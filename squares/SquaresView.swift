import SwiftUI

struct SquaresView: View {
    let rows = 52
        let columns = 7
        let totalItems = 364
        let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]
        let expandedHeight = 15 // Number of rows in the expanded rectangle

        @State private var blocksDropped = false
        @State private var selectedDate: Date? = nil
        @State private var showAlert = false
        @State private var expandedSquares: Set<Int> = []
        @State private var isExpanding = false
        @State private var isFullyExpanded = false
        @State private var expandedRectangleTopIndex: Int = 0
        @State private var shouldScrollToTop = false

        var body: some View {
            ScrollViewReader { scrollProxy in
                ScrollView {
                    VStack(spacing: 0) {
                        Color.clear.frame(height: 1).id("top")
                        VStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(red: 62/255, green: 62/255, blue: 70/255), lineWidth: 2)
                                    .padding(-35)
                                
                                VStack(spacing: 0) {
                                    HStack(spacing: 1) {
                                        if isFullyExpanded, let date = selectedDate {
                                            Text(formattedDateHeader(date))
                                                .font(.caption)
                                                .foregroundColor(Color(hue: 1.0, saturation: 0.002, brightness: 0.794))
                                                .frame(maxWidth: .infinity, alignment: .center)
                                        } else {
                                            ForEach(0..<columns, id: \.self) { index in
                                                Text(daysOfWeek[index])
                                                    .font(.caption)
                                                    .foregroundColor(Color(hue: 1.0, saturation: 0.002, brightness: 0.794))
                                                    .frame(width: 39, height: 20, alignment: .center)
                                            }
                                        }
                                    }
                                    .frame(height: 20)
                                    .padding(.bottom, 5)

                                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 1), count: columns), spacing: 1) {
                                        ForEach((0..<totalItems).reversed(), id: \.self) { index in
                                            if !isFullyExpanded || (index >= expandedRectangleTopIndex && index < expandedRectangleTopIndex + (expandedHeight * columns)) {
                                                GeometryReader { geo in
                                                    let isVisible = geo.frame(in: .global).minY < UIScreen.main.bounds.height && geo.frame(in: .global).maxY > 0
                                                    
                                                    SquareView(
                                                        date: calculateDate(for: index),
                                                        isVisible: isVisible,
                                                        blocksDropped: blocksDropped,
                                                        index: index,
                                                        totalItems: totalItems,
                                                        isExpanded: expandedSquares.contains(index) || isFullyExpanded,
                                                        onTap: {
                                                            selectedDate = calculateDate(for: index)
                                                            showAlert = true
                                                            startRippleEffect(from: index)
                                                        }
                                                    )
                                                }
                                                .frame(width: 40, height: 40)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 10)
                                }
                            }
                            .padding(45)
                            .background(Color(red: 14 / 255, green: 17 / 255, blue: 22 / 255))
                        }
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
                .onChange(of: shouldScrollToTop) { newValue in
                    if newValue {
                        withAnimation {
                            scrollProxy.scrollTo("top", anchor: .top)
                        }
                        shouldScrollToTop = false
                    }
                }
            }
        }
    
    private func calculateDate(for index: Int) -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return calendar.date(byAdding: .day, value: index + 2 - 365, to: today)!
    }
    
    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy"
        return formatter.string(from: date)
    }
    
    private func formattedDateHeader(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private func startRippleEffect(from index: Int) {
        guard !isExpanding else { return }
        isExpanding = true
        expandedSquares.removeAll()
        isFullyExpanded = false
        
        // Calculate the top index of the expanded rectangle
        let selectedRow = index / columns
        let topRow = max(0, min(rows - expandedHeight, selectedRow - expandedHeight / 2))
        expandedRectangleTopIndex = topRow * columns
        
        func expand(fromIndex: Int, currentLevel: Int) {
            guard currentLevel < 30 && expandedSquares.count < expandedHeight * columns else {
                completeExpansion()
                return
            }
            
            let adjacentIndices = getAdjacentIndices(for: fromIndex)
            let newIndices = adjacentIndices.filter {
                !expandedSquares.contains($0) &&
                $0 >= expandedRectangleTopIndex &&
                $0 < expandedRectangleTopIndex + (expandedHeight * columns)
            }
            expandedSquares.formUnion(newIndices)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
                for idx in newIndices {
                    expand(fromIndex: idx, currentLevel: currentLevel + 1)
                }
            }
        }
        
        expandedSquares.insert(index)
        expand(fromIndex: index, currentLevel: 0)
    }
    
    private func completeExpansion() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.isFullyExpanded = true
                }
                self.isExpanding = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.shouldScrollToTop = true
                }
            }
        }
    
    private func getAdjacentIndices(for index: Int) -> [Int] {
        let row = index / columns
        let col = index % columns
        var adjacent: [Int] = []
        
        for i in -1...1 {
            for j in -1...1 {
                let newRow = row + i
                let newCol = col + j
                if newRow >= 0 && newRow < rows && newCol >= 0 && newCol < columns {
                    adjacent.append(newRow * columns + newCol)
                }
            }
        }
        
        return adjacent
    }
}

struct SquaresView_Previews: PreviewProvider {
    static var previews: some View {
        SquaresView()
    }
}
