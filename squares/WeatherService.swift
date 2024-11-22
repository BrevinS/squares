import Foundation
import CoreLocation

struct HourlyTemperature: Identifiable {
    let id = UUID()
    let hour: Int
    let temperature: Double
    let time: Date
}

// Updated for OpenWeatherMap API 3.0
struct WeatherResponse: Codable {
    let hourly: [HourlyData]
    let current: CurrentData
    
    struct HourlyData: Codable {
        let time: Int // Unix timestamp
        let temperature: Temperature
        let humidity: Int
        let weather: [WeatherDescription]
        
        enum CodingKeys: String, CodingKey {
            case time = "dt"
            case temperature = "temp"
            case humidity
            case weather
        }
    }
    
    struct CurrentData: Codable {
        let time: Int
        let temperature: Temperature
        let humidity: Int
        let weather: [WeatherDescription]
        
        enum CodingKeys: String, CodingKey {
            case time = "dt"
            case temperature = "temp"
            case humidity
            case weather
        }
    }
    
    struct Temperature: Codable {
        let value: Double
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            value = try container.decode(Double.self)
        }
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
    
    private let apiKey = "------------------------------"
    private let locationManager = CLLocationManager()
    
    init() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func fetchDailyTemperatures() async {
        isLoading = true
        
        guard let location = locationManager.location else {
            error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Location not available"])
            isLoading = false
            return
        }
        
        let urlString = "https://api.openweathermap.org/data/3.0/onecall?lat=\(location.coordinate.latitude)&lon=\(location.coordinate.longitude)&exclude=minutely,daily,alerts&units=imperial&appid=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            isLoading = false
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            let decoder = JSONDecoder()
            let weather = try decoder.decode(WeatherResponse.self, from: data)
            
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: Date())
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            
            await MainActor.run {
                self.hourlyTemperatures = weather.hourly
                    .filter { hourly in
                        let date = Date(timeIntervalSince1970: TimeInterval(hourly.time))
                        return date >= startOfDay && date < endOfDay
                    }
                    .map { hourly in
                        let date = Date(timeIntervalSince1970: TimeInterval(hourly.time))
                        return HourlyTemperature(
                            hour: calendar.component(.hour, from: date),
                            temperature: hourly.temperature.value,
                            time: date
                        )
                    }
                
                self.currentTemp = weather.current.temperature.value
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
            print("Error fetching weather: \(error.localizedDescription)")
        }
    }
}
