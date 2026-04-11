
//  EQRecommendation.swift
//  AudioSpectrumPro

import Foundation

struct EQRecommendation: Identifiable {
    let id = UUID()
    let frequency: Float    // Hz
    let cutDB: Float        // recommended cut in dB (positive = cut)
    let urgency: Urgency
    let bandwidthQ: Float   // Q factor for the EQ band
    let detail: String      // human-readable explanation

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
