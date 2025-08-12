//
//  WeatherManager.swift
//  Kodiak
//
//  Created by Assistant on 12/08/2025.
//

import Foundation
import CoreLocation
import WeatherKit

@Observable
final class WeatherManager {
    private let weatherService = WeatherService()
    var weather: Weather?
    var isLoading: Bool = false
    var errorMessage: String?
    var resolvedCityName: String = ""
    
    func fetch(forCity city: String) async {
        await MainActor.run { self.isLoading = true; self.errorMessage = nil }
        do {
            let geocoder = CLGeocoder()
            let placemarks = try await geocoder.geocodeAddressString(city)
            guard let placemark = placemarks.first, let location = placemark.location else {
                await MainActor.run { self.errorMessage = "Couldn't find that location."; self.isLoading = false }
                return
            }
            self.resolvedCityName = placemark.locality ?? city
            try await fetch(for: location.coordinate)
        } catch {
            await MainActor.run {
                self.errorMessage = "Weather unavailable (setup required)."
                self.isLoading = false
            }
        }
    }
    
    func fetch(for coordinate: CLLocationCoordinate2D) async throws {
        do {
            let weather = try await weatherService.weather(for: .init(latitude: coordinate.latitude, longitude: coordinate.longitude))
            await MainActor.run {
                self.weather = weather
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Weather unavailable (setup required)."
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Derived display properties
    var symbolName: String {
        weather?.currentWeather.symbolName ?? "questionmark"
    }
    
    var temperatureText: String {
        guard let temp = weather?.currentWeather.temperature else { return "--" }
        let celsius = temp.converted(to: .celsius).value
        return "\(Int(celsius))°C"
    }
    
    var humidityText: String {
        guard let humidity = weather?.currentWeather.humidity else { return "--" }
        return "\(Int(humidity * 100))%"
    }
    
    var conditionText: String {
        weather?.currentWeather.condition.description.capitalized ?? "—"
    }
}


