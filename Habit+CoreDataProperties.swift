//
//  Habit+CoreDataProperties.swift
//  squares
//
//  Created by Brevin Simon on 11/24/24.
//
//

import Foundation
import CoreData
import squares

extension Habit {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Habit> {
        return NSFetchRequest<Habit>(entityName: "Habit")
    }

    @NSManaged public var colorHex: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var hasNotes: Bool
    @NSManaged public var id: UUID?
    @NSManaged public var isBinary: Bool
    @NSManaged public var isDefaultHabit: Bool
    @NSManaged public var name: String?
    @NSManaged public var entries: NSSet?

}

// MARK: Generated accessors for entries
extension Habit {

    @objc(addEntriesObject:)
    @NSManaged public func addToEntries(_ value: HabitEntry)

    @objc(removeEntriesObject:)
    @NSManaged public func removeFromEntries(_ value: HabitEntry)

    @objc(addEntries:)
    @NSManaged public func addToEntries(_ values: NSSet)

    @objc(removeEntries:)
    @NSManaged public func removeFromEntries(_ values: NSSet)

}

extension Habit : Identifiable {

}
