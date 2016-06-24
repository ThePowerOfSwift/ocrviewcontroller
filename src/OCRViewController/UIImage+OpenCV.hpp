//
//  UIImage+OpenCV.h
//  GPUImageOCR
//
//  Created by Mario Scheliga on 6/22/16.
//  Copyright © 2016 Mario Scheliga. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "opencv2/opencv.hpp"

@interface UIImage (OpenCV)

//cv::Mat to UIImage
+ (UIImage *)imageWithCVMat:(const cv::Mat&)cvMat;
- (id)initWithCVMat:(const cv::Mat&)cvMat;

//UIImage to cv::Mat
- (cv::Mat)CVMat;
- (cv::Mat)CVMat3;  // no alpha channel
- (cv::Mat)CVGrayscaleMat;

@end