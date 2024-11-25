//
//  HabitEntry+CoreDataProperties.swift
//  squares
//
//  Created by Brevin Simon on 11/24/24.
//
//

import Foundation
import CoreData

extension HabitEntry {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<HabitEntry> {
        return NSFetchRequest<HabitEntry>(entityName: "HabitEntry")
    }

    @NSManaged public var completed: Bool
    @NSManaged public var date: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var notes: String?
    @NSManaged public var habit: Habit?

}

extension HabitEntry : Identifiable {

}
