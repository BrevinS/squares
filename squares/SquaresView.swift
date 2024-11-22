import SwiftUI
import CoreData

struct SquaresView: View {
    let rows = 52
    let columns = 7
    let totalItems = 364
    @State private var daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]
    let expandedHeight = 19
    
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
    
    // Strava refresh
    @State private var isRefreshing = false
    @State private var selectedWorkoutDetails: WorkoutDetails?
    @EnvironmentObject var authManager: StravaAuthManager
    
    // Initialize subjects with defaults
    @State private var subjects: [Subject] = Subject.defaultSubjects()
    
    // Initialize selectedSubjects with all subjects except "Workouts" since it's the default view state
    @State private var selectedSubjects: Set<Subject> = Set(Subject.defaultSubjects().filter { $0.name != "Workouts" && $0.isDefaultSelected })
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        entity: LocalWorkout.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \LocalWorkout.date, ascending: true)]
    ) var workouts: FetchedResults<LocalWorkout>
    
    private func shouldShowWorkout(_ workout: LocalWorkout?) -> Bool {
        guard let workout = workout,
              let workoutType = workout.type else {
            return false
        }
        
        // If no types are selected, show all workouts
        if selectedTypes.isEmpty {
            return true
        }
        
        // Show workout if its type is selected
        return selectedTypes.contains(workoutType)
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
                    
                    // Existing content
                    Color.clear.frame(height: 1).id("top")
                    
                    VStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(red: 62/255, green: 62/255, blue: 70/255), lineWidth: 2)
                                .padding(-35)
                            
                            VStack(spacing: 0) {
                                // Update the HStack in the header section to include the back button
                                HStack(spacing: 1) {
                                    if isFullyExpanded, let date = selectedDate {
                                        HStack {
                                            Button(action: resetView) {
                                                Image(systemName: "chevron.left")
                                                    .font(.system(size: 20))
                                                    .foregroundColor(.white)
                                            }
                                            .padding(.leading, 8)
                                            
                                            Spacer()
                                            
                                            Text(formattedDateHeader(date))
                                                .font(.caption)
                                                .foregroundColor(.white)
                                            
                                            Spacer()
                                        }
                                        .frame(maxWidth: .infinity)
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
                                        
                                        if let localWorkout = selectedLocalWorkout {
                                            WorkoutDetailView(localWorkout: localWorkout)
                                                .padding()
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
                                    .animation(.easeInOut(duration: 0.5), value: cardRotation)
                                    .animation(.easeInOut(duration: 0.5), value: cardScale)
                                    .animation(.easeInOut(duration: 0.5), value: cardOpacity)
                                    
                                } else {
                                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 1), count: columns), spacing: 1) {
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
                                            .frame(width: 40, height: 40)
                                        }
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.bottom, 200) // Add extra padding at the bottom
                                }
                            }
                        }
                        .padding(45)
                        .background(Color(red: 14 / 255, green: 17 / 255, blue: 22 / 255))
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
        
        // Find any workout that falls within this day
        let workout = workouts.first { workout in
            guard let workoutDate = workout.date else { return false }
            return workoutDate >= dayStart && workoutDate < dayEnd
        }
        
        return shouldShowWorkout(workout) ? workout : nil
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
        VStack(alignment: .leading, spacing: 10) {
            Text(localWorkout.detailedWorkout?.name ?? "Unnamed Workout")
                .font(.title)
                .padding(.bottom)
            
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
    }
    .padding()
    .foregroundColor(.white)
    .background(
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.green.opacity(0.2))
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
    )
    .onAppear {
        print("WorkoutDetailView appeared for workout ID: \(localWorkout.id)")
        print("Detailed workout: \(String(describing: localWorkout.detailedWorkout))")
    }
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
