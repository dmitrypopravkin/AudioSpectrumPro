
//  FrequencyPeak.swift
//  AudioSpectrumPro

import Foundation

struct FrequencyPeak: Identifiable {
    let id = UUID()
    let frequency: Float    // Hz
    let magnitude: Float    // dB
    let prominence: Float   // dB above surroundings

    var frequencyLabel: String {
        if frequency >= 1000 {
            let kHz = Double(frequency / 1000)
            return kHz.formatted(.number.precision(.fractionLength(1))) + " kHz"
        } else {
            return Int(frequency).formatted() + " Hz"
        }
    }
}
