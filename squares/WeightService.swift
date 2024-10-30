import Foundation
import CoreData

class WeightService: ObservableObject {
    @Published var weightMeasurements: [WeightMeasurement] = []
    private let viewContext: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
        fetchWeightData()
    }
    
    func fetchWeightData() {
        let request = WeightMeasurement.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WeightMeasurement.date, ascending: true)]
        
        do {
            weightMeasurements = try viewContext.fetch(request)
        } catch {
            print("Error fetching weight data: \(error)")
            weightMeasurements = []
        }
    }
    
    func addWeight(_ weight: Double, date: Date = Date()) {
        let newMeasurement = WeightMeasurement(context: viewContext)
        newMeasurement.id = UUID()
        newMeasurement.weight = weight
        newMeasurement.date = date
        
        do {
            try viewContext.save()
            fetchWeightData()
        } catch {
            print("Error saving weight: \(error)")
        }
    }
    
    // Function to add historical data easily
    func addHistoricalData() {
        let calendar = Calendar.current
        let today = Date()
        
        // Example data - replace these weights with your actual weights
        let historicalWeights: [(days: Int, weight: Double)] = [
            (6, 153.8), // 6 days ago
            (5, 152.4), // 5 days ago
            (4, 153.4), // 4 days ago
            (3, 154.2), // 3 days ago
            (2, 153.2), // 2 days ago
            (1, 154.0), // yesterday
            (0, 153.6)  // today
        ]
        
        for (daysAgo, weight) in historicalWeights {
            if let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) {
                addWeight(weight, date: date)
            }
        }
    }
}
