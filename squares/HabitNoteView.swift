import SwiftUI

struct HabitNoteView: View {
    let habitEntry: HabitEntry
    let onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.title)
                }
            }
            .padding()
            
            Text(habitEntry.habit?.name ?? "Note")
                .font(.title)
                .foregroundColor(.white)
            
            Text(formatDate(habitEntry.date ?? Date()))
                .font(.subheadline)
                .foregroundColor(.gray)
            
            ScrollView {
                Text(habitEntry.notes ?? "No notes available")
                    .foregroundColor(.white)
                    .padding()
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 14/255, green: 17/255, blue: 22/255))
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy h:mm a"
        return formatter.string(from: date)
    }
}
