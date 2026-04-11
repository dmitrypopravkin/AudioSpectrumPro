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
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                titleBar
                spectrumPanel
            }
            Divider().background(Color.white.opacity(0.15))
            RecommendationsView(recommendations: viewModel.recommendations)
                .frame(width: 280)
        }
    }

    private var iPhoneLayout: some View {
        VStack(spacing: 0) {
            titleBar
            spectrumPanel
            Divider().background(Color.white.opacity(0.15))
            RecommendationsView(recommendations: viewModel.recommendations)
                .frame(maxHeight: 200)
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
            startStopButton
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(white: 0.06))
    }

    private var spectrumPanel: some View {
        SpectrumView(displayData: viewModel.displayData, peaks: viewModel.peaks)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var languageButton: some View {
        Button(action: { showingLanguagePicker = true }) {
            Text(langManager.language.displayName)
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.5))
        }
        .buttonStyle(.plain)
        .padding(.trailing, 8)
        .accessibilityLabel(langManager.l10n.language)
    }

    private var startStopButton: some View {
        Button(action: toggleAnalysis) {
            Label(
                viewModel.isRunning ? langManager.l10n.stop : langManager.l10n.start,
                systemImage: viewModel.isRunning ? "stop.fill" : "mic.fill"
            )
        }
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(viewModel.isRunning ? Color.red : Color.green)
        .buttonStyle(.plain)
        .accessibilityLabel(viewModel.isRunning ? langManager.l10n.stopAnalysis : langManager.l10n.startAnalysis)
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
