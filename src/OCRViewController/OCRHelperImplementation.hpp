//
//  OCRHelperImplementation.h
//  GPUImageOCR
//
//  Created by Mario Scheliga on 6/22/16.
//  Copyright © 2016 Mario Scheliga. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OCRHelperImplementation : NSObject

+ (UIImage *) extractMRZ:(UIImage*) image;
+ (UIImage *) prepareOCR:(UIImage*) image;
+ (UIImage *) ocrImage:(UIImage*) image;
+ (UIImage *) swtImage:(UIImage*) image;

@end