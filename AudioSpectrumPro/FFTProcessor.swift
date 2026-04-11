
//  FFTProcessor.swift
//  AudioSpectrumPro

import Accelerate
import Foundation

final class FFTProcessor {
    let fftSize: Int
    let sampleRate: Float

    // Display range
    static let minFrequency: Float = 50
    static let maxFrequency: Float = 16000
    static let displayBinCount = 256

    // dB display range
    static let minDB: Float = -80
    static let maxDB: Float = 0

    private let halfSize: Int
    private let log2n: vDSP_Length
    private let fftSetup: FFTSetup
    private var hannWindow: [Float]

    init(fftSize: Int = 4096, sampleRate: Float = 44100) {
        self.fftSize = fftSize
        self.sampleRate = sampleRate
        self.halfSize = fftSize / 2
        self.log2n = vDSP_Length(log2(Double(fftSize)))
        self.fftSetup = vDSP_create_fftsetup(vDSP_Length(log2(Double(fftSize))), FFTRadix(kFFTRadix2))!
        self.hannWindow = [Float](repeating: 0, count: fftSize)
        vDSP_hann_window(&hannWindow, vDSP_Length(fftSize), Int32(vDSP_HANN_NORM))
    }

    deinit {
        vDSP_destroy_fftsetup(fftSetup)
    }

    /// Returns raw FFT magnitude bins in dB (halfSize values, linear frequency spacing).
    func process(_ samples: [Float]) -> [Float] {
        // Pad or truncate to fftSize
        var windowed = [Float](repeating: 0, count: fftSize)
        let copyCount = min(samples.count, fftSize)
        windowed.replaceSubrange(0..<copyCount, with: samples[0..<copyCount])

        // Apply Hann window to reduce spectral leakage
        vDSP_vmul(windowed, 1, hannWindow, 1, &windowed, 1, vDSP_Length(fftSize))

        // Perform forward FFT using split-complex representation
        var realPart = [Float](repeating: 0, count: halfSize)
        var imagPart = [Float](repeating: 0, count: halfSize)
        var magnitudes = [Float](repeating: 0, count: halfSize)

        realPart.withUnsafeMutableBufferPointer { realPtr in
            imagPart.withUnsafeMutableBufferPointer { imagPtr in
                var sc = DSPSplitComplex(realp: realPtr.baseAddress!, imagp: imagPtr.baseAddress!)

                // Pack interleaved real signal into split complex (even=real, odd=imaginary)
                windowed.withUnsafeBytes { rawPtr in
                    let complexPtr = rawPtr.baseAddress!.assumingMemoryBound(to: DSPComplex.self)
                    vDSP_ctoz(complexPtr, 2, &sc, 1, vDSP_Length(halfSize))
                }

                vDSP_fft_zrip(fftSetup, &sc, 1, log2n, FFTDirection(FFT_FORWARD))

                vDSP_zvmags(&sc, 1, &magnitudes, 1, vDSP_Length(halfSize))
            }
        }

        // Scale and convert power to dB
        let scale = Float(1.0) / Float(fftSize * fftSize)
        var result = [Float](repeating: FFTProcessor.minDB, count: halfSize)
        for i in 0..<halfSize {
            let power = magnitudes[i] * scale
            result[i] = max(10.0 * log10f(max(power, 1e-20)), FFTProcessor.minDB)
        }

        return result
    }

    /// Maps raw FFT bins to logarithmic frequency display bins (50 Hz – 16 kHz).
    func mapToLogScale(_ fftData: [Float]) -> [Float] {
        let count = FFTProcessor.displayBinCount
        let freqPerBin = sampleRate / Float(fftSize)
        let logMin = log10(FFTProcessor.minFrequency)
        let logMax = log10(FFTProcessor.maxFrequency)

        var output = [Float](repeating: FFTProcessor.minDB, count: count)

        for i in 0..<count {
            let t = Float(i) / Float(count - 1)
            let logFreq = logMin + t * (logMax - logMin)
            let freq = powf(10, logFreq)
            let binIndex = Int(freq / freqPerBin)
            let clampedBin = min(binIndex, fftData.count - 1)
            output[i] = fftData[clampedBin]
        }

        return output
    }

    /// Convert a display bin index to frequency in Hz.
    func frequency(forDisplayBin bin: Int) -> Float {
        let t = Float(bin) / Float(FFTProcessor.displayBinCount - 1)
        let logMin = log10(FFTProcessor.minFrequency)
        let logMax = log10(FFTProcessor.maxFrequency)
        return powf(10, logMin + t * (logMax - logMin))
    }

    /// Convert frequency in Hz to a 0...1 normalized X position (log scale).
    static func normalizedX(for frequency: Float) -> Float {
        let logMin = log10(minFrequency)
        let logMax = log10(maxFrequency)
        let logF = log10(max(frequency, minFrequency))
        return (logF - logMin) / (logMax - logMin)
    }
}
