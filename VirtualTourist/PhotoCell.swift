//
//  PhotoCell.swift
//  VirtualTourist
//
//  Created by Mohammed Javeed Shaikh on 2017-08-17.
//  Copyright © 2017 Mohammed Javeed Shaikh. All rights reserved.
//

import UIKit

class PhotoCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
 
    var imageURL: String?
}
