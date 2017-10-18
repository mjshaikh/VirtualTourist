//
//  Photo+CoreDataClass.swift
//  
//
//  Created by Mohammed Javeed Shaikh on 2017-08-18.
//
//

import Foundation
import CoreData

@objc(Photo)
public class Photo: NSManagedObject {

    // MARK: - Initializer
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    convenience init(title: String, imageUrl: String, pin: Pin, context: NSManagedObjectContext) {
        if let ent = NSEntityDescription.entity(forEntityName: "Photo", in: context){
            self.init(entity:ent, insertInto: context)
            self.title = title
            self.imageUrl = imageUrl
            self.pin = pin
        }
        else{
            fatalError("Unable to find Entity name!")
        }
    }
}
