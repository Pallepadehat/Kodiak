//
//  ToolsSheetView.swift
//  Kodiak
//
//  Created by Assistant on 12/08/2025.
//

import SwiftUI

struct ToolsSheetView: View {
    var onPreferencesChanged: () -> Void
    
    @AppStorage("toolWeatherEnabled") private var toolWeatherEnabled: Bool = true
    @AppStorage("toolWebSearchEnabled") private var toolWebSearchEnabled: Bool = false
    @AppStorage("toolWikipediaEnabled") private var toolWikipediaEnabled: Bool = false
    
    var body: some View {
        List {
            Section(header: header) {
                Toggle(isOn: $toolWeatherEnabled) {
                    ToolRow(
                        icon: "cloud.sun.fill",
                        iconColors: [.orange, .yellow],
                        title: "Weather",
                        subtitle: "Answer weather questions using Apple WeatherKit",
                        status: toolWeatherEnabled ? .enabled : .disabled
                    )
                }
                .tint(.orange)
                .onChange(of: toolWeatherEnabled) { _ in onPreferencesChanged() }

                Toggle(isOn: $toolWebSearchEnabled) {
                    ToolRow(
                        icon: "magnifyingglass.circle.fill",
                        iconColors: [.blue, .teal],
                        title: "Web Search",
                        subtitle: "Search the web for up-to-date answers",
                        status: .comingSoon
                    )
                }
                .tint(.blue)
                .disabled(true)

                Toggle(isOn: $toolWikipediaEnabled) {
                    ToolRow(
                        icon: "book.pages.fill",
                        iconColors: [.purple, .indigo],
                        title: "Wikipedia",
                        subtitle: "Summarize topics from Wikipedia",
                        status: .comingSoon
                    )
                }
                .tint(.purple)
                .disabled(true)
            }

            Section(footer: Text("Tools run on demand when the model decides they help answer your question. Weather uses Apple WeatherKit.").foregroundStyle(.secondary)) { EmptyView() }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #endif
    }
    
    // MARK: - Sections
    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(
                    LinearGradient(colors: [.orange.opacity(0.35), .yellow.opacity(0.25)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                Image(systemName: "puzzlepiece.extension.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.orange)
            }
            .frame(width: 34, height: 34)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Tools")
                    .font(.headline)
                Text("Enable capabilities the model can call when helpful")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
    
}

// MARK: - ToolRow
private struct ToolRow: View {
    enum Status { case enabled, disabled, comingSoon }

    let icon: String
    let iconColors: [Color]
    let title: String
    let subtitle: String
    let status: Status

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.ultraThinMaterial)
                Image(systemName: icon)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(iconColors.first ?? .primary, (iconColors.dropFirst().first ?? (iconColors.first ?? .primary)).opacity(0.8))
                    .font(.system(size: 20, weight: .semibold))
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.headline)
                    statusBadge
                }
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch status {
        case .enabled:
            Text("Enabled")
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.green.opacity(0.15), in: Capsule())
                .foregroundStyle(.green)
        case .disabled:
            Text("Disabled")
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.gray.opacity(0.15), in: Capsule())
                .foregroundStyle(.secondary)
        case .comingSoon:
            Text("Coming soon")
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.orange.opacity(0.15), in: Capsule())
                .foregroundStyle(.orange)
        }
    }
}
