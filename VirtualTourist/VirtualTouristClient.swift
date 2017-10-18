//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Mohammed Javeed Shaikh on 2017-08-17.
//  Copyright © 2017 Mohammed Javeed Shaikh. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class VirtualTouristClient {
    
    // Singleton to maintain a single client object across the app
    static let sharedInstance = VirtualTouristClient()
    
    private init() {}
    
    
    func initiateFlickrDownload(pin: Pin, completion: @escaping (_ success: Bool, _ photos: [Photo]?, _ error: Error?) -> Void){
        
        let boundingBox = bboxString(latitude: pin.latitude, longitude: pin.longitude)
        
        let url = buildFlickrURL(bbox: boundingBox, page: pin.currentPage)
        
        // Download photo details for lat/long on first page for 21 photos
        photoSearchForLatLong(url: url, pin: pin,completion: {
            (success, photos, error) in
            
            if success {
                //Fetch the Pins to confirm if they are indeed saved in CoreData
                fetchAllPins()
                
                // Fetch the Photos to confirm if they are indeed saved in CoreData
                fetchAllPhotos()

                completion(true, photos, nil)
            }
            else{   // Error
                completion(false, nil, error)
            }
        })
    }
    
    
    func photoSearchForLatLong(url: URL, pin: Pin, completion: @escaping (_ success: Bool, _ photos: [Photo]?, _ error: Error?) -> Void) {
        
        Alamofire.request(url, method: .get)
            .validate()
            .responseJSON { (response) -> Void in
                
                //print("Request: \(response.request!)")
                //print("Response: \(response.response!)")
                
                switch response.result {
                    
                case .success:
                    let json = JSON(response.result.value as Any)
                    
                    //print(json)
                    
                    var photos = [Photo]()
                    
                    let totalPages = json["photos"]["pages"].intValue
                    
                    pin.totalPages = totalPages
                    
                    for result in json["photos"]["photo"].arrayValue {
                        let title = result["title"].stringValue
                        let urlString = result["url_q"].stringValue
                        
                        let photoObject = Photo(title: title, imageUrl: urlString, pin: pin, context: appDelegate.stack.mainContext)
                        photos.append(photoObject)
                        
                        // Downloaded photo is stored in CoreData
                        saveContext()
                        
                        if json["photos"]["photo"].count == photos.count{
                            completion(true, photos, nil)
                        }
                    }
                    
                case .failure(let error):
                    completion(false, nil, error)
                }
        }
    }
    
    
    func downloadPhoto(urlString: String, completion: @escaping (_ photoData: Data?, _ error: Error?) -> Void){
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL : \(urlString)")
            completion(nil,nil)
            return
        }
        
        Alamofire.request(
            url,
            method: .get)
            .validate()
            .responseData{ (response) -> Void in
                
                //print("Request: \(response.request!)")
                //print("Response: \(response.response!)")
                
                switch response.result {
                    
                case .success:
                    
                    if let photoData = response.result.value {
                        //print("JSON: \(photoData)")
                        
                        completion(photoData, nil)
                    }
                    
                    
                case .failure(let error):
                    print("Error while fetching photos: \(error.localizedDescription)")
                    completion(nil, error)
                }
        }
        
    }
    
}
