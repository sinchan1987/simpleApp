//
//  AudioPlayerView.swift
//  simpleApp
//
//  Created by Sinchan Roychowdhury on 11/5/25.
//

import SwiftUI
import AVFoundation
import Combine

struct AudioPlayerView: View {
    let audioURL: String

    @StateObject private var player = AudioPlayer()
    @State private var showError = false

    var body: some View {
        VStack(spacing: 16) {
            // Player controls
            HStack(spacing: 16) {
                // Play/Pause button
                Button(action: togglePlayback) {
                    ZStack {
                        Circle()
                            .fill(AppColors.accent)
                            .frame(width: 48, height: 48)

                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .disabled(player.isLoading)

                VStack(alignment: .leading, spacing: 4) {
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            Capsule()
                                .fill(Color.gray.opacity(0.2))

                            // Progress
                            Capsule()
                                .fill(AppColors.accent)
                                .frame(width: geometry.size.width * player.progress)
                        }
                    }
                    .frame(height: 4)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let progress = value.location.x / UIScreen.main.bounds.width
                                player.seek(to: progress)
                            }
                    )

                    // Time labels
                    HStack {
                        Text(timeString(from: player.currentTime))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppColors.textSecondary)
                            .monospacedDigit()

                        Spacer()

                        Text(timeString(from: player.duration))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppColors.textSecondary)
                            .monospacedDigit()
                    }
                }
            }

            // Waveform visualization (simplified)
            if player.isPlaying {
                WaveformView()
                    .frame(height: 40)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
        )
        .onAppear {
            player.loadAudio(from: audioURL)
        }
        .onDisappear {
            player.stop()
        }
        .alert("Playback Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Failed to play audio")
        }
    }

    private func togglePlayback() {
        if player.isPlaying {
            player.pause()
        } else {
            player.play()
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Audio Player
@MainActor
class AudioPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlaying = false
    @Published var isLoading = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var progress: Double = 0

    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    private var audioURL: String?

    func loadAudio(from urlString: String) {
        guard audioURL != urlString else { return }
        audioURL = urlString
        isLoading = true

        Task {
            do {
                guard let url = URL(string: urlString) else {
                    isLoading = false
                    return
                }

                // Download audio data
                let (data, _) = try await URLSession.shared.data(from: url)

                // Create audio player
                audioPlayer = try AVAudioPlayer(data: data)
                audioPlayer?.delegate = self
                audioPlayer?.prepareToPlay()

                duration = audioPlayer?.duration ?? 0
                isLoading = false

            } catch {
                print("Error loading audio: \(error)")
                isLoading = false
            }
        }
    }

    func play() {
        guard let player = audioPlayer else { return }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            player.play()
            isPlaying = true
            startTimer()

        } catch {
            print("Error playing audio: \(error)")
        }
    }

    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        timer?.invalidate()
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        isPlaying = false
        currentTime = 0
        progress = 0
        timer?.invalidate()
    }

    func seek(to percentage: Double) {
        guard let player = audioPlayer else { return }
        let newTime = duration * percentage
        player.currentTime = newTime
        currentTime = newTime
        progress = percentage
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.audioPlayer else { return }

            Task { @MainActor in
                self.currentTime = player.currentTime
                self.progress = self.duration > 0 ? player.currentTime / self.duration : 0
            }
        }
    }

    // MARK: - AVAudioPlayerDelegate
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isPlaying = false
            self.currentTime = 0
            self.progress = 0
            self.timer?.invalidate()
            self.audioPlayer?.currentTime = 0
        }
    }

    deinit {
        timer?.invalidate()
    }
}

// MARK: - Waveform View
struct WaveformView: View {
    @State private var barHeights: [CGFloat] = Array(repeating: 0.3, count: 40)
    @State private var animationTimer: Timer?

    var body: some View {
        HStack(alignment: .center, spacing: 2) {
            ForEach(0..<barHeights.count, id: \.self) { index in
                Capsule()
                    .fill(AppColors.accent.opacity(0.7))
                    .frame(width: 3, height: barHeights[index] * 40)
                    .animation(.easeInOut(duration: 0.3), value: barHeights[index])
            }
        }
        .onAppear {
            startAnimation()
        }
        .onDisappear {
            animationTimer?.invalidate()
        }
    }

    private func startAnimation() {
        animationTimer?.invalidate()
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            withAnimation {
                for index in barHeights.indices {
                    barHeights[index] = CGFloat.random(in: 0.2...1.0)
                }
            }
        }
    }
}

#Preview {
    AudioPlayerView(audioURL: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3")
        .padding()
}
