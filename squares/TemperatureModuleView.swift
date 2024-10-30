import SwiftUI
import Charts

struct DailyStatView: View {
    let title: String
    let value: String
    var subtitle: String? = nil
    let color: Color
    let widthMultiplier: CGFloat
    
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            
            Text(value)
                .font(.system(.body, design: .rounded))
                .fontWeight(.medium)
                .foregroundColor(color)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity)
        .layoutPriority(1)
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
    }
}

struct TemperatureModuleView: View {
    @StateObject private var weatherService = WeatherService()
    @State private var currentTime = Date()
    @State private var selectedTime: Date?
    
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    private var next12Hours: [HourlyTemperature] {
        let endTime = currentTime.addingTimeInterval(12 * 3600)
        return weatherService.hourlyTemperatures.filter { temp in
            temp.time >= currentTime && temp.time <= endTime
        }
    }
    
    private var tempStats: (min: Double, max: Double, hotWindow: (start: Date, end: Date, avgTemp: Double)) {
        let temps = next12Hours
        let minTemp = temps.map { $0.temperature }.min() ?? 0
        let maxTemp = temps.map { $0.temperature }.max() ?? 0
        
        var hottestWindow = (start: Date(), end: Date(), avgTemp: -Double.infinity)
        let threeHours: TimeInterval = 3 * 3600
        
        for i in 0..<temps.count {
            let windowStart = temps[i].time
            let windowEnd = windowStart.addingTimeInterval(threeHours)
            
            let windowTemps = temps.filter {
                $0.time >= windowStart && $0.time <= windowEnd
            }
            
            if !windowTemps.isEmpty {
                let avgTemp = windowTemps.map { $0.temperature }.reduce(0, +) / Double(windowTemps.count)
                
                if avgTemp > hottestWindow.avgTemp {
                    hottestWindow = (start: windowStart, end: windowEnd, avgTemp: avgTemp)
                }
            }
        }
        
        return (minTemp, maxTemp, hottestWindow)
    }
    
    private var statsSection: some View {
        GeometryReader { geometry in
            HStack(spacing: 16) {
                HStack(spacing: 16) {
                    DailyStatView(
                        title: "Low",
                        value: String(format: "%.1f°", tempStats.min),
                        color: .blue,
                        widthMultiplier: 0.2
                    )
                    .frame(width: geometry.size.width * 0.2)
                    
                    DailyStatView(
                        title: "High",
                        value: String(format: "%.1f°", tempStats.max),
                        color: .red,
                        widthMultiplier: 0.2
                    )
                    .frame(width: geometry.size.width * 0.2)
                }
                
                DailyStatView(
                    title: "Hottest Window",
                    value: String(format: "%.1f° avg", tempStats.hotWindow.avgTemp),
                    subtitle: "\(formatTime(tempStats.hotWindow.start)) - \(formatTime(tempStats.hotWindow.end))",
                    color: .orange,
                    widthMultiplier: 0.6
                )
                .frame(width: geometry.size.width * 0.6)
            }
        }
        .frame(height: 60)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Today's Temperature")
                    .font(.headline)
                    .foregroundColor(.orange)
                
                Spacer()
                
                if let time = selectedTime,
                   let temp = findTemperature(for: time) {
                    Text(formatDate(time))
                    Text(String(format: "%.1f°F", temp))
                        .foregroundColor(.white)
                } else if let currentTemp = weatherService.currentTemp {
                    Text("Now")
                    Text(String(format: "%.1f°F", currentTemp))
                        .foregroundColor(.white)
                }
            }
            
            if weatherService.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
            } else if let error = weatherService.error {
                Text("Error: \(error.localizedDescription)")
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
            } else {
                VStack(spacing: 8) {
                    tempChart
                        .frame(height: 200)
                    
                    statsSection
                        .padding(.horizontal)
                }
            }
        }
        .padding()
        .background(Color(red: 23/255, green: 27/255, blue: 33/255))
        .cornerRadius(12)
        .task {
            await weatherService.fetchDailyTemperatures()
        }
        .onReceive(timer) { time in
            currentTime = time
            Task {
                await weatherService.fetchDailyTemperatures()
            }
        }
    }
    
    private var tempChart: some View {
        Chart {
            ForEach(next12Hours) { temp in
                LineMark(
                    x: .value("Time", temp.time),
                    y: .value("Temperature", temp.temperature)
                )
                .foregroundStyle(.orange.gradient)
                .interpolationMethod(.catmullRom)
            }
            
            RuleMark(x: .value("Current Time", currentTime))
                .foregroundStyle(.white.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
            
            if let time = selectedTime {
                RuleMark(x: .value("Selected Time", time))
                    .foregroundStyle(.white.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour, count: 3)) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.hour())
                    .foregroundStyle(.white)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    if let temp = value.as(Double.self) {
                        Text("\(Int(temp))°")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .chartYScale(domain: .automatic(includesZero: false))
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let xPosition = value.location.x
                                if let time: Date = proxy.value(atX: xPosition) {
                                    selectedTime = time
                                }
                            }
                            .onEnded { _ in
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    selectedTime = nil
                                }
                            }
                    )
            }
        }
    }
    
    private func findTemperature(for date: Date) -> Double? {
        let closest = next12Hours.min(by: { abs($0.time.timeIntervalSince(date)) < abs($1.time.timeIntervalSince(date)) })
        return closest?.temperature
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}
