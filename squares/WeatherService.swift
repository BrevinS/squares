// WeatherService.swift
import Foundation
import CoreLocation

struct HourlyTemperature: Identifiable {
    let id = UUID()
    let hour: Int
    let temperature: Double
    let time: Date
}

// Updated to match OpenWeatherMap's actual response structure
struct WeatherResponse: Codable {
    let hourly: [HourlyData]
    let current: CurrentData
    
    struct HourlyData: Codable {
        let dt: Int // Unix timestamp
        let temp: Double
        let feels_like: Double
        let pressure: Int
        let humidity: Int
        let clouds: Int
        let weather: [WeatherDescription]
    }
    
    struct CurrentData: Codable {
        let dt: Int
        let temp: Double
        let feels_like: Double
        let pressure: Int
        let humidity: Int
        let clouds: Int
        let weather: [WeatherDescription]
    }
    
    struct WeatherDescription: Codable {
        let id: Int
        let main: String
        let description: String
        let icon: String
    }
}

class WeatherService: ObservableObject {
    @Published var hourlyTemperatures: [HourlyTemperature] = []
    @Published var currentTemp: Double?
    @Published var isLoading = true
    @Published var error: Error?
    
    // Use your API key from OpenWeatherMap
    private let apiKey = "--------------------------------"
    private let locationManager = CLLocationManager()
    
    init() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func fetchDailyTemperatures() {
        isLoading = true
        
        guard let location = locationManager.location else {
            error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Location not available"])
            isLoading = false
            return
        }
        
        // Updated URL to use correct API endpoint and version
        let urlString = "https://api.openweathermap.org/data/2.5/onecall?lat=\(location.coordinate.latitude)&lon=\(location.coordinate.longitude)&exclude=minutely,daily,alerts&units=imperial&appid=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            isLoading = false
            return
        }
        
        print("Fetching weather data from: \(urlString)") // Debug print
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.error = error
                    self?.isLoading = false
                    print("Network error: \(error.localizedDescription)") // Debug print
                    return
                }
                
                guard let data = data else {
                    self?.error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])
                    self?.isLoading = false
                    return
                }
                
                // Debug print the raw JSON response
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Raw JSON response: \(jsonString)")
                }
                
                do {
                    let decoder = JSONDecoder()
                    let weather = try decoder.decode(WeatherResponse.self, from: data)
                    
                    let calendar = Calendar.current
                    let startOfDay = calendar.startOfDay(for: Date())
                    let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
                    
                    self?.hourlyTemperatures = weather.hourly
                        .filter { hourly in
                            let date = Date(timeIntervalSince1970: TimeInterval(hourly.dt))
                            return date >= startOfDay && date < endOfDay
                        }
                        .map { hourly in
                            let date = Date(timeIntervalSince1970: TimeInterval(hourly.dt))
                            return HourlyTemperature(
                                hour: calendar.component(.hour, from: date),
                                temperature: hourly.temp,
                                time: date
                            )
                        }
                    
                    self?.currentTemp = weather.current.temp
                    print("Successfully parsed weather data. Current temp: \(weather.current.temp)°F") // Debug print
                    self?.isLoading = false
                } catch {
                    self?.error = error
                    self?.isLoading = false
                    print("Decoding error: \(error.localizedDescription)") // Debug print
                    if let decodingError = error as? DecodingError {
                        switch decodingError {
                        case .keyNotFound(let key, let context):
                            print("Key '\(key.stringValue)' not found:", context.debugDescription)
                        case .typeMismatch(let type, let context):
                            print("Type '\(type)' mismatch:", context.debugDescription)
                        case .valueNotFound(let type, let context):
                            print("Value of type '\(type)' not found:", context.debugDescription)
                        case .dataCorrupted(let context):
                            print("Data corrupted:", context.debugDescription)
                        @unknown default:
                            print("Unknown decoding error")
                        }
                    }
                }
            }
        }.resume()
    }
}
