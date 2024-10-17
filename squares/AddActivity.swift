import SwiftUI
import AuthenticationServices
import CoreData

struct WorkoutSummary: Codable, Identifiable {
    let id: Int64
    let distance: Double
    let date: String

    enum CodingKeys: String, CodingKey {
        case id = "workout_id"
        case distance
        case date = "start_date_local"
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
    
    public func handleCallback(url: URL) {
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
        
        URLSession.shared.dataTask(with: url) { data, response, error in
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
                    let newWorkouts = self.updateWorkoutSummaries(decodedResponse.workouts)
                    print("Decoded \(decodedResponse.workouts.count) workout summaries, \(newWorkouts.count) new or updated")
                    self.saveWorkoutsLocally(newWorkouts)
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
        var newWorkoutsCount = 0
        var updatedWorkoutsCount = 0
        var unchangedWorkoutsCount = 0
        
        for workout in workouts {
            let fetchRequest: NSFetchRequest<LocalWorkout> = LocalWorkout.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %lld", workout.id)
            
            do {
                let results = try context.fetch(fetchRequest)
                if let existingWorkout = results.first {
                    // Workout already exists, check if it needs updating
                    if existingWorkout.distance != workout.distance || existingWorkout.date != ISO8601DateFormatter().date(from: workout.date) {
                        existingWorkout.distance = workout.distance
                        existingWorkout.date = ISO8601DateFormatter().date(from: workout.date)
                        updatedWorkoutsCount += 1
                        print("Updated existing workout: ID \(workout.id)")
                    } else {
                        unchangedWorkoutsCount += 1
                        print("Workout found on device, no update needed: ID \(workout.id)")
                    }
                } else {
                    // Create new workout
                    let localWorkout = LocalWorkout(context: context)
                    localWorkout.id = workout.id
                    localWorkout.distance = workout.distance
                    localWorkout.date = ISO8601DateFormatter().date(from: workout.date)
                    newWorkoutsCount += 1
                    print("Created new workout: ID \(workout.id)")
                }
            } catch {
                print("Error processing workout ID \(workout.id): \(error)")
            }
        }
        
        do {
            if context.hasChanges {
                try context.save()
                print("Core Data context saved successfully")
            } else {
                print("No changes to save in Core Data context")
            }
            print("Summary: \(newWorkoutsCount) new, \(updatedWorkoutsCount) updated, \(unchangedWorkoutsCount) unchanged")
        } catch {
            print("Failed to save workouts locally: \(error)")
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

struct AddActivity: View {
    @EnvironmentObject var authManager: StravaAuthManager
    @State private var isRefreshing = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add Activity")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            if authManager.isAuthenticated {
                Text("Authentication successful!")
                    .foregroundColor(.green)
                Text("Athlete ID: \(authManager.athleteId ?? 0)")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                
                Button(action: {
                    refreshWorkouts()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh Workouts")
                    }
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(isRefreshing)
                
                if isRefreshing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                        .scaleEffect(1.5)
                } else if authManager.workoutSummaries.isEmpty {
                    Text("No workouts found")
                        .foregroundColor(.gray)
                } else {
                    List(authManager.workoutSummaries) { summary in
                        VStack(alignment: .leading) {
                            Text("Date: \(formatDate(summary.date))")
                            Text("Distance: \(formatDistance(summary.distance)) mi")
                        }
                    }
                }
                
                Button("Logout") {
                    authManager.logout()
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
            } else {
                Button("Connect with Strava") {
                    authManager.authenticate()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 14 / 255, green: 17 / 255, blue: 22 / 255))
    }
    
    private func refreshWorkouts() {
        isRefreshing = true
        authManager.fetchWorkoutSummaries { success in
            isRefreshing = false
            if !success {
                // Handle error, maybe show an alert
            }
        }
    }
    
    func formatDate(_ dateString: String) -> String {
        let inputFormatter = ISO8601DateFormatter()
        inputFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = inputFormatter.date(from: dateString) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "MMM d, yyyy HH:mm"
            return outputFormatter.string(from: date)
        }
        return dateString
    }
    
    func formatDistance(_ distance: Double) -> String {
        return String(format: "%.2f", distance / 1609.344) // Convert meters to miles
    }
}

struct AddActivity_Previews: PreviewProvider {
    static var previews: some View {
        AddActivity()
            .environmentObject(StravaAuthManager())
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
