//  RecommendationsView.swift
//  AudioSpectrumPro

import SwiftUI

struct RecommendationsView: View {
    let recommendations: [EQRecommendation]
    @EnvironmentObject private var langManager: LanguageManager

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider().background(Color.white.opacity(0.15))
            recommendationList
        }
        .background(Color(white: 0.08))
    }

    private var header: some View {
        Text(langManager.l10n.eqRecommendations)
            .font(.system(size: 13, weight: .semibold, design: .monospaced))
            .foregroundStyle(Color.white.opacity(0.7))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
    }

    private var recommendationList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 2) {
                ForEach(recommendations) { rec in
                    RecommendationRowView(recommendation: rec)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

struct RecommendationRowView: View {
    let recommendation: EQRecommendation
    @EnvironmentObject private var langManager: LanguageManager

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            urgencyDot
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    frequencyLabel
                    if recommendation.urgency != .ok {
                        cutLabel
                    }
                }
                detailText
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    private var urgencyDot: some View {
        Circle()
            .fill(urgencyColor)
            .frame(width: 8, height: 8)
            .padding(.top, 4)
    }

    private var frequencyLabel: some View {
        Text(recommendation.urgency == .ok ? "OK" : recommendation.frequencyLabel)
            .font(.system(size: 13, weight: .bold, design: .monospaced))
            .foregroundStyle(urgencyColor)
    }

    private var cutLabel: some View {
        Text(recommendation.cutLabel)
            .font(.system(size: 12, weight: .regular, design: .monospaced))
            .foregroundStyle(Color.white.opacity(0.9))
            .padding(.horizontal, 6)
            .padding(.vertical, 1)
            .background(urgencyColor.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private var detailText: some View {
        let l10n = langManager.l10n
        let cut = Int(recommendation.cutDB.rounded())
        let text = recommendation.urgency == .ok
            ? l10n.spectrumClean
            : recommendation.band.description(in: l10n, cut: cut)

        return Text(text)
            .font(.system(size: 11))
            .foregroundStyle(Color.white.opacity(0.5))
            .fixedSize(horizontal: false, vertical: true)
    }

    private var urgencyColor: Color {
        switch recommendation.urgency {
        case .critical: return .red
        case .warning:  return .yellow
        case .ok:       return .green
        }
    }
}

#if DEBUG
struct RecommendationsView_Previews: PreviewProvider {
    static var previews: some View {
        RecommendationsView(recommendations: [
            EQRecommendation(frequency: 820,  cutDB: 8, urgency: .critical, bandwidthQ: 2.0, band: .lowMid),
            EQRecommendation(frequency: 2400, cutDB: 4, urgency: .warning,  bandwidthQ: 1.4, band: .presence),
            EQRecommendation(frequency: 0,    cutDB: 0, urgency: .ok,       bandwidthQ: 0,   band: .mid)
        ])
        .environmentObject(LanguageManager())
        .preferredColorScheme(.dark)
    }
}
#endif
