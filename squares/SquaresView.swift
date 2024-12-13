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
        entity: {
            let entityDescription = NSEntityDescription.entity(forEntityName: "Habit", in: PersistenceController.shared.container.viewContext)
            print("🎯 Habit entity description: \(String(describing: entityDescription))")
            return entityDescription!
        }(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Habit.createdAt, ascending: true)
        ],
        animation: .default
    ) private var habits: FetchedResults<Habit>

    // Replace the existing FetchRequest for workouts
    @FetchRequest(
        entity: LocalWorkout.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \LocalWorkout.date, ascending: true)
        ],
        animation: .default
    ) private var workouts: FetchedResults<LocalWorkout>
    
    private var hasHabits: Bool {
        let count = habits.count
        //print("👀 Checking hasHabits - count: \(count)")
        return !habits.isEmpty
    }
    
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
    @State private var selectedHabitName: String? = nil
    
    @State private var selectedHabitEntry: HabitEntry?
    @State private var showHabitNote = false

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
                        
                        if hasHabits {
                            SubjectFilterBar(
                                selectedTypes: $selectedTypes,
                                selectedHabitName: $selectedHabitName  // Add this binding
                            )
                            .padding(.bottom, 10)
                        }
                        
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
                                                    selectedHabitName: selectedHabitName,
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
                    //diagnoseHabitEntity()
                    print("📊 SquaresView appeared")
                    print("💾 Current context: \(viewContext)")
                    print("📝 Number of habits: \(habits.count)")
                    print("🏃‍♂️ Number of workouts: \(workouts.count)")
                    
                    // Log available entities
                    if let entities = viewContext.persistentStoreCoordinator?.managedObjectModel.entities {
                        print("📋 Available entities:", entities.map { $0.name ?? "unnamed" })
                    }
                    
                    // Test fetch request manually
                    let fetchRequest: NSFetchRequest<Habit> = Habit.fetchRequest()
                    do {
                        let count = try viewContext.count(for: fetchRequest)
                        print("🔢 Manual habit count: \(count)")
                    } catch {
                        print("❌ Error counting habits: \(error)")
                    }
                    
                    blocksDropped = true
                    alignDaysOfWeek()
                    printWorkouts()
                }
            }
            .background(Color(red: 14 / 255, green: 17 / 255, blue: 22 / 255))
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
            .sheet(isPresented: $showHabitNote) {
                if let entry = selectedHabitEntry {
                    HabitNoteView(habitEntry: entry) {
                        showHabitNote = false
                    }
                }
            }
        }
        
    }
    
    private func diagnoseHabitEntity() {
        print("🔍 Starting Habit entity diagnosis")
        
        // Check model configuration
        if let model = viewContext.persistentStoreCoordinator?.managedObjectModel {
            print("📝 Model entities: \(model.entities.map { $0.name ?? "unnamed" })")
            if let habitEntity = model.entities.first(where: { $0.name == "Habit" }) {
                print("✅ Found Habit entity:")
                print("   Name: \(habitEntity.name ?? "nil")")
                print("   Class: \(habitEntity.managedObjectClassName)")
                print("   Properties: \(habitEntity.properties.map { $0.name })")
            } else {
                print("❌ No Habit entity found in model")
            }
        }
        
        // Test creating a Habit
        let habit = Habit(context: viewContext)
        print("🆕 Created test habit: \(habit)")
    }
    
    private func hasHabitEntry(for date: Date) -> Bool {
        guard hasHabits else { return false }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let fetchRequest = HabitEntry.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "date >= %@ AND date < %@ AND complete = YES",
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
        
    private func getHabitColor(for date: Date) -> Color {
        guard hasHabits else {
            return Color(red: 23/255, green: 27/255, blue: 33/255)
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let fetchRequest = HabitEntry.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "date >= %@ AND date < %@ AND complete = YES",
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
    
    private var habitsRequest: FetchRequest<Habit> {
        guard let habitEntity = NSEntityDescription.entity(forEntityName: "Habit", in: viewContext) else {
            return FetchRequest<Habit>(
                entity: Habit.entity(),
                sortDescriptors: [],
                predicate: NSPredicate(value: false)  // Return empty result if entity doesn't exist
            )
        }
        
        return FetchRequest<Habit>(
            entity: habitEntity,
            sortDescriptors: [
                NSSortDescriptor(keyPath: \Habit.createdAt, ascending: true)
            ]
        )
    }

    private var workoutsRequest: FetchRequest<LocalWorkout> {
        guard let workoutEntity = NSEntityDescription.entity(forEntityName: "LocalWorkout", in: viewContext) else {
            return FetchRequest<LocalWorkout>(
                entity: LocalWorkout.entity(),
                sortDescriptors: [],
                predicate: NSPredicate(value: false)  // Return empty result if entity doesn't exist
            )
        }
        
        return FetchRequest<LocalWorkout>(
            entity: workoutEntity,
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
        
        return workouts.first { workout in
            guard let workoutDate = workout.date else { return false }
            return workoutDate >= dayStart && workoutDate < dayEnd
        }
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

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        // Handle workouts
        if let workout = workoutFor(date: date) {
            selectedLocalWorkout = workout
            if workout.detailedWorkout == nil {
                print("Fetching detailed workout for ID: \(workout.id)")
                fetchWorkoutDetails(for: workout.id)
            } else {
                print("Detailed workout already available for ID: \(workout.id)")
            }
            startRippleEffect(from: index)
            return
        }
        
        // Handle habits with notes
        let fetchRequest: NSFetchRequest<HabitEntry> = HabitEntry.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "date >= %@ AND date < %@ AND habit.name == %@ AND completed == YES",
            startOfDay as NSDate,
            endOfDay as NSDate,
            selectedHabitName ?? ""
        )
        
        do {
            let entries = try viewContext.fetch(fetchRequest)
            if let entry = entries.first {
                if entry.habit?.hasNotes == true {
                    selectedHabitEntry = entry
                    showHabitNote = true
                }
            }
        } catch {
            print("Error fetching habit entry: \(error)")
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
            if let data = data, let jsonString = String(data: data, encoding: .utf8) {
                print("📊 Raw workout details response: \(jsonString)")  // Add this debug line
            }
            
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
        print("💾 Saving workout details. ID: \(workoutId)")
            
        viewContext.perform {
            if let existingWorkout = self.workouts.first(where: { $0.id == workoutId }) {
                let detailedWorkout = existingWorkout.detailedWorkout ?? DetailedWorkout(context: viewContext)
                
                // Save map data as raw string
                if let mapString = details["polyline"] as? String {
                    print("📍 Storing map data as string \(mapString)")
                    detailedWorkout.polyline = mapString
                } else {
                    print("ℹ️ No map data available for this workout")
                }
                
                // Handle coordinate strings
                if let startCoords = details["start_lnglat"] as? [[String: Any]] {
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: startCoords)
                        if let jsonString = String(data: jsonData, encoding: .utf8) {
                            print("✅ Storing start coordinates: \(jsonString)")
                            detailedWorkout.start_lnglat = jsonString
                        }
                    } catch {
                        print("❌ Error converting start coordinates to JSON: \(error)")
                    }
                }
                
                if let endCoords = details["end_lnglat"] as? [[String: Any]] {
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: endCoords)
                        if let jsonString = String(data: jsonData, encoding: .utf8) {
                            print("✅ Storing end coordinates: \(jsonString)")
                            detailedWorkout.end_lnglat = jsonString
                        }
                    } catch {
                        print("❌ Error converting end coordinates to JSON: \(error)")
                    }
                }
                                
                detailedWorkout.polyline = (details["polyline"] as? String) ?? ""
                
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
                detailedWorkout.calories = (details["calories"] as? NSNumber)?.doubleValue ?? 0
                
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
        
        if let startCoords = details["start_lnglat"] as? [[String: Any]] {
            if let jsonData = try? JSONSerialization.data(withJSONObject: startCoords),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                print("✅ Storing start coordinates: \(jsonString)")
                detailedWorkout.start_lnglat = jsonString
            }
        }
        
        if let endCoords = details["end_lnglat"] as? [[String: Any]] {
            if let jsonData = try? JSONSerialization.data(withJSONObject: endCoords),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                print("✅ Storing end coordinates: \(jsonString)")
                detailedWorkout.end_lnglat = jsonString
            }
        }
        
        detailedWorkout.polyline = details["polyline"] as? String ?? ""
        
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
        detailedWorkout.calories = details["calories"] as? Double ?? 0
        
        print("Updated detailed workout: \(detailedWorkout)")
    }
}
    
struct WorkoutDetailView: View {
    let localWorkout: LocalWorkout
    @Environment(\.managedObjectContext) private var viewContext
    @State private var isFavorite: Bool
    
    init(localWorkout: LocalWorkout) {
        self.localWorkout = localWorkout
        self._isFavorite = State(initialValue: localWorkout.isFavorite)
    }
    
    private var timeRange: (start: String, end: String) {
        guard let startDate = localWorkout.detailedWorkout?.start_date_local,
              let duration = localWorkout.detailedWorkout?.elapsed_time else {
            return ("--:-- AM", "--:-- AM")
        }
        
        let endDate = startDate.addingTimeInterval(TimeInterval(duration))
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        
        return (formatter.string(from: startDate), formatter.string(from: endDate))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Workout Name
            HStack {
                Text(localWorkout.detailedWorkout?.name ?? "Unnamed Workout")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: toggleFavorite) {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .font(.system(size: 24))
                        .foregroundColor(isFavorite ? .yellow : .gray)
                }
            }
            .padding(.top, 8)
            
            // Map - only show if valid polyline data exists
            if let detailedWorkout = localWorkout.detailedWorkout,
               let polyline = detailedWorkout.polyline,
               !polyline.isEmpty {
                RunMapCard(workout: detailedWorkout)
                    .frame(height: 200)
                    .cornerRadius(12)
            }
            
            // Time Range
            HStack {
                Text(timeRange.start)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                Spacer()
                
                Image(systemName: "clock.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text(timeRange.end)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            // Rest of the view remains unchanged...
            // Distance
            VStack(alignment: .leading, spacing: 4) {
                Text(String(format: "%.2f", localWorkout.distance / 1609.344))
                    .font(.system(size: 42, weight: .bold))
                Text("MILES")
                    .font(.system(size: 16, weight: .medium))
                    .opacity(0.7)
            }
            .foregroundColor(.white)
            .padding(.vertical, 8)
            
            // Stats Rows with Middle Alignment
            HStack(alignment: .top) {
                // Left Column (margin left)
                VStack(alignment: .leading, spacing: 16) {
                    // Calories
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                            Text(String(format: "%.0f", localWorkout.detailedWorkout?.calories ?? 0))
                                .font(.system(size: 24, weight: .semibold))
                        }
                        Text("CALORIES")
                            .font(.system(size: 12, weight: .medium))
                            .opacity(0.7)
                    }
                    
                    // Duration
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.blue)
                            Text(formatDuration(Int(localWorkout.detailedWorkout?.elapsed_time ?? 0)))
                                .font(.system(size: 24, weight: .semibold))
                        }
                        Text("DURATION")
                            .font(.system(size: 12, weight: .medium))
                            .opacity(0.7)
                    }
                }
                
                Spacer()
                
                // Right Column (aligned vertically)
                VStack(alignment: .leading, spacing: 16) {
                    // Heart Rate
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "bolt.heart.fill")
                                .foregroundColor(.red)
                            if let avgHeartRate = localWorkout.detailedWorkout?.average_heartrate,
                               avgHeartRate > 0 {
                                Text(String(format: "%.0f", avgHeartRate))
                                    .font(.system(size: 24, weight: .semibold))
                            } else {
                                Text("--")
                                    .font(.system(size: 24, weight: .semibold))
                            }
                        }
                        Text("AVG BPM")
                            .font(.system(size: 12, weight: .medium))
                            .opacity(0.7)
                    }
                    
                    // Average Mile
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "hare.fill")
                                .foregroundColor(.purple)
                            Text(averageMileTime)
                                .font(.system(size: 24, weight: .semibold))
                        }
                        Text("AVG MILE")
                            .font(.system(size: 12, weight: .medium))
                            .opacity(0.7)
                    }
                }
            }
            .foregroundColor(.white)
            .padding(.vertical, 8)
            
            // Elevation Gain
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "mountain.2.fill")
                        .foregroundColor(.gray)
                    Text(String(format: "%.0f ft", (localWorkout.detailedWorkout?.total_elevation_gain ?? 0) * 3.28084))
                        .font(.system(size: 24, weight: .semibold))
                }
                Text("ELEVATION GAIN")
                    .font(.system(size: 12, weight: .medium))
                    .opacity(0.7)
            }
            .foregroundColor(.white)
            .padding(.vertical, 8)
            
            Spacer()
        }
        .padding()
        .frame(width: 286, height: 1065)
        .background(Color(red: 14/255, green: 17/255, blue: 22/255))
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(Color(red: 62/255, green: 62/255, blue: 70/255), lineWidth: 2)
        )
    }
    
    private func toggleFavorite() {
        localWorkout.isFavorite.toggle()
        isFavorite = localWorkout.isFavorite
        
        do {
            try viewContext.save()
        } catch {
            print("Error saving favorite status: \(error)")
        }
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = seconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, remainingSeconds)
        } else {
            return String(format: "%d:%02d", minutes, remainingSeconds)
        }
    }
    
    private var averageMileTime: String {
        guard let elapsedTime = localWorkout.detailedWorkout?.elapsed_time,
              localWorkout.distance > 0 else {
            return "--:--"
        }
        
        let milesRun = localWorkout.distance / 1609.344
        let secondsPerMile = Double(elapsedTime) / milesRun
        
        let minutes = Int(secondsPerMile / 60)
        let seconds = Int(secondsPerMile.truncatingRemainder(dividingBy: 60))
        
        return String(format: "%d:%02d", minutes, seconds)
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
    static var previews: some View {
        print("🎨 Initializing SquaresView preview")
        let context = PersistenceController.preview.container.viewContext
        print("🖼️ Preview context created: \(context)")
        
        return NavigationView {
            SquaresView()
                .environment(\.managedObjectContext, context)
                .environmentObject(StravaAuthManager())
        }
    }
}
