//
//  ContentView.swift
//  AudioSpectrumPro
//
//  Created by Dmitry Popravkin on 11.04.2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel: SpectrumViewModel
    @Environment(\.horizontalSizeClass) private var sizeClass

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
        .alert("Ошибка", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Layouts

    /// Side-by-side layout for iPad / landscape
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

    /// Stacked layout for iPhone
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
            Text("Audio Spectrum Pro")
                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)
            Spacer()
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

    private var startStopButton: some View {
        Button(action: toggleAnalysis) {
            Label(
                viewModel.isRunning ? "Стоп" : "Старт",
                systemImage: viewModel.isRunning ? "stop.fill" : "mic.fill"
            )
        }
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(viewModel.isRunning ? Color.red : Color.green)
        .buttonStyle(.plain)
        .accessibilityLabel(viewModel.isRunning ? "Остановить анализ" : "Начать анализ")
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(viewModel: .preview)
            .previewDisplayName("С данными")
        ContentView()
            .previewDisplayName("Пустой")
    }
}
