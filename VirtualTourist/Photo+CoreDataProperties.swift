//
//  Photo+CoreDataProperties.swift
//  
//
//  Created by Mohammed Javeed Shaikh on 2017-08-18.
//
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo");
    }

    @NSManaged public var imageData: Data?
    @NSManaged public var title: String
    @NSManaged public var imageUrl: String
    @NSManaged public var pin: Pin?

}
