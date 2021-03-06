//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Mohammed Javeed Shaikh on 2017-01-13.
//  Copyright © 2017 Mohammed Javeed Shaikh. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelMapViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var deletePinLabel: UILabel!
    
    let defaults = UserDefaults.standard
    
    // We will create an array to store all point annotations
    // and then provided to the map view.
    var annotations = [MKPointAnnotation]()
    
    var editMode: Bool = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        appDelegate.travelMapVC = self
        
        // Fetch all Pins
        if let pins = fetchAllPins(){
            
            // Add annotations pins on the map
            addAnnotationToMap(pins)
            
            // Restore the last known map state
            restoreMapState()

        }
        
        // Fetch and display total Photos in CoreData
        fetchAllPhotos()
    }
    
    
    @IBAction func downloadPhotos(_ sender: UIBarButtonItem) {
        
    }

    
    
    func restoreMapState(){
        
        let locationDict = defaults.dictionary(forKey: "locationDict")
        
        if let locationDict = locationDict {
            
            let latitude = locationDict["latitude"] as! CLLocationDegrees
            let longitude = locationDict["longitude"] as! CLLocationDegrees
            let latitudeDelta = locationDict["latitudeDelta"] as! CLLocationDegrees
            let longitudeDelta = locationDict["longitudeDelta"] as! CLLocationDegrees
            
            let center = CLLocationCoordinate2DMake(latitude, longitude)
            let span = MKCoordinateSpanMake(latitudeDelta, longitudeDelta)
            
            let region = MKCoordinateRegionMake(center, span)
            
            mapView.setRegion(region, animated: false)
            
            print("Map state restored!")
        }
        
    }
    
    
    func saveMapState(){
        
        let latitude = mapView.region.center.latitude
        let longitude = mapView.region.center.longitude
        let latitudeDelta = mapView.region.span.latitudeDelta
        let longitudeDelta = mapView.region.span.longitudeDelta
        
        let locationDict = ["latitude": latitude, "longitude": longitude,
                            "latitudeDelta": latitudeDelta, "longitudeDelta": longitudeDelta]
        
        defaults.set(locationDict, forKey: "locationDict")
        
        print("Map state saved!")
        
    }
    
    
    @IBAction func handleTap(_ gestureReconizer: UILongPressGestureRecognizer) {
        
        if gestureReconizer.state ==  UIGestureRecognizerState.began {
            
            let location = gestureReconizer.location(in: mapView)
            let coordinate = mapView.convert(location,toCoordinateFrom: mapView)
            
            // Add annotation:
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            mapView.addAnnotation(annotation)
            
            let pin = Pin(latitude: Double(coordinate.latitude), longitude: Double(coordinate.longitude), totalPages: 0, currentPage: 0, context: appDelegate.stack.mainContext)
            
            print("Just created a pin with latitude: \(pin.latitude) and longitude: \(pin.longitude)")
            
            // Pin is stored in CoreData
            saveContext()
        }
    }

    
    
    @IBAction func toggleEditMode(_ barButton: UIBarButtonItem) {
        
        if editMode {
            editMode = false
            deletePinLabel.isHidden = true
            barButton.title = "Edit"
        }
        else {
            editMode = true
            deletePinLabel.isHidden = false
            barButton.title = "Done"
        }
        
    }
    
    
    
    /* This function takes an array carrying location
     and adds the locations as an annotations on the Map */
    
    func addAnnotationToMap(_ pins: [Pin]) {
        
        // If annotations already exist then remove them
        if !annotations.isEmpty {
            mapView.removeAnnotations(annotations)
            annotations.removeAll()
        }
        
        // For each location build the annotation
        
        for pin in pins {
            
            let lat = CLLocationDegrees(pin.latitude)
            let long = CLLocationDegrees(pin.longitude)
            
            // The lat and long are used to create a CLLocationCoordinates2D instance.
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
            
            // Here we create the annotation and set its coordiate, title, and subtitle properties
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            
            // Finally we place the annotation in an array of annotations.
            annotations.append(annotation)
        }
        
        // When the array is complete, we add the annotations to the map.
        mapView.addAnnotations(annotations)
        
    }
    
    
    
    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "pinSegue" {
            
            if let photoAlbumVC = segue.destination as? PhotoAlbumViewController {
                
                let pin = sender as! Pin
                
                // Inject the pin and totalPages
                photoAlbumVC.pin = pin
            }
        }
    }
    
    
    // MARK:  Map Delegate methods
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.animatesDrop = true
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        let latitude = view.annotation?.coordinate.latitude
        let longitude = view.annotation?.coordinate.longitude
        
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        let pred = NSPredicate(format: "latitude = %lf AND longitude = %lf", latitude!, longitude!)
        fetchRequest.predicate = pred
        
        var pinsArray: [Pin]?
        
        // Find the Pin in Core Data
        
        do {
            let results = try appDelegate.stack.mainContext.fetch(fetchRequest)
            pinsArray = results
            
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        
        // Make sure the selected pin exists in CoreData before moving forward
        guard let pins = pinsArray, let pinObject = pins.first else {
            return
        }
        
        if editMode{
            
            // If pin is clicked in edit mode then remove it from the CoreData and Map
            appDelegate.stack.mainContext.delete(pinObject)
            mapView.removeAnnotation(view.annotation!)
            
            print("pin deleted with latitude: \(latitude!) and longitude: \(longitude!)")
            
            // Save the deletion changes in CoreData
            saveContext()
            
            //Fetch the Pins to confirm changes if is saved in CoreData
            fetchAllPins()
            
            // Fetch the Photos to confirm changes if is saved in CoreData
            fetchAllPhotos()
            
            
        }
        else{   // Otherwise open the Photo Album for the selected Pin
            
            print("pin selected with latitude: \(latitude!) and longitude: \(longitude!)")

            // If Pin object has photos in CoreData just load them
            if let pinPhotos = pinObject.photos, pinPhotos.count > 0 {
                print("Pin object has \(pinPhotos.count) photos")
                
                mapView.deselectAnnotation(view.annotation, animated: false)
                
                self.performSegue(withIdentifier: "pinSegue", sender: pinObject)
            }
            else{   // Otherwise the pin object has no photos so download them once again
                
                print(" Pin object don't have photos. Downloading now...")
                
                // Fetch photos starting from page # 1
                pinObject.currentPage = 1
                
                // Initiate flickr download request for the Pin
                VirtualTouristClient.sharedInstance.initiateFlickrDownload(pin: pinObject, completion: {
                    (success, photos, error) in
                    
                    if success{
                        print("Download succeeded")
                        
                        mapView.deselectAnnotation(view.annotation, animated: false)
                        
                        self.performSegue(withIdentifier: "pinSegue", sender: pinObject)
                    }
                    else{
                        print("Error while searching photos: \(error?.localizedDescription)")
                    }
                })
            }
        }
        
    }
}

