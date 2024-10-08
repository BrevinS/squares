import SwiftUI
import Combine

class NoteGraphViewModel: ObservableObject {
    @Published var notes: [Note] = [
        Note(title: "SwiftUI", content: "A framework for building user interfaces"),
        Note(title: "AWS", content: "Cloud computing services"),
        Note(title: "Obsidian", content: "A powerful knowledge base"),
        Note(title: "GraphQL", content: "A query language for APIs"),
        Note(title: "React", content: "A JavaScript library for building user interfaces"),
        Note(title: "Node.js", content: "JavaScript runtime built on Chrome's V8 JavaScript engine")
    ]
    
    @Published var nodes: [NoteNode] = []
    @Published var scale: CGFloat = 1.0
    @Published var offset: CGSize = .zero
    private var timer: AnyCancellable?
    let canvasSize = CGSize(width: 2000, height: 1500) // Larger canvas
    let nodeRadius: CGFloat = 15 // Smaller node radius
    let personalSpace: CGFloat = 200 // Increased personal space
    let centerAttraction: CGFloat = 0.015 // Reduced center attraction
    let repulsionStrength: CGFloat = 3000 // Increased repulsion strength
    let damping: CGFloat = 0.8
    
    init() {
        // Initialize node positions randomly
        for note in notes {
            nodes.append(NoteNode(id: note.id, position: CGPoint(x: CGFloat.random(in: 100...1900), y: CGFloat.random(in: 100...1400))))
        }
        
        // Add some example connections
        notes[0].connections.append(notes[1].id)
        notes[1].connections.append(notes[2].id)
        notes[2].connections.append(notes[3].id)
        notes[3].connections.append(notes[4].id)
        notes[4].connections.append(notes[5].id)
        notes[5].connections.append(notes[0].id)
        
        startSimulation()
    }
    
    func startSimulation() {
        timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateNodes()
            }
    }
    
    func updateNodes() {
        let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
        var totalMovement: CGFloat = 0
        
        for i in 0..<nodes.count {
            var force = CGPoint.zero
            
            // Center gravity
            let directionToCenter = CGPoint(x: center.x - nodes[i].position.x, y: center.y - nodes[i].position.y)
            let distanceToCenter = sqrt(directionToCenter.x * directionToCenter.x + directionToCenter.y * directionToCenter.y)
            force.x += directionToCenter.x * centerAttraction
            force.y += directionToCenter.y * centerAttraction
            
            // Repulsion from other nodes
            for j in 0..<nodes.count where i != j {
                let dx = nodes[i].position.x - nodes[j].position.x
                let dy = nodes[i].position.y - nodes[j].position.y
                let distanceSquared = dx * dx + dy * dy
                if distanceSquared < personalSpace * personalSpace {
                    let distance = sqrt(distanceSquared)
                    let repulsion = repulsionStrength / (distance * distance)
                    force.x += dx / distance * repulsion
                    force.y += dy / distance * repulsion
                }
            }
            
            // Update velocity
            nodes[i].velocity.x = (nodes[i].velocity.x + force.x) * damping
            nodes[i].velocity.y = (nodes[i].velocity.y + force.y) * damping
            
            // Update position
            nodes[i].position.x += nodes[i].velocity.x
            nodes[i].position.y += nodes[i].velocity.y
            
            // Constrain to canvas
            nodes[i].position.x = max(nodeRadius, min(canvasSize.width - nodeRadius, nodes[i].position.x))
            nodes[i].position.y = max(nodeRadius, min(canvasSize.height - nodeRadius, nodes[i].position.y))
            
            // Calculate total movement
            totalMovement += abs(nodes[i].velocity.x) + abs(nodes[i].velocity.y)
        }
        
        // Stop simulation if movement is very small
        if totalMovement < 0.1 {
            timer?.cancel()
        }
    }
}
