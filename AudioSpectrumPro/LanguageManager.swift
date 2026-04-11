//  LanguageManager.swift
//  AudioSpectrumPro

import Combine
import SwiftUI

final class LanguageManager: ObservableObject {
    @AppStorage("app_language") var selectedLanguage: String = Language.english.rawValue {
        willSet { objectWillChange.send() }
    }

    var language: Language {
        get { Language(rawValue: selectedLanguage) ?? .english }
        set { selectedLanguage = newValue.rawValue }
    }

    var l10n: L10n { L10n.make(for: language) }
}
