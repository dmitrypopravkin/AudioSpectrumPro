//  EQRecommendation.swift
//  AudioSpectrumPro

import Foundation

enum FrequencyBand {
    case subBass    // < 100 Hz
    case lowMid     // 100–300 Hz
    case mid        // 300–800 Hz
    case upperMid   // 800–2000 Hz
    case presence   // 2000–5000 Hz
    case high       // > 5000 Hz

    static func from(_ frequency: Float) -> FrequencyBand {
        switch frequency {
        case ..<100:        return .subBass
        case 100..<300:     return .lowMid
        case 300..<800:     return .mid
        case 800..<2000:    return .upperMid
        case 2000..<5000:   return .presence
        default:            return .high
        }
    }

    func description(in l10n: L10n, cut: Int) -> String {
        switch self {
        case .subBass:   return l10n.subBass(cut)
        case .lowMid:    return l10n.lowMid(cut)
        case .mid:       return l10n.mid(cut)
        case .upperMid:  return l10n.upperMid(cut)
        case .presence:  return l10n.presence(cut)
        case .high:      return l10n.high(cut)
        }
    }
}

struct EQRecommendation: Identifiable {
    let id = UUID()
    let frequency: Float    // Hz
    let cutDB: Float        // recommended cut (positive = cut)
    let urgency: Urgency
    let bandwidthQ: Float   // Q factor for the EQ band
    let band: FrequencyBand

    enum Urgency {
        case critical   // growing peak, risk of feedback
        case warning    // stable prominent peak
        case ok         // spectrum is clean
    }

    var frequencyLabel: String {
        if frequency >= 1000 {
            let kHz = Double(frequency / 1000)
            return kHz.formatted(.number.precision(.fractionLength(1))) + " kHz"
        } else {
            return Int(frequency).formatted() + " Hz"
        }
    }

    var cutLabel: String {
        "-\(Int(cutDB.rounded())) dB"
    }
}
