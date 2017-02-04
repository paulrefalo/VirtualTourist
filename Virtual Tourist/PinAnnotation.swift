//
//  PinAnnotation.swift
//  Virtual Tourist
//
//  Created by Paul ReFalo on 12/23/16.
//  Copyright © 2016 QSS. All rights reserved.
//

import MapKit
import CoreData
import UIKit
import Foundation

class PinAnnotation: NSObject, MKAnnotation {
    
    let title: String?
    let subtitle: String?
    var coordinate: CLLocationCoordinate2D
    
    init(objectID: NSManagedObjectID, title: String?, subtitle: String?, coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
        super.init()
    }
}
