import SwiftUI
import MapKit

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

class MapCoordinator: NSObject, MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            
            // Check if this is the outline polyline
            if let isOutline = polyline.title, isOutline == "outline" {
                renderer.strokeColor = .black
                renderer.lineWidth = 6  // Slightly wider for the outline
            } else {
                renderer.strokeColor = .orange
                renderer.lineWidth = 4  // Slightly thinner for the main line
            }
            
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "PinAnnotation"
        var view: MKMarkerAnnotationView
        
        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView {
            view = dequeuedView
        } else {
            view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        }
        
        if annotation.title == "Start" {
            view.markerTintColor = .green
        } else {
            view.markerTintColor = .red
        }
        
        return view
    }
}

struct RunMapCard: View {
    let workout: DetailedWorkout
    @State private var region: MKCoordinateRegion
    @State private var mapView: MKMapView?
    
    init(workout: DetailedWorkout) {
        self.workout = workout
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        ))
    }
    
    private var routeCoordinates: [CLLocationCoordinate2D] {
        guard let polylineString = workout.polyline else { return [] }
        return RoutePolyline.decode(polylineString)
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
    
    private var startCoordinate: CLLocationCoordinate2D {
        parseCoordinates(from: workout.start_lnglat)
    }
    
    private var endCoordinate: CLLocationCoordinate2D {
        parseCoordinates(from: workout.end_lnglat)
    }
    
    private func calculateRegion() {
        let coordinates = routeCoordinates
        
        if coordinates.isEmpty {
            // Fallback to start/end points if no route
            let start = startCoordinate
            let end = endCoordinate
            
            let minLat = min(start.latitude, end.latitude)
            let maxLat = max(start.latitude, end.latitude)
            let minLon = min(start.longitude, end.longitude)
            let maxLon = max(start.longitude, end.longitude)
            
            updateRegion(minLat: minLat, maxLat: maxLat, minLon: minLon, maxLon: maxLon)
            return
        }
        
        // Calculate bounds from all route coordinates
        let minLat = coordinates.map { $0.latitude }.min() ?? 0
        let maxLat = coordinates.map { $0.latitude }.max() ?? 0
        let minLon = coordinates.map { $0.longitude }.min() ?? 0
        let maxLon = coordinates.map { $0.longitude }.max() ?? 0
        
        updateRegion(minLat: minLat, maxLat: maxLat, minLon: minLon, maxLon: maxLon)
    }
    
    private func updateRegion(minLat: Double, maxLat: Double, minLon: Double, maxLon: Double) {
        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        
        // Add padding to the span
        let latDelta = (maxLat - minLat) * 1.5
        let lonDelta = (maxLon - minLon) * 1.5
        
        // Ensure minimum zoom level
        let minDelta = 0.005
        let finalLatDelta = max(latDelta, minDelta)
        let finalLonDelta = max(lonDelta, minDelta)
        
        withAnimation(.easeInOut(duration: 0.5)) {
            region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
                span: MKCoordinateSpan(latitudeDelta: finalLatDelta, longitudeDelta: finalLonDelta)
            )
        }
        
        mapView?.setRegion(region, animated: true)
    }
    
    var body: some View {
        MapView(region: $region, mapView: $mapView) { map in
            // Add route polyline if we have coordinates
            let coordinates = routeCoordinates
            if !coordinates.isEmpty {
                // Add the outline polyline first
                let outlinePolyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
                outlinePolyline.title = "outline"  // Mark this as the outline
                map.addOverlay(outlinePolyline)
                
                // Add the main orange polyline on top
                let mainPolyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
                map.addOverlay(mainPolyline)
                
                print("Added polyline with \(coordinates.count) coordinates")
            }
            
            // Add start marker
            let startAnnotation = MKPointAnnotation()
            startAnnotation.coordinate = startCoordinate
            startAnnotation.title = "Start"
            map.addAnnotation(startAnnotation)
            
            // Add end marker
            let endAnnotation = MKPointAnnotation()
            endAnnotation.coordinate = endCoordinate
            endAnnotation.title = "End"
            map.addAnnotation(endAnnotation)
        }
        .onAppear {
            calculateRegion()
        }
    }
}

struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var mapView: MKMapView?
    let configure: (MKMapView) -> Void
    
    func makeCoordinator() -> MapCoordinator {
        MapCoordinator()
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.region = region
        mapView = map
        configure(map)
        return map
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.region = region
    }
}
