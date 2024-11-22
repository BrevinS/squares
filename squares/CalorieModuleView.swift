import SwiftUI
import CoreData

struct CalorieEntry: Identifiable {
    let id = UUID()
    let name: String
    let calories: Int
    let timestamp: Date
}

class CalorieService: ObservableObject {
    @Published var calorieEntries: [CalorieEntry] = []
    private let viewContext: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
    }
    
    func addEntry(_ name: String, calories: Int) {
        let newEntry = CalorieEntry(name: name, calories: calories, timestamp: Date())
        calorieEntries.append(newEntry)
    }
    
    var totalCaloriesConsumed: Int {
        calorieEntries.reduce(0) { $0 + $1.calories }
    }
}

struct CalorieScaleView: View {
    let consumedCalories: Int
    let targetCalories: Int
    
    private var scaleAngle: Double {
        let difference = Double(consumedCalories - targetCalories)
        // Limit the tilt to ±30 degrees
        return min(max(-30, difference / 100), 30)
    }
    
    var body: some View {
        VStack {
            // Scale beam
            ZStack {
                // Fulcrum
                Triangle()
                    .fill(Color.gray)
                    .frame(width: 20, height: 20)
                
                // Beam
                Rectangle()
                    .fill(Color.orange)
                    .frame(width: 200, height: 4)
                    .rotationEffect(.degrees(scaleAngle))
                
                // Left weight (consumed calories)
                Text("\(consumedCalories)")
                    .font(.caption)
                    .foregroundColor(.white)
                    .offset(x: -90, y: -sin(Double(scaleAngle) * .pi / 180) * 50)
                
                // Right weight (target calories)
                Text("\(targetCalories)")
                    .font(.caption)
                    .foregroundColor(.white)
                    .offset(x: 90, y: sin(Double(scaleAngle) * .pi / 180) * 50)
            }
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct CalorieModuleView: View {
    @StateObject private var calorieService: CalorieService
    @State private var newEntryName: String = ""
    @State private var newEntryCalories: String = ""
    @State private var isAddingEntry: Bool = false
    @State private var baseMetabolism: Int = 2000 // Default value
    @State private var caloriesBurned: Int = 0
    
    init() {
        _calorieService = StateObject(wrappedValue: CalorieService(context: PersistenceController.shared.container.viewContext))
    }
    
    private var targetCalories: Int {
        baseMetabolism + caloriesBurned
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Calorie Tracking")
                    .font(.headline)
                    .foregroundColor(.orange)
                
                Spacer()
                
                Button(action: {
                    isAddingEntry = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.orange)
                }
            }
            
            CalorieScaleView(
                consumedCalories: calorieService.totalCaloriesConsumed,
                targetCalories: targetCalories
            )
            .frame(height: 100)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Consumed")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(calorieService.totalCaloriesConsumed)")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Target")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(targetCalories)")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            
            if !calorieService.calorieEntries.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(calorieService.calorieEntries) { entry in
                            HStack {
                                Text(entry.name)
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(entry.calories) cal")
                                    .foregroundColor(.orange)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .frame(maxHeight: 150)
            }
        }
        .padding()
        .background(Color(red: 23/255, green: 27/255, blue: 33/255))
        .cornerRadius(12)
        .sheet(isPresented: $isAddingEntry) {
            NavigationView {
                Form {
                    TextField("Entry Name", text: $newEntryName)
                    TextField("Calories", text: $newEntryCalories)
                        .keyboardType(.numberPad)
                }
                .navigationTitle("Add Calorie Entry")
                .navigationBarItems(
                    leading: Button("Cancel") {
                        isAddingEntry = false
                    },
                    trailing: Button("Add") {
                        if let calories = Int(newEntryCalories) {
                            calorieService.addEntry(newEntryName, calories: calories)
                            newEntryName = ""
                            newEntryCalories = ""
                            isAddingEntry = false
                        }
                    }
                    .disabled(newEntryName.isEmpty || newEntryCalories.isEmpty)
                )
            }
        }
    }
}
