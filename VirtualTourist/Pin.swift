//
//  Pin+CoreDataClass.swift
//  
//
//  Created by Mohammed Javeed Shaikh on 2017-08-18.
//
//

import Foundation
import CoreData

@objc(Pin)
public class Pin: NSManagedObject {

    // MARK: - Initializer
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    convenience init(latitude: Double, longitude: Double, totalPages: Int, currentPage: Int, context: NSManagedObjectContext) {
        if let ent = NSEntityDescription.entity(forEntityName: "Pin", in: context){
            self.init(entity:ent, insertInto: context)
            self.latitude = latitude
            self.longitude = longitude
            self.totalPages = totalPages
            self.currentPage = currentPage
        }
        else{
            fatalError("Unable to find Entity name!")
        }
    }
}
