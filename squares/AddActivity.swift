import SwiftUI
import AuthenticationServices

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
                self.fetchWorkoutSummaries()
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
        self.fetchWorkoutSummaries()
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
    }
    
    func fetchWorkoutSummaries() {
            guard let athleteId = self.athleteId else {
                print("No athlete ID available")
                return
            }
            
            let urlString = "\(apiUrl)?athleteId=\(athleteId)"
            guard let url = URL(string: urlString) else {
                print("Invalid URL: \(urlString)")
                return
            }
            
            print("Fetching workouts from URL: \(urlString)")
            
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let error = error {
                    print("Error fetching workout summaries: \(error)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("Invalid response")
                    return
                }
                
                print("Response status code: \(httpResponse.statusCode)")
                
                guard let data = data else {
                    print("No data received")
                    return
                }
                
                print("Received data: \(String(data: data, encoding: .utf8) ?? "Unable to convert data to string")")
                
                do {
                    let decodedResponse = try JSONDecoder().decode(WorkoutsResponse.self, from: data)
                    DispatchQueue.main.async {
                        self.workoutSummaries = decodedResponse.workouts
                        print("Decoded \(self.workoutSummaries.count) workout summaries")
                    }
                } catch {
                    print("Error decoding workout summaries: \(error)")
                    if let decodingError = error as? DecodingError {
                        switch decodingError {
                        case .dataCorrupted(let context):
                            print("Data corrupted: \(context)")
                        case .keyNotFound(let key, let context):
                            print("Key '\(key)' not found: \(context)")
                        case .valueNotFound(let value, let context):
                            print("Value '\(value)' not found: \(context)")
                        case .typeMismatch(let type, let context):
                            print("Type '\(type)' mismatch: \(context)")
                        @unknown default:
                            print("Unknown decoding error")
                        }
                    }
                }
            }.resume()
        }
}

struct AddActivity: View {
    @EnvironmentObject var authManager: StravaAuthManager
    
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
                
                if authManager.workoutSummaries.isEmpty {
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

#Preview {
    AddActivity()
        .environmentObject(StravaAuthManager())
}
