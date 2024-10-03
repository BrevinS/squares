//
//  LocalWorkout+CoreDataProperties.swift
//  squares
//
//  Created by Brevin Simon on 10/2/24.
//
//

import Foundation
import CoreData


extension LocalWorkout {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LocalWorkout> {
        return NSFetchRequest<LocalWorkout>(entityName: "LocalWorkout")
    }

    @NSManaged public var date: Date?
    @NSManaged public var distance: Double
    @NSManaged public var id: Int64
    @NSManaged public var detailedWorkout: DetailedWorkout?

}

extension LocalWorkout : Identifiable {

}
