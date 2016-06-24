//
//  OCRHelperImplementation.m
//  GPUImageOCR
//
//  Created by Mario Scheliga on 6/22/16.
//  Copyright © 2016 Mario Scheliga. All rights reserved.
//

#include "opencv2/opencv.hpp"
#import "OCRHelperImplementation.hpp"
#import "UIImage+OpenCV.hpp"
#import "UIImage+Rotate.hpp"

#include <sstream>
#include <TesseractOCR/TesseractOCR.h>

using namespace cv;
using namespace std;

@implementation OCRHelperImplementation


bool compareContourAreas ( std::vector<cv::Point> contour1, std::vector<cv::Point> contour2 ) {
    double i = fabs( contourArea(Mat(contour1)) );
    double j = fabs( contourArea(Mat(contour2)) );
    return ( i > j );
}

inline Mat cropMRZArea(Mat input) {
    Mat cropped = input.clone();
    Mat output = input.clone();
    cv::Size size = input.size();
    Mat rectKernel = cv::getStructuringElement(MORPH_RECT, cv::Size(13, 5));
    Mat sqKernel = cv::getStructuringElement(MORPH_RECT, cv::Size(21, 21));
    Mat rectKernel2 = cv::getStructuringElement(MORPH_RECT, cv::Size(3, 3));
    
    
    
    float width = size.width;
    float height = size.height;
    float ratio = 500/height;
    
    size.width = width*ratio;
    size.height = 500;
    
    cv::resize(output, output, size);
    Mat gray;
    cv::cvtColor(output, gray, COLOR_BGR2GRAY);
    cv::GaussianBlur(gray, gray, cv::Size(25,25), 0);
    Mat blackhat;
    cv::morphologyEx(gray, blackhat, MORPH_BLACKHAT, rectKernel);
    
    // compute the Scharr gradient of the blackhat image and
    // scale the result into the range [0, 255]
    
    Mat gradX;
    cv::Sobel(blackhat, gradX, CV_32F, 1, 0, -1);
    gradX = cv::abs(gradX);
    double minVal;
    double maxVal;
    cv::minMaxIdx(gradX, &minVal, &maxVal);
    gradX = Mat(255 * ((gradX - minVal) / (maxVal - minVal)));
    gradX.convertTo(gradX, CV_8UC1);
    
    // apply a closing operation using the rectangular kernel to close
    // gaps in between letters -- then apply Otsu's thresholding method
    
    cv::morphologyEx(gradX, gradX, MORPH_CLOSE, rectKernel);
    Mat thresh;
    cv::threshold(gradX, thresh, 0, 255, THRESH_BINARY | THRESH_OTSU);
    
    // perform another closing operation, this time using the square
    // kernel to close gaps between lines of the MRZ, then perform a
    // serieso of erosions to break apart connected components
    cv::morphologyEx(thresh, thresh, MORPH_CLOSE, sqKernel);
    cv::erode(thresh, thresh, rectKernel2, cv::Point(-1,-1), 4);
    
    // during thresholding, it's possible that border pixels were
    // included in the thresholding, so let's set 5% of the left and
    // right borders to zero
    //    p = int(image.shape[1] * 0.05)
    //    thresh[:, 0:p] = 0
    //    thresh[:, image.shape[1] - p:] = 0
    
    vector< vector<cv::Point> > contours;
    cv::findContours(thresh.clone(), contours, RETR_EXTERNAL, CV_CHAIN_APPROX_SIMPLE);
    sort(contours.begin(), contours.end(), compareContourAreas);
    NSLog(@"found contours: %d", contours.size());
    
    for(size_t i = 0; i < contours.size(); i++) {
        vector<cv::Point> contour = contours[i];
        cv::Rect bounding = cv::boundingRect(contour);
        int x = bounding.x;
        int y = bounding.y;
        int w = bounding.width;
        int h = bounding.height;
        
        NSLog(@"boundingbox of contour");
        NSLog(@"    x: %d", x);
        NSLog(@"    y: %d", y);
        NSLog(@"    w: %d", w);
        NSLog(@"    h: %d", h);
        NSLog(@"    size.width: %d", size.width);
        
        float ar = w / h;
        float crWidth = float(w) / size.width; //FUCK: gray.shape[1] ?!
        NSLog(@"crWidth of contour: %f", crWidth);
        NSLog(@"ar: %f", ar);
        
        if(ar > 5 && crWidth > 0.75) {
            float pX = int((x + w) * 0.03);
            float pY = int((y + h) * 0.03);
            x = x - pX;
            y = y - pY;
            w = w + (pX * 2);
            h = h + (pY * 2);
            NSLog(@"cut out");
            NSLog(@"    x: %d", x);
            NSLog(@"    y: %d", y);
            NSLog(@"    w: %d", w);
            NSLog(@"    h: %d", h);
            
            cv::Size osize = output.size();
            
            NSLog(@" from w: %d", osize.width);
            NSLog(@"      h: %d", osize.height);
            NSLog(@"      cols: %d", output.cols);
            NSLog(@"      rows: %d", output.rows);
            //  &&  &&  &&  &&
            
            
            cv::Rect roi = cv::Rect(cv::Point(x, y), cv::Size(w, h));
            
            NSLog(@" roi.x: %d", roi.x);
            NSLog(@" roi.y: %d", roi.y);
            NSLog(@" roi.width: %d", roi.width);
            NSLog(@" roi.height: %d", roi.height);
            NSLog(@"assert: 0 <= roi.x (%d)", 0 <= roi.x);
            NSLog(@"assert: 0 <= roi.width (%d)", 0 <= roi.width);
            NSLog(@"assert: roi.x + roi.width <= m.cols (%d)", roi.x + roi.width <= output.cols);
            NSLog(@"assert: 0 <= roi.y (%d)", 0 <= roi.y);
            NSLog(@"assert: 0 <= roi.height (%d)", 0 <= roi.height);
            NSLog(@"assert: roi.y + roi.height <= m.rows (%d)", roi.y + roi.height <= output.rows);
            
            NSLog(@"before cut");
            Mat(output, roi).copyTo(cropped);
            
            NSLog(@"after cut");
            break;
            
            //output(cv::Rect(y, x, w, h)).copyTo(cropped);
            
        }
        
    }
    
    return cropped;
}

+ (UIImage *) extractMRZ:(UIImage*) image;
{
    // convert to Mat
    Mat origMat = [image CVMat];
    Mat inputMat = origMat.clone();
    Mat croppedMrz = cropMRZArea(inputMat);
    Mat gray;
    cv::cvtColor(croppedMrz, gray, COLOR_BGR2GRAY);
    // prepare for ocr
    gray.convertTo(gray, CV_8UC1);
    cv::threshold(gray, gray, 127, 255, THRESH_BINARY | THRESH_OTSU);
    
    UIImage* result =  [UIImage imageWithCVMat:gray];
    return result;
    /*
    string ocr_output;
    vector<cv::Rect>   boxes;
    vector<string> words;
    vector<float>  confidences;
    
    
    NSString *resourcePath = [NSBundle bundleForClass:G8Tesseract.class].resourcePath;
    NSString *tessdataFolderName = @"tessdata";
    NSString *tessdataFolderPathFromTheBundle = [[resourcePath stringByAppendingPathComponent:tessdataFolderName] stringByAppendingString:@"/"];
    NSString *debugConfigFileName = @"debugConfig.txt";
    NSString *recognitionConfigFileName = @"recognitionConfig.txt";
    NSString *tessConfigsFolderName = @"tessconfigs";
    NSString *debugConfigFilePath = [[tessdataFolderPathFromTheBundle stringByAppendingPathComponent:tessConfigsFolderName]  stringByAppendingPathComponent:debugConfigFileName];
    NSString *recognitionConfigFilePath = [[tessdataFolderPathFromTheBundle stringByAppendingPathComponent:tessConfigsFolderName]  stringByAppendingPathComponent:recognitionConfigFileName];
    
    
    //
    // Initialize the `G8Tesseract` object using the config files
    G8Tesseract *tesseract = [[G8Tesseract alloc] initWithLanguage:@"eng"];
    
    //    G8Tesseract *tesseract = [[G8Tesseract alloc] initWithLanguage:@"eng"];
    tesseract.delegate = self;
    tesseract.charWhitelist = @"0123456789";
    tesseract.image = [[UIImage imageWithCVMat:gray] g8_blackAndWhite];
    [tesseract recognize];
    NSLog(@"%@", [tesseract recognizedText]);
    
    NSLog(@"before result");
    UIImage* result =  [UIImage imageWithCVMat:gray];
    return result;*/
}

@end
