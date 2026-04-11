
//  SpectrumViewModel.swift
//  AudioSpectrumPro

import Combine
import SwiftUI

@MainActor
final class SpectrumViewModel: ObservableObject {
    @Published var displayData: [Float] = Array(repeating: FFTProcessor.minDB, count: FFTProcessor.displayBinCount)
    @Published var peaks: [FrequencyPeak] = []
    @Published var recommendations: [EQRecommendation] = []
    @Published var isRunning = false
    @Published var errorMessage: String?

    private let audioEngine = AudioEngine()
    private let fftProcessor = FFTProcessor()
    private let peakDetector = PeakDetector()

    // Exponential moving average smoothing (alpha: 0 = no update, 1 = no smoothing)
    private let smoothingAlpha: Float = 0.3
    private var smoothedData: [Float] = Array(repeating: FFTProcessor.minDB, count: FFTProcessor.displayBinCount)

    func start() {
        guard !isRunning else { return }
        isRunning = true
        errorMessage = nil

        Task {
            do {
                try await audioEngine.start()
                for await samples in audioEngine.sampleStream {
                    let rawFFT = fftProcessor.process(samples)
                    let logScaled = fftProcessor.mapToLogScale(rawFFT)
                    smooth(logScaled)

                    let detectedPeaks = peakDetector.detect(
                        fftData: rawFFT,
                        sampleRate: fftProcessor.sampleRate,
                        fftSize: fftProcessor.fftSize
                    )

                    displayData = smoothedData
                    peaks = detectedPeaks
                    recommendations = makeRecommendations(from: detectedPeaks)
                }
            } catch {
                errorMessage = error.localizedDescription
                isRunning = false
            }
        }
    }

    func stop() {
        audioEngine.stop()
        isRunning = false
    }

    // MARK: - Private

    private func smooth(_ newData: [Float]) {
        let count = min(newData.count, smoothedData.count)
        let alpha = smoothingAlpha
        let oneMinusAlpha = 1.0 - alpha
        for i in 0..<count {
            smoothedData[i] = alpha * newData[i] + oneMinusAlpha * smoothedData[i]
        }
    }

    private func makeRecommendations(from peaks: [FrequencyPeak]) -> [EQRecommendation] {
        guard !peaks.isEmpty else {
            return [EQRecommendation(
                frequency: 0,
                cutDB: 0,
                urgency: .ok,
                bandwidthQ: 0,
                detail: "Спектр чистый — обратная связь маловероятна."
            )]
        }

        return peaks.map { peak in
            let cutDB = min(peak.prominence * 0.75, 12.0)
            let urgency: EQRecommendation.Urgency = peak.prominence >= 18 ? .critical : .warning
            let bandwidthQ: Float = peak.prominence >= 15 ? 2.0 : 1.4
            let detail = describeFrequency(peak.frequency, cutDB: cutDB)

            return EQRecommendation(
                frequency: peak.frequency,
                cutDB: cutDB,
                urgency: urgency,
                bandwidthQ: bandwidthQ,
                detail: detail
            )
        }
        .sorted { $0.urgency.sortPriority > $1.urgency.sortPriority }
    }

    private func describeFrequency(_ freq: Float, cutDB: Float) -> String {
        let cut = Int(cutDB.rounded())
        switch freq {
        case ..<100:
            return "Суббас — гул помещения. Срез -\(cut) dB уберёт гудение."
        case 100..<300:
            return "Нижняя середина — гулкость зала. Срез -\(cut) dB."
        case 300..<800:
            return "Середина — гнусавость. Срез -\(cut) dB улучшит разборчивость."
        case 800..<2000:
            return "Верхняя середина — резкость. Срез -\(cut) dB снизит напряжённость."
        case 2000..<5000:
            return "Присутствие — картонность. Срез -\(cut) dB не повредит разборчивости."
        default:
            return "Верхний диапазон — свистящие призвуки. Срез -\(cut) dB."
        }
    }
}

#if DEBUG
extension SpectrumViewModel {
    /// Pre-populated instance for SwiftUI previews — no microphone needed.
    static var preview: SpectrumViewModel {
        let vm = SpectrumViewModel()
        let count = FFTProcessor.displayBinCount

        // Simulate a spectrum: noise floor with two prominent peaks
        vm.displayData = (0..<count).map { i in
            let t = Float(i) / Float(count - 1)
            // Noise floor that rolls off at high frequencies
            let floor: Float = -55 + 10 * (1 - t)
            // Peak at ~820 Hz (bin ≈ 90) and ~2.4 kHz (bin ≈ 160)
            let peak1 = 30 * expf(-0.5 * powf((Float(i) - 90) / 6, 2))
            let peak2 = 18 * expf(-0.5 * powf((Float(i) - 160) / 5, 2))
            let noise = Float.random(in: -2...2)
            return min(floor + peak1 + peak2 + noise, FFTProcessor.maxDB)
        }

        vm.peaks = [
            FrequencyPeak(frequency: 820,  magnitude: -15, prominence: 22),
            FrequencyPeak(frequency: 2400, magnitude: -25, prominence: 13)
        ]

        vm.recommendations = [
            EQRecommendation(
                frequency: 820, cutDB: 8, urgency: .critical, bandwidthQ: 2.0,
                detail: "Нижняя середина — гулкость зала. Срез -8 dB уберёт обратную связь."
            ),
            EQRecommendation(
                frequency: 2400, cutDB: 4, urgency: .warning, bandwidthQ: 1.4,
                detail: "Присутствие — картонность. Срез -4 dB не повредит разборчивости."
            )
        ]

        return vm
    }
}
#endif

extension EQRecommendation.Urgency {
    var sortPriority: Int {
        switch self {
        case .critical: return 2
        case .warning: return 1
        case .ok: return 0
        }
    }
}
