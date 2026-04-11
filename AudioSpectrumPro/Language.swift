//  Language.swift
//  AudioSpectrumPro

import Foundation

enum Language: String, CaseIterable, Identifiable {
    case english    = "en"
    case russian    = "ru"
    case ukrainian  = "uk"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english:   return "English"
        case .russian:   return "Русский"
        case .ukrainian: return "Українська"
        }
    }
}
