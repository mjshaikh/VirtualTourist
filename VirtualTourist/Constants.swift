//
//  Constants.swift
//  VirtualTourist
//
//  Created by Mohammed Javeed Shaikh on 2017-08-17.
//  Copyright © 2017 Mohammed Javeed Shaikh. All rights reserved.
//

import Foundation
import UIKit

let APIKey = "eb76169211aa651ae093ef6333ab8c64"

var appDelegate: AppDelegate {
    return UIApplication.shared.delegate as! AppDelegate
}

func saveContext(){
    do {
        try appDelegate.stack.save()
    } catch let error as NSError {
        print("Could not save. \(error), \(error.userInfo)")
    }
}

func bboxString(latitude: Double, longitude: Double) -> String {
    // ensure bbox is bounded by minimum and maximums

        let minimumLon = max(longitude - Flickr.SearchBBoxHalfWidth, Flickr.SearchLonRange.0)
        let minimumLat = max(latitude - Flickr.SearchBBoxHalfHeight, Flickr.SearchLatRange.0)
        let maximumLon = min(longitude + Flickr.SearchBBoxHalfWidth, Flickr.SearchLonRange.1)
        let maximumLat = min(latitude + Flickr.SearchBBoxHalfHeight, Flickr.SearchLatRange.1)
        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
}

// MARK: Flickr
struct Flickr {
    static let APIScheme = "https"
    static let APIHost = "api.flickr.com"
    static let APIPath = "/services/rest"
    
    static let SearchBBoxHalfWidth = 1.0
    static let SearchBBoxHalfHeight = 1.0
    static let SearchLatRange = (-90.0, 90.0)
    static let SearchLonRange = (-180.0, 180.0)
}

// MARK: Flickr Parameter Keys
struct FlickrParameterKeys {
    static let Method = "method"
    static let APIKey = "api_key"
    static let Extras = "extras"
    static let Format = "format"
    static let NoJSONCallback = "nojsoncallback"
    static let SafeSearch = "safe_search"
    static let BoundingBox = "bbox"
    static let Page = "page"
    static let PerPage = "per_page"
}

// MARK: Flickr Parameter Values
struct FlickrParameterValues {
    static let SearchMethod = "flickr.photos.search"
    static let APIKey = "eb76169211aa651ae093ef6333ab8c64"
    static let ResponseFormat = "json"
    static let DisableJSONCallback = "1" /* 1 means "yes" */
    static let MediumURL = "url_m"
    static let UseSafeSearch = "1"
    static let ResultPerPage = "21"
}


func buildFlickrURL(bbox: String, page: Int) -> URL {
    
    let parameters: [String : Any] = [
        FlickrParameterKeys.Method: FlickrParameterValues.SearchMethod,
        FlickrParameterKeys.APIKey: FlickrParameterValues.APIKey,
        FlickrParameterKeys.BoundingBox: bbox,
        FlickrParameterKeys.Page : page,
        FlickrParameterKeys.PerPage : FlickrParameterValues.ResultPerPage,
        FlickrParameterKeys.SafeSearch: FlickrParameterValues.UseSafeSearch,
        FlickrParameterKeys.Extras: FlickrParameterValues.MediumURL,
        FlickrParameterKeys.Format: FlickrParameterValues.ResponseFormat,
        FlickrParameterKeys.NoJSONCallback: FlickrParameterValues.DisableJSONCallback
    ]
    
    var components = URLComponents()
    components.scheme = Flickr.APIScheme
    components.host = Flickr.APIHost
    components.path = Flickr.APIPath
    components.queryItems = [URLQueryItem]()
    
    for (key, value) in parameters {
        let queryItem = URLQueryItem(name: key, value: "\(value)")
        components.queryItems!.append(queryItem)
    }
    
    return components.url!
}
