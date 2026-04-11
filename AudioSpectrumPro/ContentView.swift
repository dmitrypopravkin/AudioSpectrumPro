//
//  ContentView.swift
//  AudioSpectrumPro
//
//  Created by Dmitry Popravkin on 11.04.2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel: SpectrumViewModel
    @EnvironmentObject private var langManager: LanguageManager
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var showingLanguagePicker = false
    @State private var displayMode: DisplayMode = .spectrum

    @MainActor
    init(viewModel: SpectrumViewModel? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel ?? SpectrumViewModel())
    }

    var body: some View {
        Group {
            if sizeClass == .regular {
                iPadLayout
            } else {
                iPhoneLayout
            }
        }
        .background(Color.black)
        .preferredColorScheme(.dark)
        .alert(langManager.l10n.errorTitle,
               isPresented: .constant(viewModel.errorMessage != nil)) {
            Button(langManager.l10n.errorOK) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .sheet(isPresented: $showingLanguagePicker) {
            LanguagePickerView()
        }
    }

    // MARK: - Layouts

    private var iPadLayout: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                VStack(spacing: 0) {
                    titleBar
                    modeTabBar
                    mainPanel
                }
                if displayMode == .spectrum {
                    Divider().background(Color.white.opacity(0.15))
                    RecommendationsView(recommendations: viewModel.recommendations)
                        .frame(width: 280)
                }
            }
            bottomBar
        }
    }

    private var iPhoneLayout: some View {
        VStack(spacing: 0) {
            titleBar
            modeTabBar
            mainPanel
            if displayMode == .spectrum {
                Divider().background(Color.white.opacity(0.15))
                RecommendationsView(recommendations: viewModel.recommendations)
                    .frame(maxHeight: 160)
            }
            bottomBar
        }
    }

    // MARK: - Subviews

    private var titleBar: some View {
        HStack {
            Text(langManager.l10n.appTitle)
                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)
            Spacer()
            languageButton
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(white: 0.06))
    }

    private var modeTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                ForEach(DisplayMode.allCases) { mode in
                    ModeTabButton(
                        mode: mode,
                        isSelected: displayMode == mode,
                        l10n: langManager.l10n
                    ) { displayMode = mode }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .background(Color(white: 0.05))
    }

    private var mainPanel: some View {
        Group {
            switch displayMode {
            case .spectrum:
                SpectrumView(displayData: viewModel.displayData, peaks: viewModel.peaks)
            case .spectrograph:
                SpectrographView(rows: viewModel.waterfallRows)
            case .tuner:
                TunerView(reading: viewModel.tunerReading)
                    .environmentObject(viewModel)
            case .oscilloscope:
                OscilloscopeView(samples: viewModel.rawSamples)
            case .loudness:
                LoudnessView(
                    rmsDB: viewModel.rmsDB,
                    truePeakDB: viewModel.truePeakDB,
                    history: viewModel.loudnessHistory
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var bottomBar: some View {
        HStack {
            Spacer()
            StartStopButton(
                isRunning: viewModel.isRunning,
                startLabel: langManager.l10n.start,
                stopLabel: langManager.l10n.stop,
                startAccessibility: langManager.l10n.startAnalysis,
                stopAccessibility: langManager.l10n.stopAnalysis,
                action: toggleAnalysis
            )
            Spacer()
        }
        .padding(.vertical, 16)
        .background(Color(white: 0.06))
    }

    private var languageButton: some View {
        Button(action: { showingLanguagePicker = true }) {
            Text(langManager.language.displayName)
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.5))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(langManager.l10n.language)
    }

    // MARK: - Actions

    private func toggleAnalysis() {
        if viewModel.isRunning {
            viewModel.stop()
        } else {
            viewModel.start()
        }
    }
}

// MARK: - Start/Stop Button

struct StartStopButton: View {
    let isRunning: Bool
    let startLabel: String
    let stopLabel: String
    let startAccessibility: String
    let stopAccessibility: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(isRunning ? Color.red.opacity(0.15) : Color.green.opacity(0.15))
                        .frame(width: 64, height: 64)
                    Circle()
                        .strokeBorder(isRunning ? Color.red : Color.green, lineWidth: 2)
                        .frame(width: 64, height: 64)
                    Image(systemName: isRunning ? "stop.fill" : "mic.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(isRunning ? Color.red : Color.green)
                }
                Text(isRunning ? stopLabel : startLabel)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(isRunning ? Color.red : Color.green)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isRunning ? stopAccessibility : startAccessibility)
        .animation(.easeInOut(duration: 0.2), value: isRunning)
    }
}

// MARK: - Mode Tab Button

struct ModeTabButton: View {
    let mode: DisplayMode
    let isSelected: Bool
    let l10n: L10n
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: mode.systemImage)
                    .font(.system(size: 14))
                Text(mode.title(l10n: l10n))
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
            }
            .foregroundStyle(isSelected ? Color.green : Color.white.opacity(0.4))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.green.opacity(0.12) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Language Picker Sheet

struct LanguagePickerView: View {
    @EnvironmentObject private var langManager: LanguageManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                ForEach(Language.allCases) { language in
                    Button(action: {
                        langManager.language = language
                        dismiss()
                    }) {
                        HStack {
                            Text(language.displayName)
                                .foregroundStyle(Color.primary)
                            Spacer()
                            if langManager.language == language {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                }
            }
            .navigationTitle(langManager.l10n.language)
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Previews

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(viewModel: .preview)
            .environmentObject(LanguageManager())
            .previewDisplayName("С данными")
        ContentView()
            .environmentObject(LanguageManager())
            .previewDisplayName("Пустой")
    }
}
