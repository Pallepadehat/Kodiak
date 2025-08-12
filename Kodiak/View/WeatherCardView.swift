//
//  WeatherCardView.swift
//  Kodiak
//
//  Created by Assistant on 12/08/2025.
//

import SwiftUI

struct WeatherCardView: View {
    @State var manager = WeatherManager()
    @State private var city: String = "Copenhagen"
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: manager.symbolName)
                    .font(.system(size: 34))
                VStack(alignment: .leading, spacing: 2) {
                    Text(manager.resolvedCityName.isEmpty ? city : manager.resolvedCityName)
                        .font(.headline)
                    Text(manager.conditionText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(manager.temperatureText)
                    .font(.title3.weight(.semibold))
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            
            HStack(spacing: 8) {
                TextField("Enter a city", text: $city)
                    .textFieldStyle(.roundedBorder)
                Button("Get Weather") {
                    Task { await manager.fetch(forCity: city) }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .task { await manager.fetch(forCity: city) }
        .padding()
    }
}

#Preview {
    WeatherCardView()
}


