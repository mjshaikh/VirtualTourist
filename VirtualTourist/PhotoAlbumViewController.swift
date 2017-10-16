//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Mohammed Javeed Shaikh on 2017-08-17.
//  Copyright © 2017 Mohammed Javeed Shaikh. All rights reserved.
//

import UIKit
import MapKit
import CoreData


class PhotoAlbumViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var button: UIButton!
    
    var pin: Pin?
    
    var isNewPhotoSetRequest = true
    
    var insertIndexPaths = [IndexPath]()
    var updateIndexPaths = [IndexPath]()
    var deleteIndexPaths = [IndexPath]()
    
    var photoIndexPaths = [IndexPath](){
        
        /* We use property observer to switch visibility of delete button when atleast one item is selected
         and added to selectedIndex array */
        
        didSet{
            if !photoIndexPaths.isEmpty{
                button.setTitle("Remove Selected Pictures", for: .normal)
                isNewPhotoSetRequest = false
            }
            else{
                button.setTitle("New Collection", for: .normal)
                isNewPhotoSetRequest = true
            }
        }
    }
    
    var _fetchedResultsController: NSFetchedResultsController<Photo>? = nil
    
    var fetchedResultsController: NSFetchedResultsController<Photo> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let managedObjectContext = appDelegate.stack.mainContext
        
        // Find all the photos related to current pin
        let predicate = NSPredicate(format: "pin = %@", pin!)
        
        fetchRequest.predicate = predicate
        
        // Sort by title
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        
        let resultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        resultsController.delegate = self;
        _fetchedResultsController = resultsController
        
        do {
            try _fetchedResultsController!.performFetch()
        } catch let error as NSError {
            fatalError("Unresolved error \(error)")
        }
        return _fetchedResultsController!
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let pin = pin, let photos = pin.photos else {
            print("Oops pin or photo is nil")
            return
        }
        
        collectionView.allowsMultipleSelection = true
        
        // The lat and long are used to create a CLLocationCoordinates2D instance.
        let coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        
        // Here we create the annotation and set its coordiate, title, and subtitle properties
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        
        mapView.addAnnotation(annotation)
        centerMapOnLocation(coordinate)

    }
    
    /* This function takes a CLLocationCoordinate2D and zoom in and centers on the map location */
    
    func centerMapOnLocation(_ coordinate: CLLocationCoordinate2D) {
        let regionRadius: CLLocationDistance = 1000
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinate,
                                                                  regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
        
    }
    
    
    @IBAction func buttonAction(_ sender: UIButton) {
        
        if !isNewPhotoSetRequest {   // If button press is for removal of photos
            
            if photoIndexPaths.count > 0 {
                removePhoto()
            }
        }
        else{       // Otherwise button press is for downloading new photo set
            
            guard let pin = pin else {  // Guard check for the current pin
                return
            }
            
            // Fetch photos for the next page
            pin.currentPage = pin.currentPage + 1
            
            // Delete previous set of photoObjects
            
            if let photoObjects = fetchedResultsController.fetchedObjects {
                for photo in photoObjects {
                    appDelegate.stack.mainContext.delete(photo)
                }
            }
            
            saveContext()
            
            print("FRC count: \(fetchedResultsController.fetchedObjects?.count)")
            
            
            let boundingBox = bboxString(latitude: pin.latitude, longitude: pin.longitude)
            
            if pin.currentPage <= pin.totalPages {
                
                let url = buildFlickrURL(bbox: boundingBox, page: pin.currentPage)
                
                VirtualTouristClient.sharedInstance.fetchPhotosForLatLong(url: url,
                                                                          pin: pin,
                                                                          completion: { (success, error) in
                    
                    if success {
                        
                        print("Current page : \(pin.currentPage)")
                        print("Total pages : \(pin.totalPages)")
                        
                        saveContext()
                    }
                    else{   // Error
                        print("Error while fetching photos: \(error?.localizedDescription)")
                    }
                })
            }
        }
    }
    
    
    func removePhoto(){
        
        for index in photoIndexPaths{
            
            print("Deleting photo for index \(index.row)")
            
            // Deselect and remove highlighting for the cell at specific index
            //highlightCell(cell: index, visible: false)
            
            // Fetch Photo
            let photo = fetchedResultsController.object(at: index)
            
            // Delete Photo
            appDelegate.stack.mainContext.delete(photo)
            
        }
        
        // Clear the photoIndexPaths Array
        photoIndexPaths.removeAll()
        
        saveContext()
    }
    
    
    /* This function uses a visible flag parameter to either highlight or unhighlight the item at specific index */
    
    func highlightCell(cell : PhotoCell, visible: Bool) {
        
//        let cell = collectionView.cellForItem(at: indexPath) as! PhotoCell
        
        if visible {
            cell.layer.borderWidth = 3.0
            cell.layer.borderColor = UIColor.orange.cgColor
        } else {
            cell.layer.borderWidth = 0
            cell.layer.borderColor = nil
        }
    }
    
    
    
    // MARK: CollectionView DataSource and Delegate methods
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let sections = fetchedResultsController.sections {
            return sections[section].numberOfObjects
        }
        return 0
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let photoObject = fetchedResultsController.object(at: indexPath) as Photo
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! PhotoCell
        
        if let photo = photoObject.imageData {   // If image data exists then set imageView with photoData
            cell.activityIndicator.stopAnimating()
            //print("photoObject cache : \(photoObject)")
            cell.imageView.image = UIImage(data: photo as Data)
        }
        else{
            // Set placeholder image
            cell.imageView.image = UIImage(named: "placeholder")
            
            cell.activityIndicator.startAnimating()
            
        }
        
        if cell.isSelected{
            highlightCell(cell: cell, visible: true)
        }
        else{
            highlightCell(cell: cell, visible: false)
        }
        
        return cell
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let cell = collectionView.cellForItem(at: indexPath) as! PhotoCell
        photoIndexPaths.append(indexPath)
        highlightCell(cell: cell, visible: true)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
        let cell = collectionView.cellForItem(at: indexPath) as! PhotoCell
        
        if let index = photoIndexPaths.index(of: indexPath) {
            photoIndexPaths.remove(at: index)
        }
        highlightCell(cell: cell, visible: false)
    }
    
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertIndexPaths.removeAll()
        updateIndexPaths.removeAll()
        deleteIndexPaths.removeAll()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        
        switch type {
        case .insert:
            insertIndexPaths.append(newIndexPath!)
        case .delete:
            deleteIndexPaths.append(indexPath!)
        case .update:
            updateIndexPaths.append(indexPath!)
        case .move:
            print("We aren't doing moves so this should never be seen.")
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView.performBatchUpdates({
            self.collectionView.insertItems(at: self.insertIndexPaths)
            self.collectionView.deleteItems(at: self.deleteIndexPaths)
            self.collectionView.reloadItems(at: self.updateIndexPaths)
        }, completion: nil)
    }
    
}
