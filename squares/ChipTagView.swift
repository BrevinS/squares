//
//  ChipTagView.swift
//  squares
//
//  Created by Brevin Simon on 10/21/24.
//

import SwiftUI

enum WorkoutColors {
    static let colors: [String: Color] = [
        "Run": .blue,
        "Ride": .green
        // Add more workout types as needed
    ]
    
    static func getColor(for workoutType: String?) -> Color {
        guard let type = workoutType else { return .gray.opacity(0.3) }
        return colors[type] ?? .gray.opacity(0.3)
    }
}

struct SubjectFilterBar: View {
    @Binding var selectedTypes: Set<String>
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(WorkoutColors.colors.keys), id: \.self) { workoutType in
                    FilterChipView(
                        type: workoutType,
                        color: WorkoutColors.colors[workoutType] ?? .gray,
                        isSelected: selectedTypes.contains(workoutType)
                    ) {
                        toggleType(workoutType)
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

