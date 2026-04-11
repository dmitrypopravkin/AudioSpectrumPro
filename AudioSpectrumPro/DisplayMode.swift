//  DisplayMode.swift
//  AudioSpectrumPro

import Foundation

enum DisplayMode: String, CaseIterable, Identifiable {
    case spectrum
    case spectrograph
    case tuner
    case oscilloscope
    case loudness

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .spectrum:     return "waveform.path.ecg"
        case .spectrograph: return "chart.bar.fill"
        case .tuner:        return "music.note"
        case .oscilloscope: return "waveform"
        case .loudness:     return "speaker.wave.3.fill"
        }
    }

    func title(l10n: L10n) -> String {
        switch self {
        case .spectrum:     return l10n.modeSpectrum
        case .spectrograph: return l10n.modeSpectrograph
        case .tuner:        return l10n.modeTuner
        case .oscilloscope: return l10n.modeOscilloscope
        case .loudness:     return l10n.modeLoudness
        }
    }
}
