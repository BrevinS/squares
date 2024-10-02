import Foundation

struct WorkoutDetails: Codable {
    let athlete_id: Int
    let workout_id: Int
    let distance: Double
    let average_heartrate: Double?
    let average_speed: Double
    let elapsed_time: Int
    let type: String
    let elevation_high: String
    let elevation_low: String
    let end_lnglat: String
    let has_heartrate: Bool?
    let map: Map
    let max_heartrate: Int?
    let max_speed: Double
    let moving_time: Int
    let name: String
    let sport_type: String
    let start_date: String
    let start_date_local: String
    let start_lnglat: String
    let time_zone: String
    let total_elevation_gain: Double

    struct Map: Codable {
        let summary_polyline: String
        let id: String
        let resource_state: Int
    }

    enum CodingKeys: String, CodingKey {
        case athlete_id, workout_id, distance, average_heartrate, average_speed, elapsed_time, type,
             elevation_high, elevation_low, end_lnglat, has_heartrate, map, max_heartrate, max_speed,
             moving_time, name, sport_type, start_date, start_date_local, start_lnglat, time_zone,
             total_elevation_gain
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        athlete_id = try container.decode(Int.self, forKey: .athlete_id)
        workout_id = try container.decode(Int.self, forKey: .workout_id)
        distance = try container.decode(Double.self, forKey: .distance)
        average_heartrate = try container.decodeIfPresent(Double.self, forKey: .average_heartrate)
        average_speed = try container.decode(Double.self, forKey: .average_speed)
        elapsed_time = try container.decode(Int.self, forKey: .elapsed_time)
        type = try container.decode(String.self, forKey: .type)
        elevation_high = try container.decode(String.self, forKey: .elevation_high)
        elevation_low = try container.decode(String.self, forKey: .elevation_low)
        end_lnglat = try container.decode(String.self, forKey: .end_lnglat)
        has_heartrate = (try? container.decodeIfPresent(Bool.self, forKey: .has_heartrate)) ?? (try? container.decodeIfPresent(Int.self, forKey: .has_heartrate) != nil)
        map = try container.decode(Map.self, forKey: .map)
        max_heartrate = try container.decodeIfPresent(Int.self, forKey: .max_heartrate)
        max_speed = try container.decode(Double.self, forKey: .max_speed)
        moving_time = try container.decode(Int.self, forKey: .moving_time)
        name = try container.decode(String.self, forKey: .name)
        sport_type = try container.decode(String.self, forKey: .sport_type)
        start_date = try container.decode(String.self, forKey: .start_date)
        start_date_local = try container.decode(String.self, forKey: .start_date_local)
        start_lnglat = try container.decode(String.self, forKey: .start_lnglat)
        time_zone = try container.decode(String.self, forKey: .time_zone)
        total_elevation_gain = try container.decode(Double.self, forKey: .total_elevation_gain)
    }
}
