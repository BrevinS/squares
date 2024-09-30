import SwiftUI

struct DayActivityMapView: View {
    let columns = 7
    let expandedHeight = 15 // Number of rows in the expanded rectangle
    @Binding var isPresented: Bool
    let topRowYPosition: CGFloat

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(red: 14 / 255, green: 17 / 255, blue: 22 / 255).edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    expandedRectangle
                        .position(x: geometry.size.width / 2, y: topRowYPosition + (CGFloat(expandedHeight) * 41 - 1) / 2)
                    Spacer()
                }
            }
        }
        .transition(.opacity)
    }
    
    private var expandedRectangle: some View {
        Rectangle()
            .fill(Color.green)
            .frame(width: CGFloat(columns) * 41 - 1, height: CGFloat(expandedHeight) * 41 - 1)
    }
}

struct DayActivityMapView_Previews: PreviewProvider {
    static var previews: some View {
        DayActivityMapView(isPresented: .constant(true), topRowYPosition: 100)
    }
}
