//
//  Photo+CoreDataProperties.swift
//  Virtual Tourist
//
//  Created by Paul ReFalo on 12/22/16.
//  Copyright © 2016 QSS. All rights reserved.
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo");
    }

    @NSManaged public var urlString: String?
    @NSManaged public var imageIsLoaded: Bool
    @NSManaged public var title: String?
    @NSManaged public var imageData: NSData?
    @NSManaged public var height: Int64
    @NSManaged public var width: Int64
    @NSManaged public var pin: Pin?

}
