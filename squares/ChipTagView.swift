//
//  ChipTagView.swift
//  squares
//
//  Created by Brevin Simon on 10/21/24.
//

import SwiftUI

enum WorkoutColors {
    static let defaultColor: Color = .gray.opacity(0.3)
    
    static func getColor(for workoutType: String?) -> Color {
        guard let type = workoutType else { return defaultColor }
        return Color(hex: type) ?? defaultColor
    }
}

struct SubjectFilterBar: View {
    @Binding var selectedTypes: Set<String>
    @Binding var selectedHabitName: String?
    
    @FetchRequest(
        entity: Habit.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Habit.createdAt, ascending: true)]
    ) var habits: FetchedResults<Habit>
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(habits, id: \.id) { habit in
                    if let name = habit.name {
                        FilterChipView(
                            type: name,
                            color: Color(hex: habit.colorHex ?? "#808080") ?? .gray,
                            isSelected: selectedTypes.contains(name),
                            isDefault: habit.isDefaultHabit
                        ) {
                            toggleType(name)
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(red: 14/255, green: 17/255, blue: 22/255))
        .onAppear {
            if selectedTypes.isEmpty {
                selectDefaultHabit()
            }
        }
    }
    
    private func toggleType(_ type: String) {
        if selectedTypes.contains(type) {
            selectedTypes.removeAll()
            selectedHabitName = nil
            selectDefaultHabit()
        } else {
            selectedTypes = [type]
            selectedHabitName = type
        }
    }
    
    private func selectDefaultHabit() {
        if let defaultHabit = habits.first(where: { $0.isDefaultHabit }),
           let name = defaultHabit.name {
            selectedTypes = [name]
            selectedHabitName = name
        }
    }
}

struct FilterChipView: View {
    let type: String
    let color: Color
    let isSelected: Bool
    let isDefault: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(type)
                    .font(.subheadline)
                if isDefault {
                    Image(systemName: "star.fill")
                        .font(.system(size: 8))
                        .foregroundColor(color)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? color.opacity(0.2) : Color.gray.opacity(0.1))
            .foregroundColor(isSelected ? color : .gray)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? color : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

