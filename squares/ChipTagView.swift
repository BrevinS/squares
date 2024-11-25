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
                            isSelected: selectedTypes.contains(name)
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
    }
    
    private func toggleType(_ type: String) {
        if selectedTypes.contains(type) {
            selectedTypes.remove(type)
        } else {
            selectedTypes.insert(type)
        }
    }
}

struct FilterChipView: View {
    let type: String
    let color: Color
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(type)
                    .font(.subheadline)
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

