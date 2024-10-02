import SwiftUI

struct DayView: View {
    let date: Date
    let distance: Double?
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

            Text(formattedDate(date))
                .font(.title)
                .foregroundColor(.white)

            if let distance = distance {
                Text(String(format: "Distance: %.2f miles", distance / 1609.344))
                    .font(.headline)
                    .foregroundColor(.white)
            } else {
                Text("No workout recorded for this date")
                    .font(.headline)
                    .foregroundColor(.white)
            }

            // Add more day activity details here
            // For example:
            // - Workout type
            // - Duration
            // - Calories burned
            // - Heart rate data
            // You can add these as they become available in your data model

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.green)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }
}
