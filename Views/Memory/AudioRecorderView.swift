//
//  AudioRecorderView.swift
//  simpleApp
//
//  Created by Sinchan Roychowdhury on 11/5/25.
//

import SwiftUI
import AVFoundation
import Combine

struct AudioRecorderView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var recordedAudioURL: URL?

    @StateObject private var audioRecorder = AudioRecorder()

    @State private var recordingTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var showError = false
    @State private var errorMessage = ""

    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    let notificationFeedback = UINotificationFeedbackGenerator()

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()

                VStack(spacing: 40) {
                    Spacer()

                    // Recording status
                    VStack(spacing: 16) {
                        if audioRecorder.isRecording {
                            // Animated pulse
                            ZStack {
                                Circle()
                                    .fill(AppColors.accent.opacity(0.3))
                                    .frame(width: 120, height: 120)
                                    .scaleEffect(audioRecorder.isRecording ? 1.2 : 1.0)
                                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: audioRecorder.isRecording)

                                Circle()
                                    .fill(AppColors.accent)
                                    .frame(width: 80, height: 80)

                                Image(systemName: "waveform")
                                    .font(.system(size: 32, weight: .semibold))
                                    .foregroundColor(.white)
                            }

                            Text("Recording...")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(AppColors.textPrimary)

                            Text(timeString(from: recordingTime))
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(AppColors.primary)
                                .monospacedDigit()

                        } else if audioRecorder.hasRecording {
                            // Playback controls
                            ZStack {
                                Circle()
                                    .fill(AppColors.personalColor.opacity(0.1))
                                    .frame(width: 120, height: 120)

                                Circle()
                                    .fill(AppColors.personalColor)
                                    .frame(width: 80, height: 80)

                                Image(systemName: audioRecorder.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 32, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .onTapGesture {
                                if audioRecorder.isPlaying {
                                    audioRecorder.pausePlayback()
                                } else {
                                    audioRecorder.playRecording()
                                }
                                impactFeedback.impactOccurred()
                            }

                            Text("Tap to \(audioRecorder.isPlaying ? "pause" : "play")")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(AppColors.textSecondary)

                            Text(timeString(from: audioRecorder.playbackTime))
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(AppColors.textPrimary)
                                .monospacedDigit()

                        } else {
                            // Ready to record
                            ZStack {
                                Circle()
                                    .fill(AppColors.accent.opacity(0.1))
                                    .frame(width: 120, height: 120)

                                Circle()
                                    .fill(AppColors.accent)
                                    .frame(width: 80, height: 80)

                                Image(systemName: "mic.fill")
                                    .font(.system(size: 32, weight: .semibold))
                                    .foregroundColor(.white)
                            }

                            Text("Ready to Record")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(AppColors.textPrimary)

                            Text("Tap the button below to start")
                                .font(.system(size: 16))
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }

                    Spacer()

                    // Controls
                    VStack(spacing: 16) {
                        if audioRecorder.isRecording {
                            // Stop recording button
                            Button(action: stopRecording) {
                                HStack {
                                    Image(systemName: "stop.fill")
                                    Text("Stop Recording")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppColors.accent)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }

                        } else if audioRecorder.hasRecording {
                            // Save and re-record buttons
                            HStack(spacing: 12) {
                                Button(action: reRecord) {
                                    HStack {
                                        Image(systemName: "arrow.counterclockwise")
                                        Text("Re-record")
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.white)
                                    .foregroundColor(AppColors.primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(AppColors.primary, lineWidth: 2)
                                    )
                                }

                                Button(action: saveRecording) {
                                    HStack {
                                        Image(systemName: "checkmark")
                                        Text("Use This")
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(AppColors.primary)
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }

                        } else {
                            // Start recording button
                            Button(action: startRecording) {
                                HStack {
                                    Image(systemName: "mic.fill")
                                    Text("Start Recording")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppColors.accent)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .padding(.horizontal, Constants.Layout.paddingLarge)
                    .padding(.bottom, Constants.Layout.paddingLarge)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        audioRecorder.cleanup()
                        dismiss()
                    }
                    .foregroundColor(AppColors.primary)
                }
            }
            .onAppear {
                audioRecorder.requestPermission { granted in
                    if !granted {
                        errorMessage = "Microphone access is required to record audio"
                        showError = true
                    }
                }
            }
            .onDisappear {
                timer?.invalidate()
                audioRecorder.stopPlayback()
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func startRecording() {
        recordingTime = 0
        timer?.invalidate()

        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            recordingTime += 0.1
        }

        audioRecorder.startRecording { success, error in
            if !success {
                errorMessage = error ?? "Failed to start recording"
                showError = true
                timer?.invalidate()
            }
        }

        impactFeedback.impactOccurred()
    }

    private func stopRecording() {
        timer?.invalidate()
        audioRecorder.stopRecording()
        notificationFeedback.notificationOccurred(.success)
    }

    private func reRecord() {
        audioRecorder.deleteRecording()
        recordingTime = 0
        impactFeedback.impactOccurred()
    }

    private func saveRecording() {
        if let url = audioRecorder.recordingURL {
            recordedAudioURL = url
            notificationFeedback.notificationOccurred(.success)
            dismiss()
        }
    }

    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Audio Recorder
@MainActor
class AudioRecorder: NSObject, ObservableObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    @Published var isRecording = false
    @Published var hasRecording = false
    @Published var isPlaying = false
    @Published var playbackTime: TimeInterval = 0

    var recordingURL: URL?
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var playbackTimer: Timer?

    // Request microphone permission
    func requestPermission(completion: @escaping (Bool) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    // Start recording
    func startRecording(completion: @escaping (Bool, String?) -> Void) {
        let audioSession = AVAudioSession.sharedInstance()

        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)

            let tempDir = FileManager.default.temporaryDirectory
            let fileName = "recording_\(UUID().uuidString).m4a"
            recordingURL = tempDir.appendingPathComponent(fileName)

            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            guard let url = recordingURL else {
                completion(false, "Failed to create recording URL")
                return
            }

            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()

            isRecording = true
            completion(true, nil)

        } catch {
            completion(false, error.localizedDescription)
        }
    }

    // Stop recording
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        hasRecording = true

        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Error deactivating audio session: \(error)")
        }
    }

    // Play recording
    func playRecording() {
        guard let url = recordingURL else { return }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.play()

            isPlaying = true
            startPlaybackTimer()

        } catch {
            print("Error playing recording: \(error)")
        }
    }

    // Pause playback
    func pausePlayback() {
        audioPlayer?.pause()
        isPlaying = false
        playbackTimer?.invalidate()
    }

    // Stop playback
    func stopPlayback() {
        audioPlayer?.stop()
        isPlaying = false
        playbackTime = 0
        playbackTimer?.invalidate()
    }

    // Delete recording
    func deleteRecording() {
        stopPlayback()

        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
        }

        recordingURL = nil
        hasRecording = false
        audioRecorder = nil
        audioPlayer = nil
    }

    // Cleanup
    func cleanup() {
        stopPlayback()
        if isRecording {
            audioRecorder?.stop()
        }
    }

    // MARK: - Playback Timer
    private func startPlaybackTimer() {
        playbackTimer?.invalidate()
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.audioPlayer else { return }
            Task { @MainActor in
                self.playbackTime = player.currentTime
            }
        }
    }

    // MARK: - AVAudioPlayerDelegate
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isPlaying = false
            self.playbackTime = 0
            self.playbackTimer?.invalidate()
        }
    }
}

#Preview {
    AudioRecorderView(recordedAudioURL: .constant(nil))
}
