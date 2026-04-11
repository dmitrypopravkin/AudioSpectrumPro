//  SpectrographView.swift
//  AudioSpectrumPro

import SwiftUI

struct SpectrographView: View {
    let rows: [[Float]]

    private let maxRows = 60

    var body: some View {
        Canvas { context, size in
            guard !rows.isEmpty, let binCount = rows.first?.count, binCount > 0 else { return }

            let rowCount  = rows.count
            let rowHeight = size.height / CGFloat(maxRows)
            let binWidth  = size.width  / CGFloat(binCount)

            for rowIndex in 0..<rowCount {
                let row = rows[rowIndex]
                let y   = CGFloat(rowIndex) * rowHeight

                for binIndex in stride(from: 0, to: binCount, by: 2) {
                    let db = row[binIndex]
                    let x  = CGFloat(binIndex) * binWidth
                    let rect = CGRect(x: x, y: y, width: binWidth * 2 + 0.5, height: rowHeight + 0.5)
                    context.fill(Path(rect), with: .color(heatColor(db: db)))
                }
            }

            // Frequency axis labels
            drawFrequencyAxis(context: context, size: size)
        }
        .background(Color.black)
    }

    // MARK: - Color mapping

    /// Maps dB (-80…0) to a heat colour: black → blue → green → yellow → red.
    private func heatColor(db: Float) -> Color {
        let t = Double((db - FFTProcessor.minDB) / (FFTProcessor.maxDB - FFTProcessor.minDB))
        let clamped = max(0, min(1, t))

        switch clamped {
        case 0..<0.25:
            let u = clamped / 0.25
            return Color(red: 0, green: 0, blue: u * 0.6)
        case 0.25..<0.5:
            let u = (clamped - 0.25) / 0.25
            return Color(red: 0, green: u * 0.8, blue: 0.6 - u * 0.6)
        case 0.5..<0.75:
            let u = (clamped - 0.5) / 0.25
            return Color(red: u, green: 0.8, blue: 0)
        default:
            let u = (clamped - 0.75) / 0.25
            return Color(red: 1, green: 0.8 - u * 0.8, blue: 0)
        }
    }

    // MARK: - Axis

    private func drawFrequencyAxis(context: GraphicsContext, size: CGSize) {
        let gridFreqs: [Float] = [100, 500, 1000, 5000, 10000]
        let font = Font.system(size: 9, weight: .regular, design: .monospaced)
        let color = Color.white.opacity(0.4)

        for freq in gridFreqs {
            let x = CGFloat(FFTProcessor.normalizedX(for: freq)) * size.width
            var path = Path()
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height - 14))
            context.stroke(path, with: .color(color.opacity(0.3)), lineWidth: 0.5)

            let label = freq >= 1000 ? "\(Int(freq / 1000))k" : "\(Int(freq))"
            context.draw(
                Text(label).font(font).foregroundColor(color),
                at: CGPoint(x: x, y: size.height - 6)
            )
        }
    }
}
