//
//  ChipTagView.swift
//  squares
//
//  Created by Brevin Simon on 10/21/24.
//

import SwiftUI

struct FilterChipView: View {
    let subject: Subject
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Circle()
                    .fill(subject.color)
                    .frame(width: 8, height: 8)
                Text(subject.name)
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? subject.color.opacity(0.2) : Color.gray.opacity(0.1))
            .foregroundColor(isSelected ? subject.color : .gray)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? subject.color : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

struct SubjectFilterBar: View {
    let subjects: [Subject]
    @Binding var selectedSubjects: Set<Subject>
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(subjects) { subject in
                    FilterChipView(
                        subject: subject,
                        isSelected: selectedSubjects.contains(subject)
                    ) {
                        toggleSubject(subject)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(red: 14/255, green: 17/255, blue: 22/255))
    }
    
    private func toggleSubject(_ subject: Subject) {
        if selectedSubjects.contains(subject) {
            selectedSubjects.remove(subject)
        } else {
            selectedSubjects.insert(subject)
        }
    }
}

