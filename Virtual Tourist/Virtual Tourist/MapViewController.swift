//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by Paul ReFalo on 12/21/16.
//  Copyright © 2016 QSS. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, UIGestureRecognizerDelegate, MKMapViewDelegate {
    
    var stack: CoreDataStack!
    let delegate = UIApplication.shared.delegate as! AppDelegate
    var editMode = Bool()

    
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var labelView: UIView!

    
    @IBAction func buttonTapped(_ sender: Any) {
        if editMode == true {
            // editMode is TRUE, toggle state and alter views
            editMode = false
            editButton.title = "Edit"
            navigationItem.rightBarButtonItem?.title = "Edit"
            labelView.isHidden = true
            self.mapView.frame = self.mapView.frame.offsetBy(dx: 0, dy: 60)
        } else {
            // Default or initial state:  editMode is FALSE, toggle state and alter views
            editMode = true
            navigationItem.rightBarButtonItem?.title = "Done"
            labelView.isHidden = false
            self.mapView.frame = self.mapView.frame.offsetBy(dx: 0, dy: -60)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(true, animated: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self
        labelView.isHidden = true
        editMode = false
        navigationItem.rightBarButtonItem?.title = "Edit"

        let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        lpgr.minimumPressDuration = 0.25
        lpgr.delaysTouchesBegan = true
        lpgr.delegate = self
        mapView.addGestureRecognizer(lpgr)
        
        stack = delegate.stack
        
        loadAnnotations()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    // Enable shake gesture to clear core data for development purposes
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            print("Shake")
            delegate.clearData()
            removeAnnotations()
        }
    }


    func handleLongPress(_ gestureReconizer: UILongPressGestureRecognizer) {
        if gestureReconizer.state == .ended {
            let point = gestureReconizer.location(in: self.mapView)
            let coordinateToAdd = mapView.convert(point, toCoordinateFrom: mapView)
            addPin(coordinate: coordinateToAdd)
        }
        
        stack.save()

    }
    
    func addPin(coordinate: CLLocationCoordinate2D) {
        let pin = Pin(latitude: coordinate.latitude, longitude: coordinate.longitude, context: stack.context)
        let pinAnnotation = PinAnnotation(objectID: pin.objectID, title: nil, subtitle: nil, coordinate: coordinate)
        mapView.addAnnotation(pinAnnotation)
    }
    
    func loadAnnotations() {
        print("loadAnnotations called")
        // create fetch request
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        do {
            if let pins = try? stack.context.fetch(fetchRequest) as! [Pin] {
                var pinAnnotations = [PinAnnotation]()
                // create annotations for pins
                for pin in pins {
                    let latitude = CLLocationDegrees(pin.latitude)
                    let longitude = CLLocationDegrees(pin.longitude)
                    let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    pinAnnotations.append(PinAnnotation(objectID: pin.objectID, title: nil, subtitle: nil, coordinate: coordinate))
                }
                // add annotations to the map
                mapView.addAnnotations(pinAnnotations)
            }
        }
    }
    
    func removeAnnotations() {
        print("removeAnnotations called")
        let allAnnotations = self.mapView.annotations
        self.mapView.removeAnnotations(allAnnotations)
        // load Annotations again to prove that DB was cleared out
        loadAnnotations()
    }
    
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        print("didSelectAnnotationView")
        // deselect pin
        mapView.deselectAnnotation(view.annotation, animated: false)
        
        let pinAnnotation = view.annotation as! PinAnnotation
        var pin: Pin!
        
        let defaults = UserDefaults.standard
        defaults.set(pinAnnotation.coordinate.latitude, forKey: "selectedLat")
        defaults.set(pinAnnotation.coordinate.longitude, forKey: "selectedLon")
        
        let latitude = pinAnnotation.coordinate.latitude
        let longitude = pinAnnotation.coordinate.longitude

        do {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
            let predicate = NSPredicate(format: "latitude == %@ AND longitude == %@", argumentArray: [latitude as Double, longitude as Double])
            fetchRequest.predicate = predicate
            var pins = try stack.context.fetch(fetchRequest) as? [Pin]
            pin = pins!.removeFirst()
            
        } catch let error as NSError {
            print("failed to pin by coordinate")
            print(error.localizedDescription)
            return
        }

        // if editing, delete the pin; otherwise segue to CollectionViewController
        guard !self.editMode else {
            mapView.removeAnnotation(view.annotation!)
            stack.context.delete(pin)
            stack.save()
            return
        }

        
        // segue to CollectionViewController
        performSegue(withIdentifier: "collectionSegue", sender: nil)
        
    }
    
}


