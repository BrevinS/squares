import SwiftUI
import CoreData

// Shake gesture recognizer
extension UIDevice {
    static let deviceDidShakeNotification = Notification.Name(rawValue: "deviceDidShakeNotification")
}

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: UIDevice.deviceDidShakeNotification, object: nil)
        }
    }
}

// Shake gesture view modifier
struct DeviceShakeViewModifier: ViewModifier {
    let action: () -> Void

    func body(content: Content) -> some View {
        content
            .onAppear()
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.deviceDidShakeNotification)) { _ in
                action()
            }
    }
}

// Shake gesture view extension
extension View {
    func onShake(perform action: @escaping () -> Void) -> some View {
        self.modifier(DeviceShakeViewModifier(action: action))
    }
}

struct WorkoutDetails: Codable {
    let athlete_id: Int
    let workout_id: Int
    let distance: Double
    let average_heartrate: Double
    let average_speed: Double
    let elapsed_time: Int
    let type: String
    let elevation_high: String
    let elevation_low: String
    let max_heartrate: Int
    let max_speed: Double
    let moving_time: Int
    let name: String
    let sport_type: String
    let start_date: String
    let start_date_local: String
    let time_zone: String
    let total_elevation_gain: Double
    
    // Add a new property to store the raw JSON string
    var rawJSON: String?

    init(placeholderData: Bool = false) {
        self.athlete_id = 0
        self.workout_id = 0
        self.distance = 0
        self.average_heartrate = 0
        self.average_speed = 0
        self.elapsed_time = 0
        self.type = ""
        self.elevation_high = ""
        self.elevation_low = ""
        self.max_heartrate = 0
        self.max_speed = 0
        self.moving_time = 0
        self.name = ""
        self.sport_type = ""
        self.start_date = ""
        self.start_date_local = ""
        self.time_zone = ""
        self.total_elevation_gain = 0
        self.rawJSON = nil
    }
}

struct SquaresView: View {
    let rows = 52
    let columns = 7
    let totalItems = 364
    let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]
    let expandedHeight = 19 // Number of rows in the expanded rectangle

    @State private var blocksDropped = false
    @State private var selectedDate: Date? = nil
    @State private var showAlert = false
    @State private var expandedSquares: Set<Int> = []
    @State private var isExpanding = false
    @State private var isFullyExpanded = false
    @State private var expandedRectangleTopIndex: Int = 0
    @State private var shouldScrollToTop = false
    @State private var selectedLocalWorkout: LocalWorkout?

    
    @State private var selectedWorkoutDetails: WorkoutDetails?
    @EnvironmentObject var authManager: StravaAuthManager
    
    @Environment(\.managedObjectContext) private var viewContext
        
    @FetchRequest(
        entity: LocalWorkout.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \LocalWorkout.date, ascending: true)]
    ) var workouts: FetchedResults<LocalWorkout>

    @State private var selectedDetailedWorkout: DetailedWorkout?

    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                VStack(spacing: 0) {
                    Color.clear.frame(height: 1).id("top")
                    VStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(red: 62/255, green: 62/255, blue: 70/255), lineWidth: 2)
                                .padding(-35)
                            
                            VStack(spacing: 0) {
                                HStack(spacing: 1) {
                                    if isFullyExpanded, let date = selectedDate {
                                        Text(formattedDateHeader(date))
                                            .font(.caption)
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity, alignment: .center)
                                    } else {
                                        ForEach(0..<columns, id: \.self) { index in
                                            Text(daysOfWeek[index])
                                                .font(.caption)
                                                .foregroundColor(Color(hue: 1.0, saturation: 0.002, brightness: 0.794))
                                                .frame(width: 39, height: 20, alignment: .center)
                                        }
                                    }
                                }
                                .frame(height: 20)
                                .padding(.bottom, 5)

                                if isFullyExpanded {
                                                ZStack {
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .fill(Color.green)
                                                        .frame(height: CGFloat(expandedHeight) * 40)
                                                    
                                                    if let localWorkout = selectedLocalWorkout, let detailedWorkout = localWorkout.detailedWorkout {
                                                        WorkoutDetailView(details: detailedWorkout)
                                                            .padding()
                                                    } else {
                                                        ProgressView()
                                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                            .scaleEffect(2)
                                                    }
                                                }
                                            } else {
                                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 1), count: columns), spacing: 1) {
                                        ForEach((0..<totalItems).reversed(), id: \.self) { index in
                                            GeometryReader { geo in
                                                let isVisible = geo.frame(in: .global).minY < UIScreen.main.bounds.height && geo.frame(in: .global).maxY > 0
                                                
                                                SquareView(
                                                    date: calculateDate(for: index),
                                                    isVisible: isVisible,
                                                    blocksDropped: blocksDropped,
                                                    index: index,
                                                    totalItems: totalItems,
                                                    isExpanded: expandedSquares.contains(index) || isFullyExpanded,
                                                    workout: workoutFor(date: calculateDate(for: index)),
                                                    onTap: { onSquareTap(date: calculateDate(for: index), index: index) }
                                                )
                                            }
                                            .frame(width: 40, height: 40)
                                        }
                                    }
                                    .padding(.horizontal, 10)
                                }
                            }
                        }
                        .padding(45)
                        .background(Color(red: 14 / 255, green: 17 / 255, blue: 22 / 255))
                    }
                }
                .onAppear {
                    blocksDropped = true
                }
            }
            .background(Color(red: 14 / 255, green: 17 / 255, blue: 22 / 255))
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Date: \(formattedDate(selectedDate))"),
                    message: Text("No workout data available for this date"),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onChange(of: shouldScrollToTop) { newValue in
                if newValue {
                    withAnimation {
                        scrollProxy.scrollTo("top", anchor: .top)
                    }
                    shouldScrollToTop = false
                }
            }
            .onShake {
                resetView()
            }
        }
    }
    
    private func calculateDate(for index: Int) -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return calendar.date(byAdding: .day, value: index + 2 - 365, to: today)!
    }
    
    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy"
        return formatter.string(from: date)
    }
    
    private func formattedDateHeader(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private func startRippleEffect(from index: Int) {
        guard !isExpanding else { return }
        isExpanding = true
        expandedSquares.removeAll()
        isFullyExpanded = false
        
        let selectedRow = index / columns
        let topRow = max(0, min(rows - expandedHeight, selectedRow - expandedHeight / 2))
        expandedRectangleTopIndex = topRow * columns
        
        func expand(fromIndex: Int, currentLevel: Int) {
            guard currentLevel < 30 && expandedSquares.count < expandedHeight * columns else {
                completeExpansion()
                return
            }
            
            let adjacentIndices = getAdjacentIndices(for: fromIndex)
            let newIndices = adjacentIndices.filter {
                !expandedSquares.contains($0) &&
                $0 >= expandedRectangleTopIndex &&
                $0 < expandedRectangleTopIndex + (expandedHeight * columns)
            }
            expandedSquares.formUnion(newIndices)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
                for idx in newIndices {
                    expand(fromIndex: idx, currentLevel: currentLevel + 1)
                }
            }
        }
        
        expandedSquares.insert(index)
        expand(fromIndex: index, currentLevel: 0)
    }
    
    private func completeExpansion() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.isFullyExpanded = true
            }
            self.isExpanding = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.shouldScrollToTop = true
            }
        }
    }
    
    private func getAdjacentIndices(for index: Int) -> [Int] {
        let row = index / columns
        let col = index % columns
        var adjacent: [Int] = []
        
        for i in -1...1 {
            for j in -1...1 {
                let newRow = row + i
                let newCol = col + j
                if newRow >= 0 && newRow < rows && newCol >= 0 && newCol < columns {
                    adjacent.append(newRow * columns + newCol)
                }
            }
        }
        
        return adjacent
    }
    
    private func resetView() {
        withAnimation(.easeInOut(duration: 0.3)) {
            blocksDropped = false
            selectedDate = nil
            expandedSquares.removeAll()
            isExpanding = false
            isFullyExpanded = false
            expandedRectangleTopIndex = 0
            shouldScrollToTop = false
            selectedWorkoutDetails = nil
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.3)) {
                blocksDropped = true
            }
        }
    }
    
    private func workoutFor(date: Date) -> LocalWorkout? {
        let calendar = Calendar.current
        return workouts.first { calendar.isDate($0.date!, inSameDayAs: date) }
    }
    
    private func onSquareTap(date: Date, index: Int) {
        selectedDate = date
        if let workout = workoutFor(date: date) {
            fetchWorkoutDetails(for: workout)
            startRippleEffect(from: index)
        } else {
            showAlert = true
        }
    }
    
    private func fetchWorkoutDetails(for workout: LocalWorkout, forceRefresh: Bool = false) {
        if !forceRefresh && workout.detailedWorkout != nil {
            self.selectedLocalWorkout = workout
            return
        }
        
        guard let athleteId = authManager.athleteId else {
            print("Error: No athlete ID available")
            return
        }
        
        let urlString = "https://tier2dqr7a.execute-api.us-west-2.amazonaws.com/prod/workout?athlete_id=\(athleteId)&workout_id=\(workout.id)"
        guard let url = URL(string: urlString) else {
            print("Error: Invalid URL")
            return
        }
        
        print("Fetching workout details from URL: \(urlString)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching workout details: \(error)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Response Status code: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("Error: No data received")
                return
            }
            
            print("Received data: \(String(data: data, encoding: .utf8) ?? "Unable to convert data to string")")
            
            do {
                // First, try to clean up the JSON string
                if var jsonString = String(data: data, encoding: .utf8) {
                    jsonString = jsonString.replacingOccurrences(of: ": ,", with: ": null,")
                    jsonString = jsonString.replacingOccurrences(of: ":,", with: ":null,")
                    
                    if let cleanedData = jsonString.data(using: .utf8),
                       let jsonResult = try JSONSerialization.jsonObject(with: cleanedData, options: []) as? [String: Any] {
                        DispatchQueue.main.async {
                            self.saveDetailedWorkout(jsonResult, for: workout)
                        }
                    } else {
                        print("Error: Unable to parse cleaned JSON data")
                    }
                } else {
                    print("Error: Unable to convert data to string")
                }
            } catch {
                print("Error decoding workout details: \(error)")
            }
        }.resume()
    }

    private func saveDetailedWorkout(_ details: [String: Any], for localWorkout: LocalWorkout) {
        viewContext.perform {
            let detailedWorkout = DetailedWorkout(context: viewContext)
            detailedWorkout.average_heartrate = details["average_heartrate"] as? Double ?? 0
            detailedWorkout.average_speed = details["average_speed"] as? Double ?? 0
            detailedWorkout.elapsed_time = Int64(details["elapsed_time"] as? Int ?? 0)
            detailedWorkout.elevation_high = details["elevation_high"] as? String ?? ""
            detailedWorkout.elevation_low = details["elevation_low"] as? String ?? ""
            detailedWorkout.max_heartrate = Int64(details["max_heartrate"] as? Int ?? 0)
            detailedWorkout.max_speed = details["max_speed"] as? Double ?? 0
            detailedWorkout.moving_time = Int64(details["moving_time"] as? Int ?? 0)
            detailedWorkout.name = details["name"] as? String ?? ""
            detailedWorkout.sport_type = details["sport_type"] as? String ?? ""
            detailedWorkout.start_date = (details["start_date"] as? String).flatMap { ISO8601DateFormatter().date(from: $0) } ?? Date()
            detailedWorkout.start_date_local = (details["start_date_local"] as? String).flatMap { ISO8601DateFormatter().date(from: $0) } ?? Date()
            detailedWorkout.time_zone = details["time_zone"] as? String ?? ""
            detailedWorkout.total_elevation_gain = details["total_elevation_gain"] as? Double ?? 0
            detailedWorkout.type = details["type"] as? String ?? ""
            detailedWorkout.workout_id = Int64(details["workout_id"] as? Int ?? 0)
            
            localWorkout.detailedWorkout = detailedWorkout
            
            do {
                try viewContext.save()
                print("Saved detailed workout data")
                self.selectedLocalWorkout = localWorkout
            } catch {
                print("Error saving detailed workout: \(error)")
            }
        }
    }
}

struct WorkoutDetailView: View {
    let details: DetailedWorkout
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text(details.name ?? "Unnamed Workout")
                    .font(.title)
                    .padding(.bottom)
                
                Group {
                    DetailRow(title: "Type", value: details.type ?? "Unknown")
                    DetailRow(title: "Duration", value: formatDuration(Int(details.elapsed_time)))
                    DetailRow(title: "Average Speed", value: String(format: "%.2f km/h", details.average_speed * 3.6))
                    DetailRow(title: "Average Heart Rate", value: String(format: "%.1f bpm", details.average_heartrate))
                    DetailRow(title: "Max Heart Rate", value: "\(details.max_heartrate) bpm")
                    DetailRow(title: "Start Time", value: formatDate(details.start_date_local ?? Date()))
                    DetailRow(title: "Elevation Gain", value: String(format: "%.1f m", details.total_elevation_gain))
                }
            }
        }
        .padding()
        .foregroundColor(.white)
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, remainingSeconds)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            Spacer()
            Text(value)
                .font(.body)
        }
        .padding(.vertical, 4)
    }
}

struct SquaresView_Previews: PreviewProvider {
    static var previews: some View {
        SquaresView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(StravaAuthManager())
    }
}
