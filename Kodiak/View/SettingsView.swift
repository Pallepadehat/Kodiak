//
//  SettingsView.swift
//  Kodiak
//
//  Created by Assistant on 12/08/2025.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Binding var chatManager: ChatManager
    @Environment(\.dismiss) private var dismiss
    
    // Preferences
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    @AppStorage("animateTitle") private var animateTitle: Bool = true
    @AppStorage("titleTypeSpeed") private var titleTypeSpeed: Double = 0.05
    @AppStorage("systemPrompt") private var systemPrompt: String = "You are a helpful and concise assistant. Provide clear, accurate answers in a professional manner."
    
    // Tools
    @AppStorage("toolWeatherEnabled") private var toolWeatherEnabled: Bool = true
    @AppStorage("toolImageUploadEnabled") private var toolImageUploadEnabled: Bool = false
    @AppStorage("toolLiveVisionEnabled") private var toolLiveVisionEnabled: Bool = false
    @AppStorage("toolWebSearchEnabled") private var toolWebSearchEnabled: Bool = false
    
    @State private var showDeleteCurrentConfirm = false
    @State private var showDeleteAllConfirm = false
    
    private let defaultSystemPrompt = "You are a helpful and concise assistant. Provide clear, accurate answers in a professional manner."
    
    var body: some View {
        NavigationStack {
            Form {
                header
                
                Section("General") {
                    Toggle(isOn: $hapticsEnabled) {
                        Label("Haptics", systemImage: "iphone.radiowaves.left.and.right")
                    }
                }
                
                Section("Conversation") {
                    Toggle(isOn: $animateTitle) {
                        Label("Animate Title Typing", systemImage: "text.cursor")
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("Title Type Speed", systemImage: "speedometer")
                            Spacer()
                            Text(String(format: "%.2fs", max(0.02, min(0.12, titleTypeSpeed))))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        Slider(value: $titleTypeSpeed, in: 0.02...0.12, step: 0.01) {
                            Text("Type Speed")
                        }
                        .disabled(!animateTitle)
                    }
                }
                
                Section("Model") {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("System Prompt", systemImage: "brain.head.profile")
                        TextEditor(text: $systemPrompt)
                            .textInputAutocapitalization(.sentences)
                            .frame(minHeight: 120)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.2))
                            )
                        HStack {
                            Spacer()
                            Button("Reset to Default") {
                                systemPrompt = defaultSystemPrompt
                            }
                            .buttonStyle(.bordered)
                            Spacer()
                        }
                    }
                }
                
                Section("Tools") {
                    Toggle(isOn: $toolWeatherEnabled) {
                        Label("Weather", systemImage: "cloud.sun")
                    }
                    .onChange(of: toolWeatherEnabled) { _ in }
                    
                    Toggle(isOn: $toolImageUploadEnabled) {
                        Label("Image Upload (coming soon)", systemImage: "photo")
                    }
                    .disabled(true)
                    
                    Toggle(isOn: $toolLiveVisionEnabled) {
                        Label("Live Vision (coming soon)", systemImage: "camera.viewfinder")
                    }
                    .disabled(true)
                    
                    Toggle(isOn: $toolWebSearchEnabled) {
                        Label("Web Search (coming soon)", systemImage: "safari")
                    }
                    .disabled(true)
                }
                
                Section("Data") {
                    Button(role: .destructive) {
                        showDeleteCurrentConfirm = true
                    } label: {
                        Label("Delete Current Chat", systemImage: "trash")
                    }
                    .disabled(chatManager.currentChat == nil)
                    
                    Button(role: .destructive) {
                        showDeleteAllConfirm = true
                    } label: {
                        Label("Delete All Chats", systemImage: "trash.slash")
                    }
                }
                
                Section("About") {
                    LabeledContent("Version") {
                        Text(appVersionString)
                    }
                    LabeledContent("Build") {
                        Text(appBuildString)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog(
                "Delete Current Chat?",
                isPresented: $showDeleteCurrentConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    chatManager.deleteCurrentChat()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete the current chat and its messages.")
            }
            .confirmationDialog(
                "Delete All Chats?",
                isPresented: $showDeleteAllConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete All", role: .destructive) {
                    chatManager.deleteAllChats()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all chats and cannot be undone.")
            }
        }
    }
    
    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 36))
                .symbolRenderingMode(.palette)
                .foregroundStyle(.orange, .orange.opacity(0.5))
                .padding(.bottom, 2)
            Text("Kodiak")
                .font(.title2.weight(.semibold))
            Text("Personal AI Chat")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
    }
    
    private var appVersionString: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }
    
    private var appBuildString: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }
}

#Preview {
    SettingsView(chatManager: .constant(ChatManager()))
}


