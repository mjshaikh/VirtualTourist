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
    
    
    func fetchPhotosForLatLong(url: URL, pin: Pin, completion: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        
        Alamofire.request(url, method: .get)
                .validate()
                .responseJSON { (response) -> Void in
                
                print("Request: \(response.request!)")
//                print("Response: \(response.response!)")
                
                switch response.result {
                    
                case .success:
                    let json = JSON(response.result.value as Any)
                    
                    //print(json)
                    
                    var photos = [Photo]()
                    
                    let totalPages = json["photos"]["pages"].intValue
                    
                    pin.totalPages = totalPages
                    
                    for result in json["photos"]["photo"].arrayValue {
                        let title = result["title"].stringValue
                        let urlString = result["url_m"].stringValue
                        self.downloadPhoto(urlString: urlString, completion: { (photoData, error) in
                            
                            guard let photoData = photoData else{
                                print("No photoData : \(error)")
                                return
                            }
                            
                            let photoObject = Photo(title: title, imageData: photoData, pin: pin, context: appDelegate.stack.mainContext)
                            photos.append(photoObject)
                        })
                    }
                    
                    saveContext()
                    
                    completion(true, nil)
                    
                case .failure(let error):
                    completion(false, error)
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
