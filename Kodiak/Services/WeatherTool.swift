//
//  WeatherTool.swift
//  Kodiak
//
//  Created by Assistant on 12/08/2025.
//

import Foundation
import FoundationModels
import CoreLocation
import WeatherKit

struct WeatherTool: Tool {
    let name = "getWeather"
    let description = "Retrieve current weather for a city using Apple WeatherKit (rain status, wind speed, temperature, humidity)."

    @Generable
    struct Arguments {
        @Guide(description: "The city to get weather information for")
        var city: String
    }

    func call(arguments: Arguments) async throws -> String {
        let city = arguments.city.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !city.isEmpty else { return "Please provide a city name." }

        if #available(iOS 16.0, macOS 13.0, *) {
            do {
                let (location, displayName) = try await geocodeCity(city)
                let weather = try await WeatherService.shared.weather(for: location)
                let current = weather.currentWeather

                let tempC = Int(current.temperature.converted(to: .celsius).value.rounded())
                let humidityPct = Int((current.humidity * 100).rounded())
                let windKmh = Int(current.wind.speed.converted(to: .kilometersPerHour).value.rounded())

                // Derive rain status from condition name to avoid exhaustive enum matching
                let conditionName = String(describing: current.condition)
                let isRaining = isRainingFromConditionName(conditionName)
                let conditionText = humanizeCondition(conditionName)

                return "Current weather in \(displayName): \(tempC)°C • \(conditionText) • Wind \(windKmh) km/h • Humidity \(humidityPct)% • Raining: \(isRaining ? "Yes" : "No")"
            } catch {
                return "Unable to retrieve WeatherKit data for \(city). Please try again."
            }
        } else {
            return "WeatherKit requires iOS 16/macOS 13 or later."
        }
    }

    // MARK: - Helpers
    private func isRainingFromConditionName(_ condition: String) -> Bool {
        let lower = condition.lowercased()
        return lower.contains("rain") || lower.contains("drizzle") || lower.contains("shower") || lower.contains("thunder")
    }

    private func humanizeCondition(_ condition: String) -> String {
        // Transform enum case names like "partlyCloudy" -> "Partly Cloudy"
        let spaced = condition.replacingOccurrences(of: "([a-z])([A-Z])",
                                                    with: "$1 $2",
                                                    options: .regularExpression,
                                                    range: nil)
        return spaced.capitalized
    }

    @available(iOS 16.0, macOS 13.0, *)
    private func geocodeCity(_ city: String) async throws -> (CLLocation, String) {
        try await withCheckedThrowingContinuation { continuation in
            let geocoder = CLGeocoder()
            geocoder.geocodeAddressString(city) { placemarks, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let placemark = placemarks?.first, let location = placemark.location else {
                    continuation.resume(throwing: NSError(domain: "WeatherTool", code: 404, userInfo: [NSLocalizedDescriptionKey: "Location not found"]))
                    return
                }

                let locality = placemark.locality ?? city
                let countryCode = placemark.isoCountryCode
                let display = [locality, countryCode].compactMap { $0 }.joined(separator: ", ")
                continuation.resume(returning: (location, display.isEmpty ? city : display))
            }
        }
    }
}


