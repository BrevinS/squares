import SwiftUI
import AuthenticationServices
import CoreData

struct WorkoutSummary: Codable, Identifiable {
    let id: Int64
    let distance: Double
    let date: String
    let type: String  // Add type field

    enum CodingKeys: String, CodingKey {
        case id = "workout_id"
        case distance
        case date = "start_date_local"
        case type = "sport_type"  // Map to type field from API
    }
}

struct WorkoutsResponse: Codable {
    let workouts: [WorkoutSummary]
}

class StravaAuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var athleteId: Int64?
    @Published var workoutSummaries: [WorkoutSummary] = []
    private let clientId = "134458"
    private let redirectUri = "https://www.movemindmap.com"
    private let scope = "activity:read_all"
    private let apiUrl = "https://iloa3qamek.execute-api.us-west-2.amazonaws.com/prod/workouts"
    
    init() {
        if let storedAthleteId = UserDefaults.standard.object(forKey: "athleteId") as? Int64 {
            self.athleteId = storedAthleteId
            self.isAuthenticated = true
            self.loadCachedWorkoutSummaries()
        } else {
            self.athleteId = nil
            self.isAuthenticated = false
        }
    }

    func authenticate() {
        let stravaAppURL = URL(string: "strava://oauth/mobile/authorize?client_id=\(clientId)&redirect_uri=\(redirectUri)&response_type=code&approval_prompt=auto&scope=\(scope)")!
        
        if UIApplication.shared.canOpenURL(stravaAppURL) {
            UIApplication.shared.open(stravaAppURL, options: [:]) { success in
                if !success {
                    self.authenticateViaWeb()
                }
            }
        } else {
            authenticateViaWeb()
        }
    }
    
    private func authenticateViaWeb() {
        let stravaWebURL = URL(string: "https://www.strava.com/oauth/mobile/authorize")!
        var urlComponents = URLComponents(url: stravaWebURL, resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "approval_prompt", value: "auto"),
            URLQueryItem(name: "scope", value: scope)
        ]
        
        guard let authURL = urlComponents.url else { return }
        
        let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: "movemindmap") { callbackURL, error in
            guard error == nil, let successURL = callbackURL else {
                print("Error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            self.handleCallback(url: successURL)
        }
        
        session.presentationContextProvider = UIApplication.shared.windows.first?.rootViewController as? ASWebAuthenticationPresentationContextProviding
        session.start()
    }
    
    func handleCallback(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value,
              let athleteIdString = components.queryItems?.first(where: { $0.name == "athlete_id" })?.value,
              let athleteId = Int64(athleteIdString) else {
            print("Invalid URL structure or missing parameters")
            return
        }
        
        self.storeAthleteId(athleteId)
        self.isAuthenticated = true
        print("Authentication successful. Athlete ID: \(athleteId)")
        
        // Create Strava Running filter tag
        createStravaRunningFilter()
    }
    
    private func createStravaRunningFilter() {
        let context = PersistenceController.shared.container.viewContext
        
        // Check if Strava Running filter already exists
        let fetchRequest: NSFetchRequest<Habit> = Habit.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", "Running (Strava)")
        
        do {
            let existingHabits = try context.fetch(fetchRequest)
            if existingHabits.isEmpty {
                // Create new Strava Running filter
                let stravaFilter = Habit(context: context)
                stravaFilter.id = UUID()
                stravaFilter.name = "Running (Strava)"
                stravaFilter.colorHex = "#FC4C02" // Strava orange color
                stravaFilter.isBinary = false
                stravaFilter.hasNotes = false
                stravaFilter.isDefaultHabit = false
                stravaFilter.createdAt = Date()
                
                try context.save()
                print("Created Strava Running filter")
            }
        } catch {
            print("Error creating Strava Running filter: \(error)")
        }
    }
    
    private func storeAthleteId(_ athleteId: Int64) {
        UserDefaults.standard.set(athleteId, forKey: "athleteId")
        self.athleteId = athleteId
    }
    
    func logout() {
        UserDefaults.standard.removeObject(forKey: "athleteId")
        self.athleteId = nil
        self.isAuthenticated = false
        self.workoutSummaries = []
        // Clear local workout data
        clearLocalWorkouts()
    }
    
    private func cleanupOldWorkouts() {
        let context = PersistenceController.shared.container.viewContext
        let calendar = Calendar.current
        
        // Calculate the cutoff date (182 days ago)
        guard let cutoffDate = calendar.date(byAdding: .day, value: -182, to: Date()) else {
            print("Failed to calculate cutoff date")
            return
        }
        
        // Create fetch request for old workouts
        let fetchRequest: NSFetchRequest<LocalWorkout> = LocalWorkout.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date < %@ AND isFavorite == NO", cutoffDate as NSDate)
        
        do {
            let oldWorkouts = try context.fetch(fetchRequest)
            print("Found \(oldWorkouts.count) workouts older than 182 days to remove")
            
            // Remove old workouts
            for workout in oldWorkouts {
                if let date = workout.date {
                    print("Removing workout from \(date)")
                }
                context.delete(workout)
            }
            
            // Save context if there were any deletions
            if !oldWorkouts.isEmpty {
                try context.save()
                print("Successfully removed old workouts")
            }
        } catch {
            print("Error cleaning up old workouts: \(error)")
        }
    }
    
    func fetchWorkoutSummaries(completion: @escaping (Bool) -> Void) {
        guard let athleteId = self.athleteId else {
            print("No athlete ID available")
            completion(false)
            return
        }
        
        let urlString = "\(apiUrl)?athleteId=\(athleteId)"
        guard let url = URL(string: urlString) else {
            print("Invalid URL: \(urlString)")
            completion(false)
            return
        }
        
        print("Fetching workouts from URL: \(urlString)")
        
        // Clean up old workouts before fetching new ones
        cleanupOldWorkouts()
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                print("Error fetching workout summaries: \(error)")
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            guard let data = data else {
                print("No data received")
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode(WorkoutsResponse.self, from: data)
                DispatchQueue.main.async {
                    let newWorkouts = self?.updateWorkoutSummaries(decodedResponse.workouts)
                    print("Decoded \(decodedResponse.workouts.count) workout summaries, \(newWorkouts?.count ?? 0) new or updated")
                    self?.saveWorkoutsLocally(newWorkouts ?? [])
                    completion(true)
                }
            } catch {
                print("Error decoding workout summaries: \(error)")
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }.resume()
    }

    private func updateWorkoutSummaries(_ newSummaries: [WorkoutSummary]) -> [WorkoutSummary] {
        var updatedWorkouts: [WorkoutSummary] = []
        
        for newSummary in newSummaries {
            if let existingIndex = workoutSummaries.firstIndex(where: { $0.id == newSummary.id }) {
                if workoutSummaries[existingIndex].distance != newSummary.distance ||
                   workoutSummaries[existingIndex].date != newSummary.date {
                    workoutSummaries[existingIndex] = newSummary
                    updatedWorkouts.append(newSummary)
                }
            } else {
                workoutSummaries.append(newSummary)
                updatedWorkouts.append(newSummary)
            }
        }
        
        // Sort workoutSummaries by date (newest first)
        workoutSummaries.sort { $0.date > $1.date }
        
        // Cache the updated workoutSummaries
        cacheWorkoutSummaries()
        
        return updatedWorkouts
    }

    private func cacheWorkoutSummaries() {
        do {
            let data = try JSONEncoder().encode(workoutSummaries)
            UserDefaults.standard.set(data, forKey: "cachedWorkoutSummaries")
        } catch {
            print("Error caching workout summaries: \(error)")
        }
    }

    private func loadCachedWorkoutSummaries() {
        if let data = UserDefaults.standard.data(forKey: "cachedWorkoutSummaries") {
            do {
                let cachedSummaries = try JSONDecoder().decode([WorkoutSummary].self, from: data)
                self.workoutSummaries = cachedSummaries
                print("Loaded \(cachedSummaries.count) cached workout summaries")
            } catch {
                print("Error loading cached workout summaries: \(error)")
            }
        }
    }
    
    private func saveWorkoutsLocally(_ workouts: [WorkoutSummary]) {
        let context = PersistenceController.shared.container.viewContext
        
        // Fetch existing workouts to check for updates
        let fetchRequest: NSFetchRequest<LocalWorkout> = LocalWorkout.fetchRequest()
        
        do {
            let existingWorkouts = try context.fetch(fetchRequest)
            let existingIds = Set(existingWorkouts.map { $0.id })
            
            for workout in workouts {
                if existingIds.contains(workout.id) {
                    // Update existing workout
                    if let existingWorkout = existingWorkouts.first(where: { $0.id == workout.id }) {
                        existingWorkout.date = ISO8601DateFormatter().date(from: workout.date)
                        existingWorkout.distance = workout.distance
                        existingWorkout.type = workout.type
                    }
                } else {
                    // Create new workout
                    let newWorkout = LocalWorkout(context: context)
                    newWorkout.id = workout.id
                    newWorkout.date = ISO8601DateFormatter().date(from: workout.date)
                    newWorkout.distance = workout.distance
                    newWorkout.type = workout.type
                    // Add isFavorite property (defaults to false)
                    newWorkout.isFavorite = false
                }
            }
            
            try context.save()
            print("Successfully saved/updated workouts")
            
        } catch {
            print("Error saving workouts locally: \(error)")
        }
    }
    
    private func clearLocalWorkouts() {
        let context = PersistenceController.shared.container.viewContext
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = LocalWorkout.fetchRequest()
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(batchDeleteRequest)
            try context.save()
            print("Cleared all local workouts")
        } catch {
            print("Failed to clear local workouts: \(error)")
        }
    }
}

struct FavoriteWorkoutRow: View {
    let workout: LocalWorkout
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: { showingDetail = true }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.detailedWorkout?.name ?? "Unnamed Workout")
                        .foregroundColor(.white)
                    if let date = workout.date {
                        Text(formatDate(date))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                Text(String(format: "%.1f mi", workout.distance / 1609.344))
                    .foregroundColor(.orange)
            }
            .padding(.vertical, 8)
        }
        .sheet(isPresented: $showingDetail) {
            WorkoutDetailView(localWorkout: workout)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

struct AddActivity: View {
    @EnvironmentObject var authManager: StravaAuthManager
    @State private var isRefreshing = false
    @FetchRequest(
        entity: LocalWorkout.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \LocalWorkout.date, ascending: false)],
        predicate: NSPredicate(format: "isFavorite == YES")
    ) private var favoriteWorkouts: FetchedResults<LocalWorkout>
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Settings")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            List {
                Section("Account Connections") {
                    VStack(alignment: .leading, spacing: 12) {
                        // Strava Connection Status
                        HStack {
                            Text("Strava")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                            // Connection Status Indicator
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(authManager.isAuthenticated ? Color.green : Color.red)
                                    .frame(width: 8, height: 8)
                                Text(authManager.isAuthenticated ? "Connected" : "Disconnected")
                                    .font(.caption)
                                    .foregroundColor(authManager.isAuthenticated ? .green : .red)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(authManager.isAuthenticated ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                            )
                        }
                        
                        if authManager.isAuthenticated {
                            // Show connected status and controls
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Athlete ID: \(authManager.athleteId ?? 0)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                HStack(spacing: 12) {
                                    // Refresh Button
                                    Button(action: {
                                        refreshWorkouts()
                                    }) {
                                        HStack {
                                            Image(systemName: "arrow.clockwise")
                                                .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                                            Text("Refresh Data")
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.orange)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                    }
                                    .disabled(isRefreshing)
                                    
                                    // Logout Button
                                    Button(action: {
                                        authManager.logout()
                                    }) {
                                        Text("Disconnect")
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(Color.red.opacity(0.2))
                                            .foregroundColor(.red)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        } else {
                            // Show connect button
                            Button(action: {
                                authManager.authenticate()
                            }) {
                                Text("Connect with Strava")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.orange)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section(
                    header: Text("Favorite Workouts")
                        .foregroundColor(.white),
                    footer: Text("Favorite workouts are stored permanently on your device")
                        .foregroundColor(.gray)
                ) {
                    if favoriteWorkouts.isEmpty {
                        Text("No favorite workouts")
                            .foregroundColor(.gray)
                            .italic()
                    } else {
                        ForEach(favoriteWorkouts, id: \.id) { workout in
                            FavoriteWorkoutRow(workout: workout)
                        }
                    }
                }
                
                Section("App Preferences") {
                    Text("More settings coming soon")
                        .foregroundColor(.gray)
                }
            }
            .listStyle(InsetGroupedListStyle())
        }
        .background(Color(red: 14/255, green: 17/255, blue: 22/255))
    }
    
    private func refreshWorkouts() {
        isRefreshing = true
        authManager.fetchWorkoutSummaries { success in
            isRefreshing = false
        }
    }
}

struct ConnectionStatusView: View {
    let isConnected: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isConnected ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            Text(isConnected ? "Connected" : "Disconnected")
                .font(.caption)
                .foregroundColor(isConnected ? .green : .red)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isConnected ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
        )
    }
}

struct AddActivity_Previews: PreviewProvider {
    static var previews: some View {
        AddActivity()
            .environmentObject(StravaAuthManager())
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
