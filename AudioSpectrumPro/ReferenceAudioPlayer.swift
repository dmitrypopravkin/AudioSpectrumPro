//  ReferenceAudioPlayer.swift
//  AudioSpectrumPro

import AVFoundation

/// Generates and plays a reference sine-wave tone at any frequency.
final class ReferenceAudioPlayer: ObservableObject {
    @Published private(set) var playingFrequency: Float? = nil

    private let engine    = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let sampleRate: Double = 44100

    init() {
        engine.attach(playerNode)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        engine.connect(playerNode, to: engine.mainMixerNode, format: format)
        try? engine.start()
    }

    /// Play a tone at `frequency` Hz for `duration` seconds.
    func play(frequency: Float, duration: Double = 2.5) {
        stop()

        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let data = buffer.floatChannelData?[0] else { return }

        buffer.frameLength = frameCount
        let sr = Float(sampleRate)
        let twoPiF = 2.0 * Float.pi * frequency
        let totalDur = Float(duration)

        // ADSR parameters
        let attack:  Float = 0.015
        let decay:   Float = 0.06
        let sustain: Float = 0.65
        let release: Float = 0.6
        let releaseStart = totalDur - release

        for i in 0..<Int(frameCount) {
            let t = Float(i) / sr
            let env: Float
            switch t {
            case ..<attack:
                env = t / attack
            case attack..<(attack + decay):
                env = 1.0 - (1.0 - sustain) * (t - attack) / decay
            case (attack + decay)..<releaseStart:
                env = sustain
            case releaseStart..<totalDur:
                env = sustain * (1.0 - (t - releaseStart) / release)
            default:
                env = 0
            }
            data[i] = sinf(twoPiF * t) * env * 0.45
        }

        playingFrequency = frequency
        playerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: { [weak self] in
            Task { @MainActor [weak self] in
                self?.playingFrequency = nil
            }
        })
        playerNode.play()
    }

    func stop() {
        playerNode.stop()
        playerNode.reset()
        playingFrequency = nil
    }
}
