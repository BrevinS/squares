import SwiftUI

struct BodyMetricsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Body Metrics")
                    .font(.largeTitle)
                    .foregroundColor(.orange)
                    .padding(.top)
                
                WeightModuleView()
                    .padding(.horizontal)
                
                TemperatureModuleView()
                    .padding(.horizontal)
                
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 14/255, green: 17/255, blue: 22/255))
    }
}

struct BodyMetricsView_Previews: PreviewProvider {
    static var previews: some View {
        BodyMetricsView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
