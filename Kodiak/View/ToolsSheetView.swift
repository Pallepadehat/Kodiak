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
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                weatherRow
                suggestions
                footer
            }
            .padding(20)
        }
        .scrollIndicators(.never)
        .background(.clear)
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
    
    private var weatherRow: some View {
        Toggle(isOn: $toolWeatherEnabled) {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(Color.orange.opacity(0.15))
                        )
                    Image(systemName: "cloud.sun.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.orange, .yellow)
                        .font(.system(size: 20, weight: .semibold))
                }
                .frame(width: 44, height: 44)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Weather")
                        .font(.headline)
                    Text("Answer weather questions via WeatherKit from Apple")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.orange.opacity(0.12))
            )
        }
        .tint(.orange)
        .onChange(of: toolWeatherEnabled) { _ in onPreferencesChanged() }
    }
    
    private var suggestions: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Try prompts")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(examplePrompts, id: \.self) { prompt in
                        Text(prompt)
                            .font(.callout)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                }
            }
        }
    }
    
    private var footer: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle")
                .foregroundStyle(.secondary)
            Text("Tools run on demand when the model decides they help answer your question. Weather uses the Open‑Meteo API.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 4)
    }
    
    private var examplePrompts: [String] {
        [
            "Weather in Copenhagen",
            "Is it raining in Odense?",
            "Wind speed in Aarhus",
            "Humidity in Aalborg"
        ]
    }
}


