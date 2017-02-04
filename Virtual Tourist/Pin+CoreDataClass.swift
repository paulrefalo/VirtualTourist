//
//  Pin+CoreDataClass.swift
//  Virtual Tourist
//
//  Created by Paul ReFalo on 12/22/16.
//  Copyright © 2016 QSS. All rights reserved.
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData

public class Pin: NSManagedObject {
    
    convenience init(latitude: Double, longitude: Double, context: NSManagedObjectContext) {
        if let entity = NSEntityDescription.entity(forEntityName: "Pin", in: context) {
            self.init(entity: entity, insertInto: context)
            self.latitude = latitude
            self.longitude = longitude
        } else {
            fatalError("Unable to find Entity name!")
        }
    }
    
    
    func deletePhotosFromPin(context: NSManagedObjectContext) {
        if let photos = photos {
            for photo in photos {
                context.delete(photo as! NSManagedObject)
            }
        }
    }
}
