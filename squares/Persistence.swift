import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create sample habits first
        let habit = Habit(context: viewContext)
        habit.id = UUID()
        habit.name = "Running"
        habit.colorHex = "#0000FF"
        habit.isBinary = true
        habit.hasNotes = false
        habit.isDefaultHabit = true
        habit.createdAt = Date()
        
        // Create sample habit entry
        let entry = HabitEntry(context: viewContext)
        entry.id = UUID()
        entry.date = Date()
        entry.completed = true
        entry.habit = habit
        
        // Create sample workouts (existing code)
        for _ in 0..<10 {
            let newWorkout = LocalWorkout(context: viewContext)
            newWorkout.id = Int64.random(in: 1...1000)
            newWorkout.date = Date()
            newWorkout.distance = Double.random(in: 1000...15000)
            newWorkout.type = "Run"
            
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
            detailedWorkout.calories = Double.random(in: 1...6000)
            
            newWorkout.detailedWorkout = detailedWorkout
        }
        
        // Create sample weight measurements (existing code)
        let calendar = Calendar.current
        let today = Date()
        for day in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -day, to: today) {
                let weightMeasurement = WeightMeasurement(context: viewContext)
                weightMeasurement.id = UUID()
                weightMeasurement.date = date
                weightMeasurement.weight = Double.random(in: 150...160)
            }
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
        print("🔄 Initializing Core Data stack")
        container = NSPersistentContainer(name: "LocalWorkout")
        
        // Add this debug print
        print("📦 Model entities: ", container.managedObjectModel.entities.map {
            "name: \($0.name ?? "nil"), managedObjectClassName: \($0.managedObjectClassName)"
        })
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                print("❌ Failed to load persistent stores: \(error), \(error.userInfo)")
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            print("✅ Successfully loaded persistent store: \(storeDescription.description)")
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
