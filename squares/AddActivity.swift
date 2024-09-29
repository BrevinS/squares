import SwiftUI
import AuthenticationServices

class StravaAuthManager: ObservableObject {
    @Published var isAuthenticated = false
    private let clientId = "134458"
    private let redirectUri = "https://www.movemindmap.com"
    private let scope = "activity:read_all"
    private let lambdaUrl = "https://h65wfsvjy8.execute-api.us-west-2.amazonaws.com/prod/exchange_token"

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
              let scope = components.queryItems?.first(where: { $0.name == "scope" })?.value else {
            print("Invalid URL structure")
            return
        }
        
        exchangeToken(code: code, scope: scope)
    }
    
    private func exchangeToken(code: String, scope: String) {
        let exchangeUrl = "\(lambdaUrl)?code=\(code)&scope=\(scope)"
        guard let url = URL(string: exchangeUrl) else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                    return
                }
                
                // Assuming the Lambda function handles token exchange and data fetching
                self.isAuthenticated = true
                print("Authentication successful. Data processing initiated on the backend.")
            }
        }.resume()
    }
}

struct AddActivity: View {
    @EnvironmentObject var authManager: StravaAuthManager
    
    var body: some View {
        VStack {
            Text("Add Activity")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            if authManager.isAuthenticated {
                Text("Authentication successful!")
                    .foregroundColor(.green)
                Text("Your activities are being processed.")
                    .foregroundColor(.gray)
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
