//
//  Photo+CoreDataClass.swift
//  Virtual Tourist
//
//  Created by Paul ReFalo on 12/22/16.
//  Copyright © 2016 QSS. All rights reserved.
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData

//@objc(Photo)
public class Photo: NSManagedObject {
    
//  imageData: NSData,
    
    convenience init(urlString: String, title: String, pin: Pin, context: NSManagedObjectContext) {

        // An EntityDescription is an object that has access to all
        // the information you provided in the Entity part of the model
        // you need it to create an instance of this class.
        if let ent = NSEntityDescription.entity(forEntityName: "Photo", in: context) {
            self.init(entity: ent, insertInto: context)
            self.urlString = urlString
            self.title = title
            self.pin = pin
            self.height = 100
            self.width = 100
        } else {
            fatalError("Unable to find Entity name!")
        }
    }
    
}

// Managed properties are:
/*
 @NSManaged public var urlString: String?
 @NSManaged public var title: String?
 @NSManaged public var imageData: NSData?
 @NSManaged public var height: Int64
 @NSManaged public var width: Int64
 @NSManaged public var pin: Pin?
 */
