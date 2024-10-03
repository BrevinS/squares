//
//  DetailedWorkout+CoreDataProperties.swift
//  squares
//
//  Created by Brevin Simon on 10/2/24.
//
//

import Foundation
import CoreData


extension DetailedWorkout {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DetailedWorkout> {
        return NSFetchRequest<DetailedWorkout>(entityName: "DetailedWorkout")
    }

    @NSManaged public var average_heartrate: Double
    @NSManaged public var average_speed: Double
    @NSManaged public var elapsed_time: Int64
    @NSManaged public var type: String?
    @NSManaged public var elevation_high: String?
    @NSManaged public var elevation_low: String?
    @NSManaged public var max_heartrate: Int64
    @NSManaged public var max_speed: Double
    @NSManaged public var moving_time: Int64
    @NSManaged public var name: String?
    @NSManaged public var sport_type: String?
    @NSManaged public var start_date: Date?
    @NSManaged public var start_date_local: Date?
    @NSManaged public var time_zone: String?
    @NSManaged public var total_elevation_gain: Double
    @NSManaged public var localWorkout: LocalWorkout?

}

extension DetailedWorkout : Identifiable {

}
