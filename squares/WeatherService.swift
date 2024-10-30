// WeatherService.swift
import Foundation

struct HourlyTemperature: Identifiable {
    let id = UUID()
    let hour: Int
    let temperature: Double
    let time: Date
}

class WeatherService: ObservableObject {
    @Published var hourlyTemperatures: [HourlyTemperature] = []
    @Published var currentTemp: Double?
    @Published var isLoading = false
    @Published var error: Error?
    
    func fetchDailyTemperatures() {
        // TODO: Replace with actual API call
        // For now, generating mock data
        isLoading = true
        
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        
        var temperatures: [HourlyTemperature] = []
        
        for hour in 0..<24 {
            let time = calendar.date(byAdding: .hour, value: hour, to: startOfDay)!
            
            // Generate mock temperature data with a realistic daily pattern
            let baseTemp = 65.0 // Base temperature
            let amplitude = 15.0 // Temperature variation
            let hourInRadians = Double(hour) * .pi / 12.0
            let temperature = baseTemp + amplitude * sin(hourInRadians - .pi/2)
            
            temperatures.append(HourlyTemperature(
                hour: hour,
                temperature: temperature,
                time: time
            ))
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { // Simulate network delay
            self.hourlyTemperatures = temperatures
            self.currentTemp = self.getCurrentTemperature(temperatures)
            self.isLoading = false
        }
    }
    
    private func getCurrentTemperature(_ temperatures: [HourlyTemperature]) -> Double {
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: Date())
        return temperatures.first { $0.hour == currentHour }?.temperature ?? 0.0
    }
}
