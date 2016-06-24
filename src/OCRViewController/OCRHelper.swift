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
}