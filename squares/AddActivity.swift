import SwiftUI
import AuthenticationServices

class StravaAuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var athleteId: String?
    private let clientId = "134458"
    private let redirectUri = "https://www.movemindmap.com"
    private let scope = "activity:read_all"
    
    init() {
        self.athleteId = UserDefaults.standard.string(forKey: "athleteId")
        self.isAuthenticated = self.athleteId != nil
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
              let athleteId = components.queryItems?.first(where: { $0.name == "athlete_id" })?.value else {
            print("Invalid URL structure or missing parameters")
            return
        }
        
        self.storeAthleteId(athleteId)
        self.isAuthenticated = true
        print("Authentication successful. Athlete ID: \(athleteId)")
    }
    
    private func storeAthleteId(_ athleteId: String) {
        UserDefaults.standard.set(athleteId, forKey: "athleteId")
        self.athleteId = athleteId
    }
    
    func logout() {
        UserDefaults.standard.removeObject(forKey: "athleteId")
        self.athleteId = nil
        self.isAuthenticated = false
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
                Text("Athlete ID: \(authManager.athleteId ?? "Not available")")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                Text("Your activities are being processed.")
                    .foregroundColor(.gray)
                
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
}

#Preview {
    AddActivity()
        .environmentObject(StravaAuthManager())
}
