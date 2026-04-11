# Audio Spectrum Pro

iOS app for real-time audio spectrum analysis. Designed for tuning live sound equipment — PA systems, monitors, and room acoustics.

## Features

- Real-time FFT spectrum analyzer (50 Hz – 16 kHz)
- Logarithmic frequency scale with dB grid
- Automatic peak detection with frequency labels
- EQ recommendations: which frequencies to cut and by how much
- Feedback risk indicator (red = critical, yellow = warning)
- Adaptive layout for iPhone and iPad

## Tech Stack

- Swift + SwiftUI (Canvas for rendering)
- AVAudioEngine — microphone capture
- Accelerate / vDSP — hardware-accelerated FFT
- No third-party dependencies

## Requirements

- iOS 16.2+
- Microphone access

## Project Structure

```
AudioSpectrumPro/
├── Audio/
│   ├── AudioEngine.swift       # Microphone capture via AVAudioEngine
│   └── FFTProcessor.swift      # FFT + logarithmic scale mapping (vDSP)
├── Detection/
│   └── PeakDetector.swift      # Prominence-based peak detection
├── Models/
│   ├── FrequencyPeak.swift
│   └── EQRecommendation.swift
├── ViewModel/
│   └── SpectrumViewModel.swift # @MainActor ObservableObject
└── Views/
    ├── ContentView.swift        # Adaptive iPhone / iPad layout
    ├── SpectrumView.swift       # Canvas: spectrum, grid, peak labels
    └── RecommendationsView.swift
```

## How It Works

1. `AudioEngine` captures PCM audio from the microphone via `AVAudioEngine`
2. `FFTProcessor` applies a Hann window and runs FFT using `vDSP_fft_zrip`
3. Frequency bins are mapped to a logarithmic scale (256 display bins, 50–16000 Hz)
4. `PeakDetector` finds prominent spectral peaks using a prominence algorithm
5. `SpectrumViewModel` generates EQ cut recommendations based on peak prominence and frequency range
6. `SpectrumView` renders everything in a SwiftUI `Canvas` at the FFT update rate (~10 fps)

## License

MIT
