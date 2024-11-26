import SwiftUI
import MapKit
import CoreLocation

// Polyline decoder utility
struct RoutePolyline {
    static func decode(_ encodedPath: String) -> [CLLocationCoordinate2D] {
        var coordinates: [CLLocationCoordinate2D] = []
        var index = 0
        let len = encodedPath.count
        var lat = 0.0
        var lng = 0.0
        
        while index < len {
            var shift = 0
            var result = 0
            var byte: Int
            
            repeat {
                byte = Int(encodedPath[encodedPath.index(encodedPath.startIndex, offsetBy: index)].asciiValue!) - 63
                result |= (byte & 0x1F) << shift
                shift += 5
                index += 1
            } while byte >= 0x20
            
            let deltaLat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1))
            lat += Double(deltaLat)
            
            shift = 0
            result = 0
            
            repeat {
                byte = Int(encodedPath[encodedPath.index(encodedPath.startIndex, offsetBy: index)].asciiValue!) - 63
                result |= (byte & 0x1F) << shift
                shift += 5
                index += 1
            } while byte >= 0x20
            
            let deltaLon = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1))
            lng += Double(deltaLon)
            
            coordinates.append(CLLocationCoordinate2D(
                latitude: lat * 1e-5,
                longitude: lng * 1e-5
            ))
        }
        
        return coordinates
    }
}

struct RunMapCard: View {
    let workout: DetailedWorkout
    @State private var region: MKCoordinateRegion
    
    // Extract polyline from map string
    private var polyline: String? {
        guard let mapString = workout.polyline,
              let data = mapString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let summaryPolyline = json["summary_polyline"] as? [String: String],
              let polylineString = summaryPolyline["S"] else {
            print("ℹ️ No valid map data available")
            return nil
        }
        print("✅ Successfully extracted polyline: \(polylineString.prefix(50))...")
        return polylineString
    }
    
    init(workout: DetailedWorkout) {
        self.workout = workout
        
        // Initialize with a default region that will be updated in onAppear
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        ))
    }
    
    private func parseCoordinates(from jsonString: String?) -> CLLocationCoordinate2D {
        guard let jsonString = jsonString,
              let jsonData = jsonString.data(using: .utf8),
              let coordinates = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]],
              coordinates.count >= 2,
              let lat = coordinates[0]["N"] as? String,
              let lng = coordinates[1]["N"] as? String,
              let latDouble = Double(lat),
              let lngDouble = Double(lng) else {
            return CLLocationCoordinate2D()
        }
        return CLLocationCoordinate2D(latitude: latDouble, longitude: lngDouble)
    }
    
    var startCoordinate: CLLocationCoordinate2D {
        return parseCoordinates(from: workout.start_lnglat)
    }
    
    var endCoordinate: CLLocationCoordinate2D {
        return parseCoordinates(from: workout.end_lnglat)
    }
    
    private func calculateRegion() {
        let start = startCoordinate
        let end = endCoordinate
        
        // Only update region if we have valid coordinates
        guard start.latitude != 0, start.longitude != 0,
              end.latitude != 0, end.longitude != 0 else {
            return
        }
        
        // Calculate the bounding box
        let minLat = min(start.latitude, end.latitude)
        let maxLat = max(start.latitude, end.latitude)
        let minLon = min(start.longitude, end.longitude)
        let maxLon = max(start.longitude, end.longitude)
        
        // Calculate center
        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        
        // Calculate span with padding
        let latDelta = (maxLat - minLat) * 1.5 // 50% padding
        let lonDelta = (maxLon - minLon) * 1.5 // 50% padding
        
        // Ensure minimum zoom level
        let minDelta = 0.005 // Minimum span to prevent over-zooming
        let finalLatDelta = max(latDelta, minDelta)
        let finalLonDelta = max(lonDelta, minDelta)
        
        // Update region with animation
        withAnimation(.easeInOut(duration: 0.5)) {
            region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
                span: MKCoordinateSpan(
                    latitudeDelta: finalLatDelta,
                    longitudeDelta: finalLonDelta
                )
            )
        }
    }
    
    var body: some View {
        Map(coordinateRegion: $region, showsUserLocation: false, annotationItems: [
            MapPin(coordinate: startCoordinate, title: "Start", color: .green),
            MapPin(coordinate: endCoordinate, title: "End", color: .red)
        ]) { pin in
            MapAnnotation(coordinate: pin.coordinate) {
                Circle()
                    .fill(pin.color)
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle()
                            .stroke(.white, lineWidth: 2)
                    )
            }
        }
        .overlay(alignment: .center) {
            if let polylineString = polyline {
                MapPolylineOverlay(coordinates: RoutePolyline.decode(polylineString))
            }
        }
        .onAppear {
            // Set initial region when view appears
            calculateRegion()
        }
    }
}

struct MapPin: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let title: String
    let color: Color
}

struct MapPolylineOverlay: UIViewRepresentable {
    let coordinates: [CLLocationCoordinate2D]
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.isUserInteractionEnabled = false
        mapView.delegate = context.coordinator
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.removeOverlays(uiView.overlays)
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        uiView.addOverlay(polyline)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .orange
                renderer.lineWidth = 4
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}
