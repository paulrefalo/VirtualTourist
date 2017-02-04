//
//  CollectionViewController.swift
//  Virtual Tourist
//
//  Created by Paul ReFalo on 12/31/16.
//  Copyright © 2016 QSS. All rights reserved.
//

import UIKit
import MapKit
import CoreData


class CollectionViewController: UIViewController {
    
    var pin: Pin!
    var photos = [Photo]()
    var stack: CoreDataStack!
    var selectedIndexes = [NSIndexPath]()
    var flickr = FlickrClient.sharedClient()
    private static var sharedInstance = FlickrClient()
    fileprivate let sectionInsets = UIEdgeInsets(top: 3.0, left: 3.0, bottom: 3.0, right: 3.0)
    
    var latitude: Double = 0.0
    var longitude: Double = 0.0


    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var bottomBarButton: UIBarButtonItem!
    @IBOutlet weak var userLabel: UILabel!
    

    override func viewDidLoad() {
        super.viewDidLoad()
  
        photoCollectionView.dataSource = self
        photoCollectionView.delegate = self
        
        self.userLabel.isHidden = true
        self.userLabel.text = "This pin has no images"

        navigationController?.setToolbarHidden(false, animated: false) // show bottom toolbar

        let delegate = UIApplication.shared.delegate as! AppDelegate
        stack = delegate.stack

        let defaults = UserDefaults.standard
        latitude = defaults.double(forKey: "selectedLat")
        longitude = defaults.double(forKey: "selectedLon")
        
        setUpMapAndPin()
 
        bottomBarButton.isEnabled = false
        
        if let photosAtPin = pin.photos?.allObjects as? [Photo] {
            print("******* FOUND PHOTOS for this pin:  \(photosAtPin.count)")

            if photosAtPin.count > 0 {
                photos = photosAtPin

                bottomBarButton.isEnabled = true
            } else {
                for _ in 1...Constants.Flickr.AlbumSize {
                    getNewCollection(numberOfPhotos: 1)
                    self.photoCollectionView.reloadData()
                }
                bottomBarButton.isEnabled = false
                toggleBottomBar()
            }
        }

    }
    
    
    @IBAction func collectionOrRemoveButton(_ sender: Any) {
        self.userLabel.isHidden = true
        
        DispatchQueue.main.async(execute: {

            if self.selectedIndexes.isEmpty {
                // delete photos from pin and get a new Collection
                self.photos.removeAll(keepingCapacity: false)
                self.pin.deletePhotosFromPin(context: self.stack.context)

                for _ in 1...Constants.Flickr.AlbumSize {
                    self.getNewCollection(numberOfPhotos: 1)
                    self.photoCollectionView.reloadData()
                }
            } else {
                // delete selected photos
                print("delete photos called")
                print("selectedIndexes.count in action is:  \(self.selectedIndexes.count)")
                if self.selectedIndexes.count > 0 {
                    self.deletePhotos()
                }
                // check for empty album
                if self.photos.count == 0 {
                    self.userLabel.text = "This album is currently empty"
                    self.userLabel.isHidden = false
                }
                DispatchQueue.main.async(execute: {
                    self.stack.save()
                })
            }
            self.photoCollectionView.reloadData() // need this one
            self.toggleBottomBar()
        })
        
    }
    
    func getNewCollection(numberOfPhotos: Int) {
        // numberOfPhotos is an optional argument that has a default of 1 on FlickerClient
        self.bottomBarButton.isEnabled = false
        self.userLabel.isHidden = true
        self.userLabel.text = ""
        
        flickr.searchByLatLon(lat: latitude, long: longitude, numberOfPhotos: numberOfPhotos) { (photoAlbumArray, error) in
            
            // if an error occurs, print it and re-enable the UI
            func displayError(_ error: String) {
                self.noPhotosCheckAndSetUp()
                print(error)
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                displayError("There was an error with your request: \(error)")
                return
            }
            
            DispatchQueue.main.async(execute: {

                var album = [[String:AnyObject]]()
                album = photoAlbumArray

                while !album.isEmpty {
                    let urlDictionary = album.removeFirst()
                    let imageTitle = urlDictionary["title"] as! String
                    let imageURLString = urlDictionary["imageURLString"] as! String
                    let thisPhoto = Photo(urlString: imageURLString, title: imageTitle, pin: self.pin, context: self.stack.context)
                    thisPhoto.pin = self.pin
                    thisPhoto.urlString = imageURLString
                    thisPhoto.imageIsLoaded = true
                    thisPhoto.title = imageTitle
                    thisPhoto.height = Int64(self.photoCollectionView.frame.width) / 3
                    thisPhoto.width = Int64(self.photoCollectionView.frame.width) / 3
                    self.photos.append(thisPhoto)
                }
                self.noPhotosCheckAndSetUp()
                self.stack.save()
                self.photoCollectionView.reloadData()
            })
            
        } // end call to Flicker client

    }
    
    private func noPhotosCheckAndSetUp() {
        DispatchQueue.main.async(execute: {

            print("noPhotos func called")
            if self.photos.count == 0 {
                self.bottomBarButton.isEnabled = false
                self.userLabel.text = "This pin has no images"
                self.userLabel.isHidden = false
            } else {
                self.bottomBarButton.isEnabled = true
                self.userLabel.isHidden = true
            }
            
        })
        self.photoCollectionView.reloadData() // necessary
    }
    
    private func setUpMapAndPin() {
        if let mapView = mapView {
            
            let mapCenter = CLLocationCoordinate2D(latitude: CLLocationDegrees(latitude), longitude: CLLocationDegrees(longitude))
            let mapSpan = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            let mapRegion = MKCoordinateRegionMake(mapCenter, mapSpan)
            mapView.setRegion(mapRegion, animated: true)
            mapView.isUserInteractionEnabled = false
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = mapCenter
            mapView.addAnnotation(annotation)
            do {
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
                let predicate = NSPredicate(format: "latitude == %@ AND longitude == %@", argumentArray: [latitude as Double, longitude as Double])
                fetchRequest.predicate = predicate
                var pins = try stack.context.fetch(fetchRequest) as? [Pin]
                pin = pins!.removeFirst()
                
            } catch let error as NSError {
                print("Failed to pin by coordinate")
                print(error.localizedDescription)
                return
            }
        }
    }
    
    func toggleBottomBar() {
        if selectedIndexes.count > 0 {
            bottomBarButton.title = "Remove Selected Pictures"
        } else {
            bottomBarButton.title = "New Collection"
        }
    }
    
    private func deletePhotos() {
        
        photoCollectionView.performBatchUpdates({

            let sortedIndexes = self.selectedIndexes.sorted(by: { $0.row > $1.row })

            for index in sortedIndexes {
                let thisPhoto = self.photos[index.row]
                self.photos.remove(at: index.row)

                self.photoCollectionView.deleteItems(at: [index as IndexPath])
                self.stack.context.delete(thisPhoto)
            }
        })
        
        // clear the array
        selectedIndexes = [NSIndexPath]()
        
    }
    
    func sortPhotos(_ photoArray: [Photo]) -> [Photo] {
        let sortedPhotos = photoArray.sorted(by: { $0.urlString! < $1.urlString! })
        
        let indexes = photoCollectionView.indexPathsForVisibleItems
        
        if indexes.count > 0 {
            for index in indexes {
                let cell = photoCollectionView!.cellForItem(at: index as IndexPath)
                cell?.contentView.alpha = 1.0
            }
        }
        
        return sortedPhotos
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil, completion: {
            _ in
            
            print("Device roated") // adjust photo image size upon roation and reload()
            
            if self.photos.count > 0 {
                for thisPhoto in self.photos {
                    thisPhoto.height = Int64(self.photoCollectionView.frame.width) / 3
                    thisPhoto.width = Int64(self.photoCollectionView.frame.width) / 3                }
            }
            self.photoCollectionView.reloadData()
        })
        
    }
    
}

extension CollectionViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("***#ItemsInSection**** Photo.count is \(photos.count)")

        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! CollectionViewCell
        
        print("********** didSelectItemAtIndexPath called")
        
        if let index = selectedIndexes.index(of: indexPath as NSIndexPath) {
            selectedIndexes.remove(at: index)
            cell.photoImageView.alpha = 1.0
        } else {
            selectedIndexes.append(indexPath as NSIndexPath)
            cell.photoImageView.alpha = 0.2
        }
        
        print("Number of selected photos is: \(selectedIndexes.count)")
        toggleBottomBar()

    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionViewCell", for: indexPath) as! CollectionViewCell

        self.userLabel.isHidden = true

        // Default alpha needed after album is emptied out to be sure new collection is reset to alpha 1.0
        cell.photoImageView.alpha = 1.0
        
        let photo = photos[indexPath.row]
        let photoData = photo.imageData
        
        if photoData != nil {
            // photo image exists, so set the data to the image property
            DispatchQueue.main.async(execute: {
                cell.activityIndicatorView.stopAnimating()
                cell.activityIndicatorView.isHidden = true
                let photoImage = UIImage(data: photoData as! Data)
                cell.photoImageView.image = photoImage
            })
        } else {
            // No data, so get NSData from UrlString -> Url -> NSData -> Image -> image property
            cell.photoImageView.image = UIImage(named: "defaultImage1")
            cell.activityIndicatorView.startAnimating()
            cell.activityIndicatorView.isHidden = false
            
            DispatchQueue.main.async(execute: {

                self.flickr.getImageData(photo: photo, completionHandler: { (imageData, error) in
                    // check for error
                    guard error == nil else {
                        return
                    }
                        cell.activityIndicatorView.stopAnimating()
                        cell.activityIndicatorView.isHidden = true
                        cell.photoImageView.image = UIImage(data: imageData! as Data)
                        photo.imageData = imageData
                })
                
            })
        }
        return cell
    }
}

// CollectionView layout from Ray Wenderlich
extension CollectionViewController : UICollectionViewDelegateFlowLayout {
    //1
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        //2
        let itemsPerRow: CGFloat = 3.0
        let availableWidth = (view.frame.width - 12) / itemsPerRow
        let width = floor(availableWidth)
        let widthPerItem = (width) 
        
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    //3
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    // 4
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
    
    // 5
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
}
