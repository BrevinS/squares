import SwiftUI
import Charts
import CoreData

private struct CountdownView: View {
    let targetDate: Date
    @State private var timeRemaining: TimeInterval = 0
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        Text(formatTimeRemaining(timeRemaining))
            .font(.subheadline)
            .foregroundColor(.gray)
            .onAppear {
                updateTimeRemaining()
            }
            .onReceive(timer) { _ in
                updateTimeRemaining()
            }
    }
    
    private func updateTimeRemaining() {
        timeRemaining = targetDate.timeIntervalSince(Date())
    }
    
    private func formatTimeRemaining(_ timeInterval: TimeInterval) -> String {
        if timeInterval <= 0 {
            return "Weight entry is now available!"
        }
        
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) / 60 % 60
        let seconds = Int(timeInterval) % 60
        
        return String(format: "Next weight entry available in: %02d:%02d:%02d", hours, minutes, seconds)
    }
}

struct WeightModuleView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var weightService: WeightService
    @State private var newWeight: String = ""
    @State private var selectedMeasurement: WeightMeasurement?
    @FocusState private var isInputFocused: Bool
    @State private var currentDate = Date()
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    init() {
        _weightService = StateObject(wrappedValue: WeightService(context: PersistenceController.shared.container.viewContext))
    }
    
    private var nextWeightEntryDate: Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        // If it's past midnight but before 12:01 AM, use current day
        if calendar.component(.hour, from: Date()) == 0 && calendar.component(.minute, from: Date()) == 0 {
            components.day = components.day
        } else {
            // Otherwise, use next day
            components.day = (components.day ?? 0) + 1
        }
        components.hour = 0
        components.minute = 1
        components.second = 0
        
        return calendar.date(from: components) ?? Date()
    }
    
    private var canEnterWeight: Bool {
        let calendar = Calendar.current
        
        // Get start of current day (12:01 AM)
        var components = calendar.dateComponents([.year, .month, .day], from: currentDate)
        components.hour = 0
        components.minute = 1
        components.second = 0
        
        guard let startOfDay = calendar.date(from: components) else { return false }
        
        // Check if there's any weight entry after startOfDay
        return !weightService.weightMeasurements.contains { measurement in
            measurement.wrappedDate >= startOfDay
        }
    }
    
    private var weightStats: (min: Double, max: Double, average: Double) {
        let weights = weightService.weightMeasurements
        let weightValues = weights.map { $0.wrappedWeight }
        return (
            min: weightValues.min() ?? 0,
            max: weightValues.max() ?? 0,
            average: weightValues.reduce(0, +) / Double(max(weightValues.count, 1))
        )
    }
    
    private var statsSection: some View {
        GeometryReader { geometry in
            HStack(spacing: 16) {
                DailyStatView(
                    title: "Lowest",
                    value: String(format: "%.1f lbs", weightStats.min),
                    color: .blue,
                    widthMultiplier: 0.33
                )
                .frame(width: geometry.size.width * 0.33)
                
                DailyStatView(
                    title: "Highest",
                    value: String(format: "%.1f lbs", weightStats.max),
                    color: .red,
                    widthMultiplier: 0.33
                )
                .frame(width: geometry.size.width * 0.33)
                
                DailyStatView(
                    title: "Average",
                    value: String(format: "%.1f lbs", weightStats.average),
                    color: .orange,
                    widthMultiplier: 0.33
                )
                .frame(width: geometry.size.width * 0.33)
            }
        }
        .frame(height: 60)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Weight Tracking")
                    .font(.headline)
                    .foregroundColor(.orange)
                
                Spacer()
                
                if let measurement = selectedMeasurement {
                    Text(formatDate(measurement.wrappedDate))
                    Text(String(format: "%.1f lbs", measurement.wrappedWeight))
                        .foregroundColor(.white)
                }
            }
            
            VStack(spacing: 8) {
                weightChart
                    .frame(height: 200)
                
                statsSection
                    .padding(.horizontal)
                
                if canEnterWeight {
                    HStack {
                        TextField("Enter weight", text: $newWeight)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .foregroundColor(.white)
                            .focused($isInputFocused)
                        
                        Button("Add") {
                            if let weight = Double(newWeight) {
                                weightService.addWeight(weight)
                                newWeight = ""
                                isInputFocused = false
                            }
                        }
                        .buttonStyle(.bordered)
                        .tint(.orange)
                        .disabled(newWeight.isEmpty)
                    }
                    .padding(.top)
                } else {
                    CountdownView(targetDate: nextWeightEntryDate)
                        .padding(.top)
                }
            }
        }
        .padding()
        .background(Color(red: 23/255, green: 27/255, blue: 33/255))
        .cornerRadius(12)
        .onReceive(timer) { _ in
            currentDate = Date()
        }
    }
    
    private var weightChart: some View {
        Chart {
            ForEach(weightService.weightMeasurements) { measurement in
                LineMark(
                    x: .value("Date", measurement.wrappedDate),
                    y: .value("Weight", measurement.wrappedWeight)
                )
                .foregroundStyle(.orange.gradient)
                .interpolationMethod(.linear) // Changed from .catmullRom to .linear
            }
            
            if let measurement = selectedMeasurement {
                RuleMark(
                    x: .value("Selected Date", measurement.wrappedDate)
                )
                .foregroundStyle(.white.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.day())
                    .foregroundStyle(.white)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    if let weight = value.as(Double.self) {
                        Text("\(Int(weight))")
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
                                guard let date: Date = proxy.value(atX: xPosition) else { return }
                                
                                selectedMeasurement = weightService.weightMeasurements
                                    .min(by: {
                                        abs($0.wrappedDate.timeIntervalSince(date)) < abs($1.wrappedDate.timeIntervalSince(date))
                                    })
                            }
                            .onEnded { _ in
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    selectedMeasurement = nil
                                }
                            }
                    )
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}
