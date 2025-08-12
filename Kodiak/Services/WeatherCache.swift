//
//  WeatherCache.swift
//  Kodiak
//
//  Created by Assistant on 12/08/2025.
//

import Foundation

struct WeatherSnapshot {
    let city: String
    let temperatureCelsius: Double
    let condition: String
}

final class WeatherCache {
    static let shared = WeatherCache()
    private init() {}
    
    private var cityToSnapshot: [String: WeatherSnapshot] = [:]
    private let lock = NSLock()
    
    private func normalize(_ s: String) -> String {
        let lowered = s.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return lowered.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
    }
    
    func set(city: String, temperatureCelsius: Double, condition: String) {
        let key = normalize(city)
        lock.lock(); defer { lock.unlock() }
        cityToSnapshot[key] = WeatherSnapshot(city: city, temperatureCelsius: temperatureCelsius, condition: condition)
    }
    
    /// Save the same snapshot under multiple aliases (e.g., user input and resolved locality)
    func set(aliases: [String], temperatureCelsius: Double, condition: String) {
        lock.lock(); defer { lock.unlock() }
        for alias in aliases {
            let key = normalize(alias)
            cityToSnapshot[key] = WeatherSnapshot(city: alias, temperatureCelsius: temperatureCelsius, condition: condition)
        }
    }
    
    func get(city: String) -> WeatherSnapshot? {
        let key = normalize(city)
        lock.lock(); defer { lock.unlock() }
        return cityToSnapshot[key]
    }
}


