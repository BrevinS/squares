import Foundation
import CoreData

extension WeightMeasurement {
    var wrappedId: UUID {
        id ?? UUID()
    }
    
    var wrappedWeight: Double {
        get { weight }
        set { weight = newValue }
    }
    
    var wrappedDate: Date {
        get { date ?? Date() }
        set { date = newValue }
    }
}
