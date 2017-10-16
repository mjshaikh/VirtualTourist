//
//  CustomFlowLayout.swift
//  VirtualTourist
//
//  Created by Mohammed Javeed Shaikh on 2017-08-16.
//  Copyright © 2017 Mohammed Javeed Shaikh. All rights reserved.
//

import Foundation
import UIKit

class CustomFlowLayout: UICollectionViewFlowLayout {
    
    var isSetup = false
    
    override func prepare() {
        super.prepare()
        
        var cellSize : Int {
            
            let columns = isPhone() ? 3 : 5
            
            let screenWidth = Int(collectionView!.frame.size.width)
            let minInteritemSpacing = Int(minimumInteritemSpacing)
            let edgeInset = Int(sectionInset.left + sectionInset.right)

            return (screenWidth - ((columns - 1) * minInteritemSpacing) - edgeInset) / columns
        }
        
        itemSize = CGSize(width: cellSize, height: cellSize)
    }
    
    
    /* This function allow us to invalidate layout upon screen rotation if the frame size changes */
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return !newBounds.size.equalTo(collectionView!.frame.size)
    }
    
    func isPhone() -> Bool{
        return UIDevice.current.model == "iPhone"
    }

}
