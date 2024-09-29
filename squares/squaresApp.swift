import SwiftUI

@main
struct squaresApp: App {
    @StateObject private var authManager = StravaAuthManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
        }
    }
    
    private func handleIncomingURL(_ url: URL) {
        guard url.scheme == "movemindmap" else { return }
        
        // Call the handleCallback method in StravaAuthManager
        authManager.handleCallback(url: url)
    }
}
