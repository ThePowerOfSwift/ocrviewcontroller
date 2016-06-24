//
//  CameraView.swift
//  GPUImageOCR
//
//  Created by Mario Scheliga on 6/21/16.
//  Copyright © 2016 Mario Scheliga. All rights reserved.
//

import UIKit

protocol OCRResultDelegate {
    func onResult(result: NSDictionary)
}

class CaptureViewController: UIViewController, MRZResultDelegate {
    @IBOutlet var cameraView: DocumentCaptureView!
    
    private var _image: UIImage?
    private var _feature: CIRectangleFeature?
    var resultDelegate: OCRResultDelegate? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.cameraView.setupCameraView()
        self.cameraView.borderDetectionEnabled = true
        self.cameraView.borderDetectionFrameColor = UIColor(red:0.2, green:0.6, blue:0.86, alpha:0.5)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBarHidden = true
        self.cameraView.start()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.cameraView.stop()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        print("prepare for seque")
        if segue.identifier == "showOCR" {
            (segue.destinationViewController as! OCRViewController).sourceImage = self._image
        }
    }
    
    //MARK: Actions
    @IBAction func captureImage(sender: AnyObject?) {
        self.cameraView.captureImage { (image, feature) -> Void in
            self._image = image
            self._feature = feature
            self.performSegueWithIdentifier("showOCR", sender: nil)
        }
    }
    
    @IBAction func abort(sender: AnyObject) {
        if (resultDelegate != nil){
            resultDelegate!.onResult(["status": "aborted"])
        }
    }
    
    @IBAction func toggleTorch(sender: AnyObject?) {
        self.cameraView.torchEnabled = !self.cameraView.torchEnabled
    }
    
    //implement delegates
    func onMRZResult(result: MRZ) {
        if (resultDelegate != nil) {
            resultDelegate!.onResult([
              "status": "success",
              "type": "mrz",
              "data": NSDictionary(dictionary: [
                "firstName": String(result.firstName),
                "lastName": String(result.lastName),
                "dayOfBirth": String(result.dateOfBirth)
              ])
            ])
        }
    }
    
    
}


/*
class ViewController: UIViewController {
    
    @IBOutlet var filterSlider: UISlider!
    @IBOutlet var filterView: GPUImageView!
    
    var timer: NSTimer?
    
    var videoCamera: GPUImageVideoCamera
    var blendImage: GPUImagePicture?
    var context :EAGLContext!
    var _glkView :GLKView
    var _coreImageContext :CIContext
    
    var exposure = GPUImageExposureFilter()
    var highlightShadow = GPUImageHighlightShadowFilter()
    var saturation = GPUImageSaturationFilter()
    var contrast = GPUImageContrastFilter()
    var adaptiveTreshold = GPUImageAdaptiveThresholdFilter()
    var grayfilter = GPUImageGrayscaleFilter()
    var crop = GPUImageCropFilter()
    var averageColor = GPUImageAverageColor()
    let detector = CIDetector(ofType: CIDetectorTypeRectangle, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
    
    var _borderDetectLastRectangleFeature :CIRectangleFeature?
    
    required init(coder aDecoder: NSCoder) {
        videoCamera = GPUImageVideoCamera(sessionPreset: AVCaptureSessionPreset640x480, cameraPosition: .Back)
        videoCamera.outputImageOrientation = .Portrait;
        
        context = EAGLContext.init(API: EAGLRenderingAPI.OpenGLES2)

        
        super.init(coder: aDecoder)!
    }
    
    func createGLKView() {
        if ((self.context) == nil) {
            return
        }
        
        self.context = EAGLContext.init(API: EAGLRenderingAPI.OpenGLES2)
        var view :GLKView = GLKView.init(frame: self.view.bounds)
        view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        view.translatesAutoresizingMaskIntoConstraints = true
        view.context = self.context
        view.contentScaleFactor = 1.0
        view.drawableDepthFormat = GLKViewDrawableDepthFormat.Format24
        self.view.insertSubview(view, atIndex: 0)
        self._glkView = view
        self._coreImageContext = CIContext.init(EAGLContext: self.context, options: [
            kCIContextWorkingColorSpace: NSNull(),
            kCIContextUseSoftwareRenderer: false
            ])
        
    }
    
    func configureView() {
        //self.createGLKView()
        videoCamera.removeAllTargets()
        // Filter settings
        exposure.exposure = 0.6 // -10 - 10
        highlightShadow.highlights  = 0.7 // 0 - 1
        saturation.saturation  = 0.3 // 0 - 2
        contrast.contrast = 3.0  // 0 - 4
        adaptiveTreshold.blurRadiusInPixels = 8.0
        
        // Only use this area for the OCR
        crop.cropRegion = CGRectMake(110.0/1920.0, 350.0/1080.0, 1700.0/1920.0, 350.0/1080 )
        
        // Try to dinamically optimize the exposure based on the average color
        averageColor.colorAverageProcessingFinishedBlock = {(redComponent, greenComponent, blueComponent, alphaComponent, frameTime) in
            let lighting = redComponent + greenComponent + blueComponent
            let currentExposure = self.exposure.exposure
            // The stablil color is between 2.85 and 2.91. Otherwise change the exposure
            if lighting < 2.85 {
                self.exposure.exposure = currentExposure + (2.88 - lighting) * 2
            }
            if lighting > 2.91 {
                self.exposure.exposure = currentExposure - (lighting - 2.88) * 2
            }
        }
        
        // Chaining the filters
        videoCamera.addTarget(exposure)
        exposure.addTarget(highlightShadow)
        highlightShadow.addTarget(grayfilter)
        grayfilter.addTarget(contrast)
        highlightShadow.addTarget(self.filterView)
        
        // Strange! Adding this filter will give a great readable picture, but the OCR won't work.
        // contrast.addTarget(adaptiveTreshold)
        // adaptiveTreshold.addTarget(self.filterView)
        
        // Adding these 2 extra filters to automatically control exposure depending of the average color in the scan area
        contrast.addTarget(crop)
        crop.addTarget(averageColor)
        
        
        //setup first call for scan routine
        self.timer = NSTimer.scheduledTimerWithTimeInterval(0.02, target: self, selector: Selector("scan"), userInfo: nil, repeats: false)
        
        self.startScan()
    }
    
    public func startScan() {
        self.videoCamera.startCameraCapture()
        self.createGLKView()
    }
    
    public func stopScan() {
        self.videoCamera.stopCameraCapture()
    }
    
    public func abbortScan() {
        
    }
    
    public func scan() {
        print("start scan")
        self.timer?.invalidate()
        self.timer = nil
        
        
        NSOperationQueue.mainQueue().addOperationWithBlock({
            let filterConfig = self.contrast
            filterConfig.useNextFrameForImageCapture()
            let snapshot = filterConfig.imageFromCurrentFramebuffer()
            if(snapshot == nil) {
                print("- couldnt get  snapshot from camera")
                return;
            }
            print("- continue with image snapshot")
            
            var image :CIImage = CIImage(image: snapshot)!
            self._borderDetectLastRectangleFeature = self.biggestRectangleInRectangles(self.detector.featuresInImage(image) as! [CIRectangleFeature])
            if((self._borderDetectLastRectangleFeature) != nil) {
                image = self.drawHighlightOverlayForPoints(image,
                    topLeft: self._borderDetectLastRectangleFeature!.topLeft,
                    topRight: self._borderDetectLastRectangleFeature!.topRight,
                    bottomLeft: self._borderDetectLastRectangleFeature!.bottomLeft,
                    bottomRight: self._borderDetectLastRectangleFeature!.bottomRight)
            }
            
            if((self.context) != nil && self._coreImageContext != NSNull()) {
                if(self.context != EAGLContext.currentContext()) {
                    
                }
                self._glkView.bindDrawable()
                self._coreImageContext.drawImage(image, inRect: self.view.bounds, fromRect: image.extent)
                self._glkView.display()
                // image = NSNull()
            }
            
            self.startScan()
            
        })
        
        
    }
    
    func drawHighlightOverlayForPoints(image: CIImage, topLeft :CGPoint, topRight :CGPoint, bottomLeft :CGPoint, bottomRight :CGPoint) -> CIImage {
        
        print("- draw highlight overlay")
        var overlay :CIImage = CIImage.init(color: CIColor.init(red: 1, green: 0, blue: 0, alpha: 0.6))
        overlay = overlay.imageByCroppingToRect(image.extent)
        overlay = overlay.imageByApplyingFilter("CIPerspectiveTransformWithExtent",
                                                withInputParameters: [
                                                    "inputExtent": CIVector(CGRect: image.extent),
                                                    "inputTopLeft": CIVector(CGPoint: topLeft),
                                                    "inputTopRight": CIVector(CGPoint: topRight),
                                                    "inputBottomLeft": CIVector(CGPoint: bottomLeft),
                                                    "inputBottomRight": CIVector(CGPoint: bottomRight)
            ])
        
        
        return overlay.imageByCompositingOverImage(image);
    }
    
    func biggestRectangleInRectangles(rectangles: [CIRectangleFeature]) -> CIRectangleFeature? {
        print("- search biggest rectangle: ", rectangles.count)
        if(rectangles.count == 0) {
            return nil
        }
        
        var halfPerimiterValue :CGFloat = 0.0
        var biggestRectangle :CIRectangleFeature = rectangles.first!
        for rect :CIRectangleFeature in rectangles {
            let p1 :CGPoint = rect.topLeft
            let p2 :CGPoint = rect.topRight
            let width :CGFloat = hypot(p1.x - p2.x, p1.y - p2.y)
            
            let p3 :CGPoint = rect.topLeft
            let p4 :CGPoint = rect.bottomLeft
            let height :CGFloat = hypot(p3.x - p4.x, p3.y - p4.y)
            
            let currentHalfPerimiterValue :CGFloat = height + width
            if(halfPerimiterValue < currentHalfPerimiterValue) {
                halfPerimiterValue = currentHalfPerimiterValue
                biggestRectangle = rect
            }
        }
        return biggestRectangle
    }
    
    @IBAction func updateSliderValue() {
        print("self.filterSlider!.value:", self.filterSlider!.value)
        self.configureView()
    }
    
    func setupCameraView() {
        videoCamera = GPUImageVideoCamera(sessionPreset: AVCaptureSessionPreset640x480, cameraPosition: .Back)
        self.configureView()
        videoCamera.startCameraCapture()
        
    }
    
    
}

 
 */