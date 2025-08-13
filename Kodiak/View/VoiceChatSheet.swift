//
//  VoiceChatSheet.swift
//  Kodiak
//
//  Created by Assistant on 13/08/2025.
//

import SwiftUI

struct VoiceChatSheet: View {
    @Environment(\.dismiss) private var dismiss
    let model: LMModel
    let chatManager: ChatManager

    @AppStorage("speakRepliesEnabled") private var speakRepliesEnabled: Bool = false
    @AppStorage("handsFreeEnabled") private var handsFreeEnabled: Bool = false

    @State private var savedSpeakReplies: Bool = false
    @State private var savedHandsFree: Bool = false

    @State private var isSessionActive: Bool = false
    @State private var isPaused: Bool = false

    var body: some View {
        VStack(spacing: 24) {
            header
            Spacer(minLength: 8)
            statusVisualization
            transcriptView
            Spacer(minLength: 8)
            controls
        }
        .padding()
        .presentationDetents([.medium, .large])
        .onAppear { startSession() }
        .onDisappear { endSession() }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "waveform")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(.orange)
            Text("Voice Chat")
                .font(.title3.weight(.semibold))
            Text("Talk hands‑free. Messages are saved in this chat.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var statusVisualization: some View {
        VStack(spacing: 16) {
            if model.voice.isListening {
                EqualizerBars()
                    .frame(height: 80)
                    .transition(.opacity)
                Text("Listening…")
                    .font(.headline)
            } else if model.isAwaitingResponse {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(1.4)
                    .transition(.opacity)
                Text("Thinking…")
                    .font(.headline)
            } else if model.voice.isSpeaking {
                SpeakingPulse()
                    .frame(width: 120, height: 120)
                    .transition(.opacity)
                Text("Speaking…")
                    .font(.headline)
            } else {
                EqualizerBars()
                    .frame(height: 40)
                    .opacity(0.5)
                Text("Ready")
                    .font(.headline)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var transcriptView: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !model.liveTranscript.isEmpty {
                Text(model.liveTranscript)
                    .font(.title3)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.ultraThinMaterial, in: .rect(cornerRadius: 16))
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button(role: .destructive) {
                dismiss()
            } label: {
                Label("Done", systemImage: "xmark.circle.fill")
                    .font(.title3)
            }
            .buttonStyle(.borderedProminent)
            .tint(.gray.opacity(0.3))

            Spacer()

            Button {
                if isPaused {
                    model.startVoiceCapture(autoSend: true)
                    isPaused = false
                } else {
                    model.stopVoiceCapture()
                    isPaused = true
                }
            } label: {
                Label(isPaused ? "Resume" : "Pause", systemImage: isPaused ? "play.fill" : "pause.fill")
                    .font(.title3)
            }
            .buttonStyle(.bordered)
            .tint(.orange)
        }
    }

    private func startSession() {
        savedSpeakReplies = speakRepliesEnabled
        savedHandsFree = handsFreeEnabled
        speakRepliesEnabled = true
        handsFreeEnabled = true
        isSessionActive = true
        model.startVoiceCapture(autoSend: true)
        isPaused = false
    }

    private func endSession() {
        if isSessionActive {
            model.stopVoiceCapture()
            model.stopSpeaking()
        }
        speakRepliesEnabled = savedSpeakReplies
        handsFreeEnabled = savedHandsFree
        isSessionActive = false
        isPaused = false
    }
}

private struct EqualizerBars: View {
    @State private var phases: [CGFloat] = (0..<5).map { _ in .random(in: 0...1) }
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(0..<5, id: \.self) { idx in
                RoundedRectangle(cornerRadius: 4)
                    .fill(LinearGradient(colors: [.orange, .yellow], startPoint: .top, endPoint: .bottom))
                    .frame(width: 10, height: 20 + sin(phases[idx] * .pi * 2) * 20 + 30)
                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: phases[idx])
            }
        }
        .onAppear {
            for i in phases.indices {
                phases[i] = .random(in: 0...1)
            }
        }
    }
}

private struct SpeakingPulse: View {
    @State private var scale: CGFloat = 0.9
    @State private var opacity: CGFloat = 0.6
    var body: some View {
        ZStack {
            Circle()
                .stroke(.orange.opacity(0.4), lineWidth: 8)
                .scaleEffect(scale)
                .opacity(opacity)
                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: scale)
                .onAppear {
                    scale = 1.2
                    opacity = 0.2
                }
            Image(systemName: "speaker.wave.2.fill")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(.orange)
        }
    }
}


