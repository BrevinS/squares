import Foundation
import CoreData

@objc(LocalWorkout)
public class LocalWorkout: NSManagedObject {
    @NSManaged public var id: Int64
    @NSManaged public var date: Date?
    @NSManaged public var distance: Double
}

extension LocalWorkout {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<LocalWorkout> {
        return NSFetchRequest<LocalWorkout>(entityName: "LocalWorkout")
    }
}
