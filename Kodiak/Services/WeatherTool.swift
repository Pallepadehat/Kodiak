//
//  WeatherTool.swift
//  Kodiak
//
//  Created by Assistant on 12/08/2025.
//

import Foundation
import FoundationModels
import CoreLocation

struct WeatherTool: Tool {
    let name = "getWeather"
    let description = "Retrieve the latest weather information for a city via Open-Meteo"

    @Generable
    struct Arguments {
        @Guide(description: "The city to get weather information for")
        var city: String
    }

    func call(arguments: Arguments) async throws -> String {
        let city = arguments.city.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !city.isEmpty else { return "Please provide a city name." }

        // Geocode using Open-Meteo
        guard let geocodeURL = URL(string: "https://geocoding-api.open-meteo.com/v1/search?name=\(urlEncode(city))&count=1&language=en&format=json") else {
            return "Unable to build geocoding request."
        }
        let geocodeData = try await fetchData(from: geocodeURL)
        let geocode = try JSONDecoder().decode(OpenMeteoGeocode.self, from: geocodeData)
        guard let loc = geocode.results?.first else {
            return "I couldn't find the location for \(city)."
        }

        // Weather using Open-Meteo
        var comps = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        comps.queryItems = [
            .init(name: "latitude", value: String(loc.latitude)),
            .init(name: "longitude", value: String(loc.longitude)),
            .init(name: "current", value: "temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m"),
            .init(name: "timezone", value: "auto")
        ]
        guard let weatherURL = comps.url else { return "Unable to build weather request." }
        let weatherData = try await fetchData(from: weatherURL)
        let forecast = try JSONDecoder().decode(OpenMeteoForecast.self, from: weatherData)
        guard let current = forecast.current else { return "Weather data unavailable right now." }

        let tempC = Int(current.temperature_2m.rounded())
        let condition = weatherCodeDescription(current.weather_code)
        let name = [loc.name, loc.country_code].compactMap { $0 }.joined(separator: ", ")
        return "Current weather in \(name): \(tempC)°C • \(condition)"
    }

    // MARK: - Helpers
    private func urlEncode(_ s: String) -> String { s.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? s }

    private func fetchData(from url: URL) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return data
    }

    private func weatherCodeDescription(_ code: Int) -> String {
        switch code {
        case 0: return "Clear"
        case 1, 2: return "Mostly clear"
        case 3: return "Overcast"
        case 45, 48: return "Fog"
        case 51, 53, 55: return "Drizzle"
        case 56, 57: return "Freezing drizzle"
        case 61, 63, 65: return "Rain"
        case 66, 67: return "Freezing rain"
        case 71, 73, 75: return "Snow"
        case 77: return "Snow grains"
        case 80, 81, 82: return "Rain showers"
        case 85, 86: return "Snow showers"
        case 95: return "Thunderstorm"
        case 96, 97: return "Thunderstorm with hail"
        default: return "Unspecified"
        }
    }
}

// MARK: - Open-Meteo DTOs
private struct OpenMeteoGeocode: Decodable {
    struct Result: Decodable { let name: String; let latitude: Double; let longitude: Double; let country_code: String? }
    let results: [Result]?
}

private struct OpenMeteoForecast: Decodable {
    struct Current: Decodable { let temperature_2m: Double; let relative_humidity_2m: Double; let weather_code: Int; let wind_speed_10m: Double }
    let current: Current?
}


