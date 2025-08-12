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
    @AppStorage("toolImageUploadEnabled") private var toolImageUploadEnabled: Bool = false
    @AppStorage("toolLiveVisionEnabled") private var toolLiveVisionEnabled: Bool = false
    @AppStorage("toolWebSearchEnabled") private var toolWebSearchEnabled: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "puzzlepiece.extension")
                Text("Tools")
                    .font(.headline)
                Spacer()
            }
            .padding(.bottom, 4)
            
            Toggle(isOn: $toolWeatherEnabled) {
                Label("Weather", systemImage: "cloud.sun")
            }
            .onChange(of: toolWeatherEnabled) { _ in onPreferencesChanged() }
            
            if toolWeatherEnabled {
                WeatherCardView()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            Group {
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
            .tint(.orange)
            
            Spacer(minLength: 0)
        }
        .padding(20)
    }
}


