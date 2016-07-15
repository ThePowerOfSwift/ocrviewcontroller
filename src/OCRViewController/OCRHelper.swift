//
//  OCRHelper.swift
//  GPUImageOCR
//
//  Created by Mario Scheliga on 6/22/16.
//  Copyright © 2016 Mario Scheliga. All rights reserved.
//

import Foundation

final public class OCRHelper : NSObject {
    public static func extractMRZ(img: UIImage) -> UIImage {
        return OCRHelperImplementation.extractMRZ(img)
    }
    
    //FIXME: if only this is needed we can totally get rid of the
    // opencv dependency by using CIFilters
    public static func prepareOCR(img: UIImage) -> UIImage {
        return OCRHelperImplementation.prepareOCR(img)
    }
    
}