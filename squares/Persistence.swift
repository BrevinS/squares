import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for _ in 0..<10 {
            let newWorkout = LocalWorkout(context: viewContext)
            newWorkout.id = Int64.random(in: 1...1000)
            newWorkout.date = Date()
            newWorkout.distance = Double.random(in: 1000...15000)
            newWorkout.type = "Run"  // Add type to preview data
            
            let detailedWorkout = DetailedWorkout(context: viewContext)
            detailedWorkout.workout_id = newWorkout.id
            detailedWorkout.name = "Sample Workout"
            detailedWorkout.type = "Run"
            detailedWorkout.average_heartrate = Double.random(in: 120...180)
            detailedWorkout.average_speed = Double.random(in: 2...6)
            detailedWorkout.elapsed_time = Int64.random(in: 1800...7200)
            detailedWorkout.max_heartrate = Int64.random(in: 150...200)
            detailedWorkout.max_speed = Double.random(in: 3...8)
            detailedWorkout.moving_time = Int64.random(in: 1800...7200)
            detailedWorkout.sport_type = "Run"
            detailedWorkout.start_date = Date()
            detailedWorkout.start_date_local = Date()
            detailedWorkout.time_zone = "UTC"
            detailedWorkout.total_elevation_gain = Double.random(in: 0...500)
            
            newWorkout.detailedWorkout = detailedWorkout
        }
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "LocalWorkout")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
