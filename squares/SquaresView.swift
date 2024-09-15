import SwiftUI

struct SquaresView: View {
    // Constants for the grid
    let rows = 52
    let columns = 7
    let totalItems = 364
    let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"] // Days of the week letters

    // State for block positions and selected date
    @State private var blocksDropped = false
    @State private var selectedDate: Date? = nil
    @State private var showAlert = false

    var body: some View {
        let gridLayout = Array(repeating: GridItem(.flexible(), spacing: 1), count: columns)
        
        ScrollView {
            VStack {
                ZStack {
                    // Encapsulating rounded rectangle
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(red: 62/255, green: 62/255, blue: 70/255), lineWidth: 2)
                        .padding(-35)
                    
                    VStack(spacing: 0) {
                        // Days of the week header inside the rounded rectangle
                        HStack(spacing: 1) {
                            ForEach(0..<columns, id: \.self) { index in
                                Text(daysOfWeek[index])
                                    .font(.caption)
                                    .foregroundColor(Color(hue: 1.0, saturation: 0.002, brightness: 0.794)) // Light grey color
                                    .frame(width: 39, height: 20, alignment: .center) // Same width as squares
                                    .padding(.top, 5) // Adjust vertical position
                            }
                        }
                        .frame(height: 20) // Ensure all letters align with grid width
                        .padding(.bottom, 5) // Space between the letters and the squares

                        // The grid of green squares
                        LazyVGrid(columns: gridLayout, spacing: 1) {
                            ForEach((0..<totalItems).reversed(), id: \.self) { index in
                                GeometryReader { geo in
                                    let isVisible = geo.frame(in: .global).minY < UIScreen.main.bounds.height && geo.frame(in: .global).maxY > 0
                                    
                                    SquareView(
                                        date: calculateDate(for: index),
                                        isVisible: isVisible,
                                        blocksDropped: blocksDropped,
                                        index: index,
                                        totalItems: totalItems,
                                        onTap: {
                                            selectedDate = calculateDate(for: index)
                                            showAlert = true
                                        }
                                    )
                                }
                                .frame(width: 40, height: 40) // Same width and height as day labels
                            }
                        }
                        .padding(.horizontal, 10)
                    }
                }
                .padding(45) // Padding for the entire ZStack
                .background(Color(red: 14 / 255, green: 17 / 255, blue: 22 / 255))
            }
            .onAppear {
                blocksDropped = true
            }
        }
        .background(Color(red: 14 / 255, green: 17 / 255, blue: 22 / 255))
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Date: \(formattedDate(selectedDate))"),
                message: Text("This is the note for \(formattedDate(selectedDate))."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func calculateDate(for index: Int) -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        // Literal Sphaggeti
        return calendar.date(byAdding: .day, value: index + 2 - 365, to: today)!
    }
    
    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy"
        return formatter.string(from: date)
    }
}

struct SquaresView_Previews: PreviewProvider {
    static var previews: some View {
        SquaresView()
    }
}
