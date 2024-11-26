import Foundation

struct WorkoutDetails: Codable {
    let athlete_id: Int
    let workout_id: Int
    let distance: Double
    let average_heartrate: Double
    let average_speed: Double
    let elapsed_time: Int
    let type: String
    let elevation_high: String
    let elevation_low: String
    let max_heartrate: Int
    let max_speed: Double
    let moving_time: Int
    let name: String
    let sport_type: String
    let start_date: String
    let start_date_local: String    
    let time_zone: String
    let total_elevation_gain: Double
    let calories: Double
    
    // Add a new property to store the raw JSON string
    var rawJSON: String?

    init(placeholderData: Bool = false) {
        self.athlete_id = 0
        self.workout_id = 0
        self.distance = 0
        self.average_heartrate = 0
        self.average_speed = 0
        self.elapsed_time = 0
        self.type = ""
        self.elevation_high = ""
        self.elevation_low = ""
        self.max_heartrate = 0
        self.max_speed = 0
        self.moving_time = 0
        self.name = ""
        self.sport_type = ""
        self.start_date = ""
        self.start_date_local = ""
        self.time_zone = ""
        self.total_elevation_gain = 0
        self.calories = 0
        self.rawJSON = nil
    }
}
