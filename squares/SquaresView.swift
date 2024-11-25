import SwiftUI
import CoreData

struct SquaresView: View {
    let rows = 26
    let columns = 7
    let totalItems = 182
    @State private var daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]
    let expandedHeight = 19
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        entity: Habit.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Habit.createdAt, ascending: true)
        ]
    ) private var habits: FetchedResults<Habit>

    @FetchRequest(
        entity: LocalWorkout.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \LocalWorkout.date, ascending: true)
        ],
        animation: .default
    ) private var workouts: FetchedResults<LocalWorkout>
    
    let squareSize: CGFloat = 40
    let squareSpacing: CGFloat = 1
    let boundingBoxPadding: CGFloat = 20
    
    @State private var blocksDropped = false
    @State private var selectedDate: Date? = nil
    @State private var showAlert = false
    @State private var expandedSquares: Set<Int> = []
    @State private var isExpanding = false
    @State private var isFullyExpanded = false
    @State private var expandedRectangleTopIndex: Int = 0
    @State private var shouldScrollToTop = false
    @State private var selectedLocalWorkout: LocalWorkout?
    @State private var refreshTrigger = false
    
    @State private var selectedTypes: Set<String> = []
    
    // Card Variables
    @State private var cardRotation: Double = 0
    @State private var cardScale: CGFloat = 1
    @State private var cardOpacity: Double = 1
    @State private var selectedSquarePosition: CGPoint = .zero
    
    @State private var selectedSquareIndex: Int?
    @State private var animationOrigin: Int?
    
    @State private var cardOffset: CGFloat = 0
    @State private var isDragging = false
    @GestureState private var dragState = CGSize.zero

    // Strava refresh
    @State private var isRefreshing = false
    @State private var selectedWorkoutDetails: WorkoutDetails?
    @EnvironmentObject var authManager: StravaAuthManager
    
    // Initialize subjects with defaults
    @State private var selectedHabitNames: Set<String> = []
    
  
    
    private var gridWidth: CGFloat {
        CGFloat(columns) * squareSize + CGFloat(columns - 1) * squareSpacing
    }
    
    private var gridHeight: CGFloat {
        CGFloat(rows) * squareSize + CGFloat(rows - 1) * squareSpacing
    }
    
    private func shouldShowWorkout(_ workout: LocalWorkout?) -> Bool {
        guard let workout = workout,
              let workoutType = workout.type else {
            return false
        }
        
        // Only show Run workouts
        return workoutType == "Run"
    }
    
    private func printWorkouts() {
        print("Total workouts in CoreData: \(workouts.count)")
        for workout in workouts {
            print("Workout ID: \(workout.id), Date: \(workout.date?.description ?? "nil"), Type: \(workout.type ?? "nil")")
        }
    }

    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                VStack(spacing: 0) {
                    HStack {
                            settingsButton
                            Spacer()
                            Text("Workout Graph")
                                .font(.largeTitle)
                                .foregroundColor(.orange)
                            Spacer()
                            addButton
                        }
                        .padding(.horizontal)
                        .padding(.top, 1)
                        .padding(.bottom, 10)
                        .background(Color(red: 14/255, green: 17/255, blue: 22/255))
                        
                        SubjectFilterBar(selectedTypes: $selectedTypes)
                        .padding(.bottom, 10)
                        
                        Color.clear.frame(height: 1).id("top")
                        
                        VStack {
                            ZStack {
                                // Bounding box
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(red: 62/255, green: 62/255, blue: 70/255), lineWidth: 2)
                                    .frame(
                                        width: gridWidth + (boundingBoxPadding * 2),
                                        height: gridHeight + (boundingBoxPadding * 2) + 30
                                    )
                                
                                VStack(spacing: 0) {
                                    // Updated days/back button header
                                    HStack(spacing: squareSpacing) {
                                        if isFullyExpanded {
                                            // Back button aligned with day letters
                                            HStack(spacing: 0) {
                                                Button(action: resetView) {
                                                    HStack(spacing: 4) {
                                                        Image(systemName: "chevron.left")
                                                            .font(.system(size: 14))
                                                        Text("Back")
                                                            .font(.caption)
                                                    }
                                                    .foregroundColor(.white)
                                                    .padding(.vertical, 4)
                                                    .padding(.horizontal, 8)
                                                    .background(Color.gray.opacity(0.3))
                                                    .cornerRadius(4)
                                                }
                                                
                                                Spacer()
                                                
                                                if let date = selectedDate {
                                                    Text(formattedDateHeader(date))
                                                        .font(.caption)
                                                        .foregroundColor(.white)
                                                }
                                                
                                                Spacer()
                                            }
                                            .frame(width: gridWidth)
                                        } else {
                                            ForEach(0..<columns, id: \.self) { index in
                                                Text(daysOfWeek[index])
                                                    .font(.caption)
                                                    .foregroundColor(Color(hue: 1.0, saturation: 0.002, brightness: 0.794))
                                                    .frame(width: squareSize, height: 20)
                                            }
                                        }
                                    }
                                    .frame(height: 20)
                                    .padding(.bottom, 10)
                                    
                                    // Rest of the content (expanded card or grid) remains the same
                                    if isFullyExpanded {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.green)
                                                .frame(
                                                    width: gridWidth,
                                                    height: gridHeight
                                                )
                                            
                                            if let localWorkout = selectedLocalWorkout {
                                                WorkoutDetailView(localWorkout: localWorkout)
                                                    .frame(
                                                        width: gridWidth,
                                                        height: gridHeight
                                                    )
                                                    .clipped()
                                            } else {
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                    .scaleEffect(2)
                                            }
                                        }
                                        .rotation3DEffect(
                                            .degrees(cardRotation),
                                            axis: (x: 0, y: 1, z: 0)
                                        )
                                        .scaleEffect(cardScale)
                                        .opacity(cardOpacity)
                                    } else {
                                    LazyVGrid(
                                        columns: Array(repeating: GridItem(.fixed(squareSize), spacing: squareSpacing), count: columns),
                                        spacing: squareSpacing
                                    ) {
                                        ForEach((0..<totalItems).reversed(), id: \.self) { index in
                                            GeometryReader { geo in
                                                let isVisible = geo.frame(in: .global).minY < UIScreen.main.bounds.height + 160 &&
                                                              geo.frame(in: .global).maxY > -160
                                                
                                                SquareView(
                                                    date: calculateDate(for: index),
                                                    isVisible: isVisible,
                                                    blocksDropped: blocksDropped,
                                                    index: index,
                                                    totalItems: totalItems,
                                                    isExpanded: expandedSquares.contains(index) || isFullyExpanded,
                                                    workout: workoutFor(date: calculateDate(for: index)),
                                                    animationDelay: calculateAnimationDelay(for: index),
                                                    onTap: { onSquareTap(date: calculateDate(for: index), index: index) }
                                                )
                                            }
                                            .frame(width: squareSize, height: squareSize)
                                        }
                                    }
                                }
                            }
                            .padding(boundingBoxPadding)
                        }
                        .background(Color(red: 14/255, green: 17/255, blue: 22/255))
                    }
                }
                .id(refreshTrigger)
                .onAppear {
                    blocksDropped = true
                    alignDaysOfWeek()
                    printWorkouts()
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
            .onChange(of: shouldScrollToTop) { oldValue, newValue in
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
    
    private func hasHabitEntry(for date: Date) -> Bool {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let fetchRequest: NSFetchRequest<HabitEntry> = HabitEntry.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "date >= %@ AND date < %@ AND completed = YES",
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        fetchRequest.fetchLimit = 1
        
        do {
            let count = try viewContext.count(for: fetchRequest)
            return count > 0
        } catch {
            print("❌ Error checking for habit entries: \(error)")
            return false
        }
    }
    
    // Helper function to get habit color for a date
    private func getHabitColor(for date: Date) -> Color {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let fetchRequest: NSFetchRequest<HabitEntry> = HabitEntry.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "date >= %@ AND date < %@ AND completed = YES",
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        
        do {
            let entries = try viewContext.fetch(fetchRequest)
            if let firstEntry = entries.first,
               let habit = firstEntry.habit,
               let colorHex = habit.colorHex {
                return Color(hex: colorHex) ?? .gray
            }
        } catch {
            print("❌ Error fetching habit entries: \(error)")
        }
        
        return Color(red: 23/255, green: 27/255, blue: 33/255)
    }
    
    // Update FetchRequests
    private var habitsRequest: FetchRequest<Habit> {
        FetchRequest(
            entity: Habit.entity(),
            sortDescriptors: [
                NSSortDescriptor(keyPath: \Habit.createdAt, ascending: true)
            ]
        )
    }
    
    private var workoutsRequest: FetchRequest<LocalWorkout> {
        FetchRequest(
            entity: LocalWorkout.entity(),
            sortDescriptors: [
                NSSortDescriptor(keyPath: \LocalWorkout.date, ascending: true)
            ],
            animation: .default
        )
    }
    
    private func getSelectedHabits() -> [Habit] {
        return habits.filter { habit in
            selectedHabitNames.contains(habit.name ?? "")
        }
    }
    
    private func calculateAnimationDelay(for index: Int) -> Double {
        guard let origin = animationOrigin else { return 0 }
        
        let originRow = origin / columns
        let originCol = origin % columns
        let currentRow = index / columns
        let currentCol = index % columns
        
        // Calculate Manhattan distance from origin square
        let distance = abs(currentRow - originRow) + abs(currentCol - originCol)
        
        // Return delay based on distance
        return Double(distance) * 0.02 // Adjust multiplier to control animation speed
    }

    private func calculateSquarePosition(for index: Int) -> (row: Int, col: Int) {
        let row = index / columns
        let col = index % columns
        return (row, col)
    }
    
    private func workoutFor(date: Date) -> LocalWorkout? {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        
        // Find any Run workout that falls within this day
        let workout = workouts.first { workout in
            guard let workoutDate = workout.date,
                  let workoutType = workout.type else { return false }
            return workoutDate >= dayStart && workoutDate < dayEnd && workoutType == "Run"
        }
        
        return workout
    }
    
    private var settingsButton: some View {
        Button(action: {
            // Add your settings action here
        }) {
            Image(systemName: "square.stack.3d.down.right.fill")
                .font(.system(size: 28))
                .foregroundColor(.orange)
        }
    }
    
    private var addButton: some View {
        Button(action: {
            // Keep your existing refresh action here
            refreshAllWorkouts()
        }) {
            Image(systemName: "figure.run")
                .font(.system(size: 28))
                .foregroundColor(.orange)
        }
        .disabled(isRefreshing)
        .rotationEffect(Angle(degrees: isRefreshing ? 360 : 0))
        .animation(isRefreshing ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshing)
    }
    
    private func alignDaysOfWeek() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        
        // Adjust the weekday to align with the array index (0-6)
        let adjustedWeekday = weekday
        
        // Rotate the days array so that today's day is at index 0
        let rotatedDays = Array(daysOfWeek[adjustedWeekday...] + daysOfWeek[..<adjustedWeekday])
        
        // Reverse the order to make the days progress forward
        daysOfWeek = Array(rotatedDays.reversed())
    }
    
    private func calculateDate(for index: Int) -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return calendar.date(byAdding: .day, value: -(totalItems - 1 - index), to: today)!
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
        // Start the card flip animation
        withAnimation(.easeInOut(duration: 0.5)) {
            cardRotation = 90
            cardScale = 0.5
            cardOpacity = 0
        }
        
        // After the card flip, start the squares animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.3)) {
                blocksDropped = false
                isExpanding = false
                isFullyExpanded = false
                expandedSquares.removeAll()
            }
            
            // Set the animation origin to the selected square
            animationOrigin = selectedSquareIndex
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    blocksDropped = true
                }
                
                // Reset remaining state
                selectedDate = nil
                expandedRectangleTopIndex = 0
                selectedWorkoutDetails = nil
                cardRotation = 0
                cardScale = 1
                cardOpacity = 1
            }
        }
    }
    
    private func onSquareTap(date: Date, index: Int) {
        selectedDate = date
        selectedSquareIndex = index
        animationOrigin = index
        
        if let workout = workoutFor(date: date) {
            selectedLocalWorkout = workout
            if workout.detailedWorkout == nil {
                print("Fetching detailed workout for ID: \(workout.id)")
                fetchWorkoutDetails(for: workout.id)
            } else {
                print("Detailed workout already available for ID: \(workout.id)")
            }
            
            // Reset animation properties
            cardRotation = 0
            cardScale = 1
            cardOpacity = 1
            
            startRippleEffect(from: index)
        } else {
            showAlert = true
        }
    }
    
    private func refreshAllWorkouts() {
        guard !isRefreshing else { return }
        isRefreshing = true
        
        authManager.fetchWorkoutSummaries { success in
            if success {
                // Check for new or updated workouts
                let existingWorkouts = Set(self.workouts.map { $0.id })
                let newWorkouts = self.authManager.workoutSummaries.filter { !existingWorkouts.contains($0.id) }
                
                for workout in newWorkouts {
                    self.fetchWorkoutDetails(for: workout.id)
                }
            } else {
                print("Failed to fetch workout summaries")
            }
            self.isRefreshing = false
        }
    }
    
    private func fetchWorkoutDetails(for workoutId: Int64) {
        guard let athleteId = authManager.athleteId else {
            print("Error: No athlete ID available")
            return
        }
        
        let urlString = "https://tier2dqr7a.execute-api.us-west-2.amazonaws.com/prod/workout?athlete_id=\(athleteId)&workout_id=\(workoutId)"
        guard let url = URL(string: urlString) else {
            print("Error: Invalid URL")
            return
        }
        
        print("Fetching workout details for workout ID: \(workoutId)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Network error fetching workout details: \(error)")
                return
            }
            
            guard let data = data else {
                print("Error: No data received")
                return
            }
            
            // Clean up the JSON response by replacing empty values with null
            if var jsonString = String(data: data, encoding: .utf8) {
                jsonString = jsonString.replacingOccurrences(of: ": ,", with: ": null,")
                jsonString = jsonString.replacingOccurrences(of: ": \n", with: ": null\n")
                
                guard let cleanedData = jsonString.data(using: .utf8) else {
                    print("Error: Could not create cleaned data")
                    return
                }
                
                do {
                    if let jsonResult = try JSONSerialization.jsonObject(with: cleanedData) as? [String: Any] {
                        print("Successfully parsed workout details")
                        DispatchQueue.main.async {
                            self.saveDetailedWorkout(jsonResult, for: workoutId)
                        }
                    }
                } catch {
                    print("JSON Parsing error: \(error)")
                    print("Cleaned JSON string: \(jsonString)")
                }
            }
        }.resume()
    }

    private func saveDetailedWorkout(_ details: [String: Any], for workoutId: Int64) {
        viewContext.perform {
            if let existingWorkout = self.workouts.first(where: { $0.id == workoutId }) {
                let detailedWorkout = existingWorkout.detailedWorkout ?? DetailedWorkout(context: viewContext)
                
                // Handle potential nil or NSNull values
                detailedWorkout.average_heartrate = (details["average_heartrate"] as? NSNumber)?.doubleValue ?? 0
                detailedWorkout.average_speed = (details["average_speed"] as? NSNumber)?.doubleValue ?? 0
                detailedWorkout.elapsed_time = Int64(details["elapsed_time"] as? Int ?? 0)
                detailedWorkout.elevation_high = (details["elevation_high"] as? String) ?? ""
                detailedWorkout.elevation_low = (details["elevation_low"] as? String) ?? ""
                detailedWorkout.max_heartrate = Int64((details["max_heartrate"] as? NSNumber)?.intValue ?? 0)
                detailedWorkout.max_speed = (details["max_speed"] as? NSNumber)?.doubleValue ?? 0
                detailedWorkout.moving_time = Int64(details["moving_time"] as? Int ?? 0)
                detailedWorkout.name = (details["name"] as? String) ?? ""
                detailedWorkout.sport_type = (details["sport_type"] as? String) ?? ""
                
                // Handle date parsing
                let dateFormatter = ISO8601DateFormatter()
                if let startDateString = details["start_date"] as? String {
                    detailedWorkout.start_date = dateFormatter.date(from: startDateString) ?? Date()
                }
                if let startDateLocalString = details["start_date_local"] as? String {
                    detailedWorkout.start_date_local = dateFormatter.date(from: startDateLocalString) ?? Date()
                }
                
                detailedWorkout.time_zone = (details["time_zone"] as? String) ?? ""
                detailedWorkout.total_elevation_gain = (details["total_elevation_gain"] as? NSNumber)?.doubleValue ?? 0
                detailedWorkout.type = (details["type"] as? String) ?? ""
                detailedWorkout.workout_id = workoutId
                
                existingWorkout.detailedWorkout = detailedWorkout
                
                print("Saving detailed workout data for workout ID: \(workoutId)")
                
                do {
                    try viewContext.save()
                    print("Core Data context saved successfully")
                    self.selectedLocalWorkout = existingWorkout
                } catch {
                    print("Error saving detailed workout: \(error)")
                }
            }
        }
    }
    
    private func updateDetailedWorkout(_ detailedWorkout: DetailedWorkout, with details: [String: Any]) {
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
        
        print("Updated detailed workout: \(detailedWorkout)")
    }
}
    
    struct WorkoutDetailView: View {
        let localWorkout: LocalWorkout
            
        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(localWorkout.detailedWorkout?.name ?? "Unnamed Workout")
                        .font(.title)
                        .padding(.bottom, 8)
                    
                    Group {
                        DetailRow(title: "Type", value: localWorkout.detailedWorkout?.type ?? "Unknown")
                        DetailRow(title: "Duration", value: formatDuration(Int(localWorkout.detailedWorkout?.elapsed_time ?? 0)))
                        DetailRow(title: "Distance", value: String(format: "%.2f miles", localWorkout.distance / 1609.344))
                        if let avgSpeed = localWorkout.detailedWorkout?.average_speed {
                            DetailRow(title: "Average Speed", value: String(format: "%.2f mph", avgSpeed * 2.23694))
                        }
                        if let avgHeartRate = localWorkout.detailedWorkout?.average_heartrate, avgHeartRate > 0 {
                            DetailRow(title: "Average Heart Rate", value: String(format: "%.0f bpm", avgHeartRate))
                        }
                        if let maxHeartRate = localWorkout.detailedWorkout?.max_heartrate, maxHeartRate > 0 {
                            DetailRow(title: "Max Heart Rate", value: "\(maxHeartRate) bpm")
                        }
                        DetailRow(title: "Start Time", value: formatDate(localWorkout.detailedWorkout?.start_date ?? Date()))
                        if let elevationGain = localWorkout.detailedWorkout?.total_elevation_gain {
                            DetailRow(title: "Elevation Gain", value: String(format: "%.1f ft", elevationGain * 3.28084))
                        }
                        if let elevLow = localWorkout.detailedWorkout?.elevation_low, !elevLow.isEmpty {
                            DetailRow(title: "Elevation Low", value: String(format: "%.1f ft", (Double(elevLow) ?? 0) * 3.28084))
                        }
                        if let elevHigh = localWorkout.detailedWorkout?.elevation_high, !elevHigh.isEmpty {
                            DetailRow(title: "Elevation High", value: String(format: "%.1f ft", (Double(elevHigh) ?? 0) * 3.28084))
                        }
                    }
                }
                .padding()
            }
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
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                Text(value)
                    .font(.body)
            }
            .padding(.vertical, 2)
        }
    }

struct SquaresView_Previews: PreviewProvider {
    static let context: NSManagedObjectContext = {
        let context = PersistenceController.preview.container.viewContext
        
        // Add sample workout data
        let workout = LocalWorkout(context: context)
        workout.id = Int64(1)
        workout.date = Date()
        workout.distance = 5000  // 5km
        workout.type = "Run"
        
        // Add detailed workout data
        let detailedWorkout = DetailedWorkout(context: context)
        detailedWorkout.workout_id = workout.id
        detailedWorkout.name = "Morning Run"
        detailedWorkout.type = "Run"
        detailedWorkout.average_heartrate = 150
        detailedWorkout.average_speed = 3.5
        detailedWorkout.elapsed_time = 1800
        detailedWorkout.max_heartrate = 175
        detailedWorkout.max_speed = 4.2
        detailedWorkout.moving_time = 1750
        detailedWorkout.start_date = Date()
        detailedWorkout.start_date_local = Date()
        detailedWorkout.time_zone = "UTC"
        detailedWorkout.total_elevation_gain = 100
        
        workout.detailedWorkout = detailedWorkout
        
        // Add sample habit data
        let habit = Habit(context: context)
        habit.id = UUID()
        habit.name = "Running"
        habit.colorHex = "#0000FF"  // Blue
        habit.isBinary = true
        habit.hasNotes = false
        habit.isDefaultHabit = true
        habit.createdAt = Date()
        
        // Save the context
        do {
            try context.save()
        } catch {
            print("Error setting up preview context: \(error)")
        }
        
        return context
    }()
    
    static var previews: some View {
        NavigationView {
            SquaresView()
                .environment(\.managedObjectContext, context)
                .environmentObject(StravaAuthManager())
        }
        .previewDevice(PreviewDevice(rawValue: "iPhone 15 Pro"))
        .previewDisplayName("iPhone 15 Pro")
    }
}
