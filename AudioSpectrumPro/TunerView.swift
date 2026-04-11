//  TunerView.swift
//  AudioSpectrumPro

import SwiftUI

struct TunerView: View {
    let reading: TunerReading?
    @EnvironmentObject private var langManager: LanguageManager
    @EnvironmentObject private var viewModel: SpectrumViewModel

    // MARK: - Persisted state

    @AppStorage("tuner_instrument") private var instrumentRaw: String = TunerInstrument.chromatic.rawValue
    @AppStorage("tuner_tuning_index") private var tuningIndex: Int = 0
    @AppStorage("tuner_reference_a4") private var referenceA4Storage: Double = 440.0
    @AppStorage("tuner_capo") private var capo: Int = 0
    @AppStorage("tuner_noise_gate") private var noiseGateDB: Double = -50.0

    // MARK: - Ephemeral state

    @State private var showingSettings = false
    @State private var strobeOn: Bool = false

    // MARK: - Piano keyboard data

    private let allNotes = TunerReading.noteNames
    private let whiteIndices = [0, 2, 4, 5, 7, 9, 11]
    private let blackIndices = [1, 3, 6, 8, 10]

    // MARK: - Derived helpers

    private var instrument: TunerInstrument {
        TunerInstrument(rawValue: instrumentRaw) ?? .chromatic
    }

    private var referenceA4: Float {
        Float(referenceA4Storage)
    }

    private var currentTuning: InstrumentTuning? {
        let tunings = instrument.tunings
        guard !tunings.isEmpty else { return nil }
        let idx = min(tuningIndex, tunings.count - 1)
        return tunings[idx]
    }

    private var nearestStringResult: (string: InstrumentString, centsOff: Int)? {
        guard instrument != .chromatic,
              let tuning = currentTuning,
              let freq = reading?.frequency else { return nil }
        return nearestString(to: freq, in: tuning, referenceA4: referenceA4, capo: capo)
    }

    private func nearestString(
        to frequency: Float,
        in tuning: InstrumentTuning,
        referenceA4: Float,
        capo: Int
    ) -> (string: InstrumentString, centsOff: Int)? {
        guard !tuning.strings.isEmpty else { return nil }
        var bestString = tuning.strings[0]
        var bestAbsDist = Int.max
        var bestCents = 0
        for string in tuning.strings {
            let shiftedMidi = string.midiNote + capo
            let targetFreq = referenceA4 * pow(2.0, Float(shiftedMidi - 69) / 12.0)
            let semitones = 12.0 * log2(frequency / targetFreq)
            let cents = Int((semitones * 100.0).rounded())
            let dist = abs(cents)
            if dist < bestAbsDist {
                bestAbsDist = dist
                bestCents = cents
                bestString = string
            }
        }
        return (string: bestString, centsOff: bestCents)
    }

    private var displayCents: Int {
        if instrument != .chromatic, let ns = nearestStringResult {
            return ns.centsOff
        }
        return reading?.cents ?? 0
    }

    private var supportsCapo: Bool {
        instrument == .guitar || instrument == .bass
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                instrumentSelector
                    .padding(.top, 12)

                if instrument != .chromatic && instrument.tunings.count > 1 {
                    tuningSelector
                        .padding(.top, 8)
                }

                if instrument != .chromatic {
                    stringIndicators
                        .padding(.top, 10)
                }

                readoutArea
                    .padding(.top, 10)

                Spacer(minLength: 6)
                tuningMeter
                Spacer(minLength: 10)

                pianoKeyboard
                    .frame(height: 90)
                    .padding(.horizontal, 16)

                quickSettingsBar
                    .padding(.top, 8)
                    .padding(.bottom, 12)
            }
            .background(Color.black)

            // Gear button overlay
            Button(action: { showingSettings = true }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.white.opacity(0.5))
                    .padding(14)
            }
            .accessibilityLabel(langManager.l10n.tunerSettings)
        }
        .sheet(isPresented: $showingSettings) {
            settingsSheet
        }
        .onChange(of: referenceA4Storage) { _ in syncViewModel() }
        .onChange(of: noiseGateDB) { _ in syncViewModel() }
        .onAppear { syncViewModel() }
    }

    // MARK: - Sync ViewModel

    private func syncViewModel() {
        viewModel.referenceA4 = Float(referenceA4Storage)
        viewModel.noiseGateDB = Float(noiseGateDB)
    }

    // MARK: - Instrument Selector

    private var instrumentSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TunerInstrument.allCases) { inst in
                    Button(action: {
                        instrumentRaw = inst.rawValue
                        tuningIndex = 0
                    }) {
                        VStack(spacing: 3) {
                            Image(systemName: inst.systemImage)
                                .font(.system(size: 14))
                            Text(inst.displayName)
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(instrument == inst ? Color.black : Color.white.opacity(0.7))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(instrument == inst ? Color.white : Color.white.opacity(0.1))
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Tuning Selector

    private var tuningSelector: some View {
        let tunings = instrument.tunings
        return HStack(spacing: 6) {
            ForEach(Array(tunings.enumerated()), id: \.offset) { idx, tuning in
                Button(action: { tuningIndex = idx }) {
                    Text(tuning.name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(tuningIndex == idx ? Color.black : Color.white.opacity(0.7))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(tuningIndex == idx ? Color.white : Color.white.opacity(0.12))
                        )
                }
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - String Indicators

    private var stringIndicators: some View {
        let strings = currentTuning?.strings ?? []
        let nearest = nearestStringResult?.string
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(strings) { str in
                    let isNearest = nearest?.id == str.id
                    let color = isNearest ? pillColor(centsOff: nearestStringResult?.centsOff ?? 0) : Color.white.opacity(0.15)
                    Text(str.name)
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundStyle(isNearest ? Color.black : Color.white.opacity(0.6))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(color)
                        )
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func pillColor(centsOff: Int) -> Color {
        let a = abs(centsOff)
        if a <= 10 { return .green }
        if a <= 25 { return .yellow }
        return .red
    }

    // MARK: - Readout

    private var readoutArea: some View {
        VStack(spacing: 4) {
            if let r = reading {
                let cents = displayCents
                Text("\(r.note)\(r.octave)")
                    .font(.system(size: 52, weight: .bold, design: .monospaced))
                    .foregroundStyle(noteColor(cents: cents))
                Text("\(r.frequency, format: .number.precision(.fractionLength(1))) Hz")
                    .font(.system(size: 14, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.6))
                if abs(cents) <= 5 {
                    Text(langManager.l10n.tunerInTune)
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color.green)
                } else {
                    Text(centsLabel(cents))
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(noteColor(cents: cents).opacity(0.9))
                }
            } else {
                Text("–")
                    .font(.system(size: 52, weight: .thin, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.2))
                Text(langManager.l10n.tunerListening)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.3))
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Tuning Meter

    private var tuningMeter: some View {
        GeometryReader { geo in
            let cents = reading != nil ? displayCents : 0
            let isNearZero = reading != nil && abs(cents) <= 5

            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 6)

                // Centre marker
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 2, height: 14)
                    .offset(x: geo.size.width / 2 - 1)

                // Strobe glow when in-tune
                if isNearZero {
                    Capsule()
                        .fill(Color.green.opacity(strobeOn ? 0.35 : 0.12))
                        .frame(width: geo.size.width * 0.4, height: 10)
                        .offset(x: geo.size.width * 0.3)
                        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: strobeOn)
                        .onAppear { strobeOn = true }
                        .onDisappear { strobeOn = false }
                }

                // Needle
                if reading != nil {
                    let offset = CGFloat(cents) / 50.0 * (geo.size.width / 2)
                    Capsule()
                        .fill(noteColor(cents: cents))
                        .frame(width: geo.size.width * 0.12, height: 6)
                        .offset(x: geo.size.width / 2 + offset - geo.size.width * 0.06)
                        .animation(.spring(response: 0.15, dampingFraction: 0.7), value: cents)
                }
            }
            .frame(maxHeight: .infinity, alignment: .center)
        }
        .frame(height: 20)
        .padding(.horizontal, 32)
    }

    // MARK: - Piano Keyboard

    private var pianoKeyboard: some View {
        GeometryReader { geo in
            let whiteCount = 7
            let whiteW = geo.size.width / CGFloat(whiteCount)
            let whiteH = geo.size.height
            let blackW = whiteW * 0.6
            let blackH = whiteH * 0.62
            let activeNote = reading?.note

            ZStack(alignment: .topLeading) {
                ForEach(0..<7, id: \.self) { i in
                    let noteIndex = whiteIndices[i]
                    let noteName = allNotes[noteIndex]
                    let isActive = activeNote == noteName

                    RoundedRectangle(cornerRadius: 3)
                        .fill(isActive ? noteColor(cents: displayCents) : Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.black.opacity(0.4), lineWidth: 1))
                        .frame(width: whiteW - 2, height: whiteH)
                        .offset(x: CGFloat(i) * whiteW + 1)
                        .animation(.easeInOut(duration: 0.1), value: isActive)
                }

                ForEach(0..<5, id: \.self) { i in
                    let noteIndex = blackIndices[i]
                    let noteName = allNotes[noteIndex]
                    let isActive = activeNote == noteName
                    let positions: [CGFloat] = [
                        whiteW * 0.7,
                        whiteW * 1.7,
                        whiteW * 3.7,
                        whiteW * 4.7,
                        whiteW * 5.7
                    ]

                    RoundedRectangle(cornerRadius: 2)
                        .fill(isActive ? noteColor(cents: displayCents) : Color.black)
                        .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color.white.opacity(0.15), lineWidth: 0.5))
                        .frame(width: blackW, height: blackH)
                        .offset(x: positions[i])
                        .animation(.easeInOut(duration: 0.1), value: isActive)
                }
            }
        }
    }

    // MARK: - Quick Settings Bar

    private var quickSettingsBar: some View {
        HStack(spacing: 16) {
            // A4 reference button
            Button(action: { showingSettings = true }) {
                Text("A4: \(Int(referenceA4)) Hz")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.6))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.08))
                    )
            }

            // Capo stepper (only for guitar/bass)
            if supportsCapo {
                HStack(spacing: 6) {
                    Text("\(langManager.l10n.tunerCapo): \(capo)")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.6))

                    Stepper("", value: $capo, in: 0...7)
                        .labelsHidden()
                        .scaleEffect(0.8)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.08))
                )
            }

            Spacer()
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Settings Sheet

    private var settingsSheet: some View {
        NavigationView {
            Form {
                // Section 1: Reference pitch
                Section(header: Text(langManager.l10n.tunerReferencePitch)) {
                    // Preset buttons
                    let presets: [Int] = [432, 438, 440, 441, 442, 443, 444]
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(presets, id: \.self) { preset in
                                let isSelected = Int(referenceA4Storage) == preset
                                Button(action: { referenceA4Storage = Double(preset) }) {
                                    Text("\(preset)")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(isSelected ? Color.black : Color.primary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.2))
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(langManager.l10n.tunerCustom)
                                .font(.callout)
                            Spacer()
                            Text("\(referenceA4Storage, specifier: "%.1f") Hz")
                                .font(.system(.callout, design: .monospaced))
                                .foregroundStyle(Color.secondary)
                        }
                        Slider(value: $referenceA4Storage, in: 430...450, step: 1)
                    }
                }

                // Section 2: Capo (guitar/bass only)
                if supportsCapo {
                    Section(header: Text(langManager.l10n.tunerCapo)) {
                        Stepper("\(langManager.l10n.tunerCapo): \(capo)", value: $capo, in: 0...7)
                    }
                }

                // Section 3: Noise gate
                Section(header: Text(langManager.l10n.tunerNoiseGate)) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(langManager.l10n.tunerNoiseGate)
                                .font(.callout)
                            Spacer()
                            Text("\(noiseGateDB, specifier: "%.0f") dB")
                                .font(.system(.callout, design: .monospaced))
                                .foregroundStyle(Color.secondary)
                        }
                        Slider(value: $noiseGateDB, in: -60...(-20), step: 1)
                    }
                }
            }
            .navigationTitle(langManager.l10n.tunerSettings)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(langManager.l10n.errorOK) {
                        showingSettings = false
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func noteColor(cents: Int) -> Color {
        let a = abs(cents)
        if a <= 5  { return .green }
        if a <= 15 { return .yellow }
        return .red
    }

    private func centsLabel(_ cents: Int) -> String {
        let sign = cents > 0 ? "+" : ""
        return "\(sign)\(cents) \(langManager.l10n.tunerCents)"
    }
}
