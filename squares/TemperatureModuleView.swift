// TemperatureModuleView.swift
import SwiftUI
import Charts

struct TemperatureModuleView: View {
    @StateObject private var weatherService = WeatherService()
    @State private var currentTime = Date()
    
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Temperature")
                .font(.headline)
                .foregroundColor(.orange)
            
            if weatherService.isLoading {
                ProgressView()
                    .frame(height: 200)
            } else {
                tempChart
            }
        }
        .padding()
        .background(Color(red: 23/255, green: 27/255, blue: 33/255))
        .cornerRadius(12)
        .onAppear {
            weatherService.fetchDailyTemperatures()
        }
        .onReceive(timer) { time in
            currentTime = time
        }
    }
    
    private var tempChart: some View {
        Chart {
            ForEach(weatherService.hourlyTemperatures) { temp in
                LineMark(
                    x: .value("Time", temp.time),
                    y: .value("Temperature", temp.temperature)
                )
                .foregroundStyle(.orange.gradient)
            }
            
            RuleMark(x: .value("Current Time", currentTime))
                .foregroundStyle(.white.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                .annotation(position: .top) {
                    Text("Now")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.gray.opacity(0.5))
                        .cornerRadius(4)
                }
            
            if let currentTemp = weatherService.currentTemp {
                PointMark(
                    x: .value("Current Time", currentTime),
                    y: .value("Temperature", currentTemp)
                )
                .foregroundStyle(.white)
                .symbolSize(100)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour, count: 3)) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.hour())
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
        .frame(height: 200)
        .chartYScale(domain: .automatic(includesZero: false))
    }
}

struct TemperatureModuleView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                TemperatureModuleView()
                    .frame(width: 350)
            }
            .padding()
        }
        .background(Color(red: 14/255, green: 17/255, blue: 22/255))
    }
}
