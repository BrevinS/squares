import SwiftUI

struct SettingsView: View {
    @Binding var nodeSize: CGFloat
    @Binding var connectionThickness: CGFloat
    @Binding var centerForce: CGFloat
    @Binding var repelForce: CGFloat
    @Binding var linkForce: CGFloat

    var body: some View {
        Form {
            Section(header: Text("Graph Appearance")) {
                SliderView(value: $nodeSize, range: 10...50, label: "Node Size")
                SliderView(value: $connectionThickness, range: 0.5...5, label: "Connection Thickness")
            }
            Section(header: Text("Physics Forces")) {
                SliderView(value: $centerForce, range: 0...0.1, label: "Center Force")
                SliderView(value: $repelForce, range: 1000...10000, label: "Repel Force")
                SliderView(value: $linkForce, range: 0...0.1, label: "Link Force")
            }
        }
        .navigationBarTitle("Settings", displayMode: .inline)
    }
}

struct SliderView: View {
    @Binding var value: CGFloat
    let range: ClosedRange<CGFloat>
    let label: String

    var body: some View {
        VStack {
            Text(label)
            Slider(value: $value, in: range)
            Text("\(value, specifier: "%.2f")")
        }
    }
}

