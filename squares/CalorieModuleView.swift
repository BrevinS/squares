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
    
    func deleteEntry(_ entry: CalorieEntry) {
        calorieEntries.removeAll { $0.id == entry.id }
    }
    
    var totalCaloriesConsumed: Int {
        calorieEntries.reduce(0) { $0 + $1.calories }
    }
}

struct AnimatedScaleView: View {
    let consumedCalories: Int
    let targetCalories: Int
    
    private var scaleAngle: Double {
        let difference = Double(consumedCalories - targetCalories)
        // Invert the angle so higher weight tilts down
        // Limit the tilt to ±15 degrees for a subtle effect
        return min(max(-15, -difference / 200), 15)  // Note the negative difference
    }
    
    var body: some View {
        VStack {
            ZStack {
                // Base stand
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 8)
                    .offset(y: 50)
                
                // Center pole
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 4, height: 60)
                    .offset(y: 20)
                
                // Scale beam
                ZStack {
                    // Main beam
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.orange)
                        .frame(width: 200, height: 4)
                    
                    // Left plate (Consumed)
                    ZStack {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 50, height: 50)
                        Text("\(consumedCalories)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .offset(x: -90)
                    
                    // Right plate (Target)
                    ZStack {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 50, height: 50)
                        Text("\(targetCalories)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .offset(x: 90)
                }
                .rotationEffect(.degrees(scaleAngle))
                .animation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0.6), value: scaleAngle)
            }
            .frame(height: 120)
            .frame(maxWidth: .infinity)
        }
    }
}

struct CalorieEntryRow: View {
    let entry: CalorieEntry
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Text(entry.name)
                .foregroundColor(.white)
            Spacer()
            Text("\(entry.calories) cal")
                .foregroundColor(.orange)
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red.opacity(0.7))
                    .font(.system(size: 20))
            }
            .buttonStyle(PlainButtonStyle())
            .transition(.opacity)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}

struct MetabolismSettingsView: View {
    @Binding var baseMetabolism: Int
    @Environment(\.dismiss) private var dismiss
    @State private var tempMetabolism: String
    
    init(baseMetabolism: Binding<Int>) {
        self._baseMetabolism = baseMetabolism
        self._tempMetabolism = State(initialValue: String(baseMetabolism.wrappedValue))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Base Metabolism")) {
                    TextField("Daily Calorie Need", text: $tempMetabolism)
                        .keyboardType(.numberPad)
                    
                    Text("This is your basic metabolic rate - the number of calories your body needs daily to maintain current weight.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("Metabolism Settings")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    if let newValue = Int(tempMetabolism) {
                        baseMetabolism = newValue
                    }
                    dismiss()
                }
                .disabled(Int(tempMetabolism) == nil)
            )
        }
    }
}

struct CalorieModuleView: View {
    @StateObject private var calorieService: CalorieService
    @State private var newEntryName: String = ""
    @State private var newEntryCalories: String = ""
    @State private var isAddingEntry: Bool = false
    @State private var baseMetabolism: Int = 2000
    @State private var caloriesBurned: Int = 0
    @State private var isShowingSettings: Bool = false
    
    init() {
        _calorieService = StateObject(wrappedValue: CalorieService(context: PersistenceController.shared.container.viewContext))
    }
    
    private var targetCalories: Int {
        baseMetabolism + caloriesBurned
    }
    
    private var isCalorieSurplus: Bool {
        calorieService.totalCaloriesConsumed > targetCalories
    }
    
    private var statusView: some View {
        HStack {
            Image(systemName: isCalorieSurplus ? "plus.forwardslash.minus" : "minus.forwardslash.plus")
                .foregroundColor(isCalorieSurplus ? .red : .green)
                .font(.system(size: 20))
            
            Text(isCalorieSurplus ? "Surplus" : "Deficit")
                .foregroundColor(isCalorieSurplus ? .red : .green)
                .font(.system(size: 16, weight: .medium))
                
            Spacer()
            
            Text("\(abs(calorieService.totalCaloriesConsumed - targetCalories)) cal")
                .foregroundColor(isCalorieSurplus ? .red : .green)
                .font(.system(size: 16, weight: .medium))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Calorie Tracking")
                    .font(.headline)
                    .foregroundColor(.orange)
                
                Spacer()
                
                // Settings button
                Button(action: {
                    isShowingSettings = true
                }) {
                    Image(systemName: "gear")
                        .font(.system(size: 20))
                        .foregroundColor(.orange)
                }
                
                Button(action: {
                    isAddingEntry = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.orange)
                }
            }
            
            VStack {
                AnimatedScaleView(
                    consumedCalories: calorieService.totalCaloriesConsumed,
                    targetCalories: targetCalories
                )
            }
            .frame(maxWidth: .infinity)
            
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
                    HStack(spacing: 4) {
                        Text("\(targetCalories)")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        // Small metabolism indicator
                        Text("(\(baseMetabolism))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            statusView
                .animation(.easeInOut, value: isCalorieSurplus)
            
            HStack {
                Text("Today's Food Log")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                Spacer()
                
                if !calorieService.calorieEntries.isEmpty {
                    Text("\(calorieService.calorieEntries.count) items")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .padding(.top, 8)
            
            if calorieService.calorieEntries.isEmpty {
                Text("No meals logged today")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(calorieService.calorieEntries) { entry in
                            CalorieEntryRow(entry: entry) {
                                withAnimation {
                                    calorieService.deleteEntry(entry)
                                }
                            }
                        }
                    }
                }
                .frame(maxHeight: 200)
            }
        }
        .padding()
        .background(Color(red: 23/255, green: 27/255, blue: 33/255))
        .cornerRadius(12)
        .sheet(isPresented: $isAddingEntry) {
            NavigationView {
                Form {
                    Section(header: Text("New Entry")) {
                        TextField("Meal or Snack Name", text: $newEntryName)
                        TextField("Calories", text: $newEntryCalories)
                            .keyboardType(.numberPad)
                    }
                }
                .navigationTitle("Add Calorie Entry")
                .navigationBarItems(
                    leading: Button("Cancel") {
                        isAddingEntry = false
                    },
                    trailing: Button("Add") {
                        if let calories = Int(newEntryCalories) {
                            withAnimation {
                                calorieService.addEntry(newEntryName, calories: calories)
                            }
                            newEntryName = ""
                            newEntryCalories = ""
                            isAddingEntry = false
                        }
                    }
                    .disabled(newEntryName.isEmpty || newEntryCalories.isEmpty)
                )
            }
        }
        .sheet(isPresented: $isShowingSettings) {
            MetabolismSettingsView(baseMetabolism: $baseMetabolism)
        }
    }
}


