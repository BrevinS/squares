import SwiftUI

struct BodyMetricsView: View {
    var body: some View {
        VStack {
            Text("Body Metrics")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            // Add your React component here using a WebView or similar approach
            // This would depend on how you're integrating React components in your app
            TemperatureModuleView()
                .frame(width: 350)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 14/255, green: 17/255, blue: 22/255))
    }
}

struct BodyMetricsView_Previews: PreviewProvider {
    static var previews: some View {
        BodyMetricsView()
    }
}
