//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by Paul ReFalo on 12/31/16.
//  Copyright © 2016 QSS. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class FlickrClient {
    
    private static var sharedInstance = FlickrClient()
    
    class func sharedClient() -> FlickrClient {
        return sharedInstance
    }
    
    
    func searchByLatLon(lat: Double, long: Double, numberOfPhotos: Int = 1, completionHandler: @escaping (_ photoAlbumArray: [[String:AnyObject]], _ error: String?) ->  Void) {
        
        print("Coordinates in flickr are: \(lat) \(long)")
        
        let methodParameters = [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod,
            Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.BoundingBox: bboxString(lat: lat, long: long),
            Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.UseSafeSearch,
            Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,
            Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback
        ]
        
        // create session and request
        let session = URLSession.shared
        let request = URLRequest(url: flickrURLFromParameters(methodParameters as [String : AnyObject]))
        print("Request is: \(request)")
        var randomPage = Int()
        
        // create network request
        let task = session.dataTask(with: request) { (data, response, error) in
            
            // if an error occurs, print it and re-enable the UI
            func displayError(_ error: String) {
                print(error)
                
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                displayError("There was an error with your request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                displayError("Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                displayError("No data was returned by the request!")
                return
            }
            
            // parse the data
            let parsedResult: [String:AnyObject]!
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:AnyObject]
            } catch {
                displayError("Could not parse the data as JSON: '\(data)'")
                return
            }
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = parsedResult[Constants.FlickrResponseKeys.Status] as? String, stat == Constants.FlickrResponseValues.OKStatus else {
                displayError("Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            /* GUARD: Is "photos" key in our result? */
            guard let photosDictionary = parsedResult[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                displayError("Cannot find keys '\(Constants.FlickrResponseKeys.Photos)' in \(parsedResult)")
                return
            }
            
            /* GUARD: Is "pages" key in the photosDictionary? */
            guard let totalPages = photosDictionary[Constants.FlickrResponseKeys.Pages] as? Int else {
                displayError("Cannot find key '\(Constants.FlickrResponseKeys.Pages)' in \(photosDictionary)")
                return
            }
            
            // pick a random page!
            let pageLimit = min(totalPages, 40)
            randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
            //            let returnedPhotoArray = self.displayImageFromFlickrBySearch(methodParameters, withPageNumber: randomPage)
            
            print("********* The total number of pages is: \(photosDictionary[Constants.FlickrResponseKeys.Pages] as? Int)")
            print("I******** The randomPage is \(randomPage)")
            
            var methodParametersWithPageNumber = methodParameters
            methodParametersWithPageNumber[Constants.FlickrParameterKeys.Page] = (randomPage as AnyObject) as? String

            // create session and request
            let session = URLSession.shared
            let secondRequest = URLRequest(url: self.flickrURLFromParameters(methodParametersWithPageNumber as [String : AnyObject]))
            
            // create network request
            let secondTask = session.dataTask(with: request) { (data, response, error) in
                
                // if an error occurs, print it and re-enable the UI
                func displayError(_ error: String) {
                    completionHandler([photosDictionary], error)

                    print(error)
                }
                
                /* GUARD: Was there an error? */
                guard (error == nil) else {
                    displayError("There was an error with your request: \(error)")
                    return
                }
                
                /* GUARD: Did we get a successful 2XX response? */
                guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                    displayError("Your request returned a status code other than 2xx!")
                    return
                }
                
                /* GUARD: Was there any data returned? */
                guard let data = data else {
                    displayError("No data was returned by the request!")
                    return
                }
                
                // parse the data
                let parsedResult: [String:AnyObject]!
                do {
                    parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:AnyObject]
                } catch {
                    displayError("Could not parse the data as JSON: '\(data)'")
                    return
                }
                
                /* GUARD: Did Flickr return an error (stat != ok)? */
                guard let stat = parsedResult[Constants.FlickrResponseKeys.Status] as? String, stat == Constants.FlickrResponseValues.OKStatus else {
                    displayError("Flickr API returned an error. See error code and message in \(parsedResult)")
                    return
                }
                
                /* GUARD: Is the "photos" key in our result? */
                guard let photosDictionary = parsedResult[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                    displayError("Cannot find key '\(Constants.FlickrResponseKeys.Photos)' in \(parsedResult)")
                    return
                }
                
                /* GUARD: Is the "photo" key in photosDictionary? */
                guard let photosArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String: AnyObject]] else {
                    displayError("Cannot find key '\(Constants.FlickrResponseKeys.Photo)' in \(photosDictionary)")
                    return
                }
                
                if photosArray.count == 0 {
                    displayError("No Photos Found. Search Again.")
                    return
                } else {
                    print("********* The total number of photos is: \(photosArray.count)")
                    
                    var albumSize = numberOfPhotos

                    if photosArray.count < albumSize {
                        albumSize = photosArray.count
                    }
                    var indexSet = Set<Int>()
                    while indexSet.count < albumSize {
                        let index = arc4random_uniform(UInt32(photosArray.count)) // random index from array
                        indexSet.insert(Int(index))
                    }
                    
                    var collectionDictionary = [String:AnyObject]()
                    var photoAlbumArray = [[String:AnyObject]]()
                    
                    while !indexSet.isEmpty {
                        // index out of range here.  Improve Error handling

                        let randomPhotoIndex = indexSet.first
                        let photoDictionary = photosArray[randomPhotoIndex!] as [String: AnyObject]
                    
                        indexSet.removeFirst()
                    
                    
                        collectionDictionary["title"] = (photoDictionary[Constants.FlickrResponseKeys.Title])
                        
                    
                    
                        /* GUARD: Does our photo have a key for 'url_m'? */
                        guard let imageUrlString = photoDictionary[Constants.FlickrResponseKeys.MediumURL] as? String else {
                            displayError("Cannot find key '\(Constants.FlickrResponseKeys.MediumURL)' in \(photoDictionary)")
                            continue
                        }
                        
                        // if an image exists at the url, set the image
                        let imageURL = URL(string: imageUrlString)

                        collectionDictionary["imageURL"] = imageURL as AnyObject?
                        collectionDictionary["imageURLString"] = imageUrlString as AnyObject
                        
                        photoAlbumArray.append(collectionDictionary)
                            
                        
                        
                    } // end while
                    completionHandler(photoAlbumArray, nil)

                }
                
            }
            
            // start the task!
            secondTask.resume()
            

        }
        
        // start the task!
        task.resume()


    }
    
    func bboxString(lat: Double, long: Double) -> String {
        let latitude: Double? = lat
        let longitude: Double? = long
 
        
        // ensure bbox is bounded by minimum and maximums

        let minimumLon = max(longitude! - Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.0),
             minimumLat = max(latitude! - Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.0),
             maximumLon = min(longitude! + Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.1),
            maximumLat = min(latitude! + Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.1)
        
        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"

    }
    
    // MARK: Helper for Creating a URL from Parameters
    
    private func flickrURLFromParameters(_ parameters: [String:AnyObject]) -> URL {
        
        var components = URLComponents()
        components.scheme = Constants.Flickr.APIScheme
        components.host = Constants.Flickr.APIHost
        components.path = Constants.Flickr.APIPath
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }
    
    func getImageData(photo: Photo, completionHandler: (_ imageData: NSData?, _ error: String?) -> Void) {
        
        if let fileUrl = Foundation.URL(string: photo.urlString!) {
            if let imageData = try? Data(contentsOf: fileUrl) {
                completionHandler(imageData as NSData?, nil)
            } else {
                completionHandler(nil, "Could not get imageData")
            }
        } else {
            completionHandler(nil, "Could not get fileUrl")
        }

    }
}

