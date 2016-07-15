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



class SharedData {
    class var sharedInstance: SharedData {
        struct Static {
            static var instance: SharedData?
            static var token: dispatch_once_t = 0
        }
        
        dispatch_once(&Static.token) {
            Static.instance = SharedData()
        }
        return Static.instance!
    }
    var mainDelegate: OCRResultDelegate? = nil
}

class CaptureViewController: UIViewController, TOCropViewControllerDelegate {
    @IBOutlet var cameraView: DocumentCaptureView!
    @IBOutlet var filterSlider: UISlider!
    
    private var _image: UIImage?
    private var _feature: CIRectangleFeature?
    private var _mrz: MRZ?
    private var _resultText: String?
    
    var resultDelegate: OCRResultDelegate? = nil
    var tesseract:G8Tesseract = G8Tesseract(language: "eng")

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.cameraView.setupCameraView()
        self.cameraView.borderDetectionEnabled = true
        self.cameraView.borderDetectionFrameColor = UIColor(red:0.2, green:0.6, blue:0.86, alpha:0.5)
        //self.cameraView.imageFilter = DocumentCaptureViewImageFilter.BlackAndWhite
    }
    
    override func viewWillAppear(animated: Bool) {
        let shared = SharedData.sharedInstance
        shared.mainDelegate = self.resultDelegate
        
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
            print("showOCR")
            (segue.destinationViewController as! OCRViewController).sourceImage = self._image
        }
        
        if segue.identifier == "showResultText" {
            let showResultVC = (segue.destinationViewController as! ResultViewController)
            
            if(self._mrz != nil) {
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = "MM-dd-yyyy"
                dateFormatter.timeZone = NSTimeZone.localTimeZone()
                var birthdayStr = ""
                
                if(self._mrz!.dateOfBirth != nil) {
                    birthdayStr = dateFormatter.stringFromDate(self._mrz!.dateOfBirth!)
                }
                
                showResultVC.data = [
                  "firstName": self._mrz!.firstName,
                  "lastName": self._mrz!.lastName,
                  "dateOfBirth": birthdayStr
                ]
                
                showResultVC.text = self._mrz!.firstName + " " + self._mrz!.lastName + " (geb. " + birthdayStr + ")"
            } else {
                showResultVC.data = ["text": self._resultText!]
                showResultVC.text = self._resultText!
            }
        }
        
    }
    

    
    //MARK: Actions
    @IBAction func captureImage(sender: AnyObject?) {
        self.cameraView.captureImage { (image, feature) -> Void in
            self._image = image
//            self._image = OCRHelperImplementation.prepareOCR(image)
            self._feature = feature
            
            var cropViewController: TOCropViewController = TOCropViewController.init(image: self._image)
            cropViewController.delegate = self
            self.presentViewController(cropViewController, animated: true, completion: nil)
        }
    }
    
    func cropViewController(cropViewController: TOCropViewController!, didCropToImage image: UIImage!, withRect cropRect: CGRect, angle: Int) {
        //self._image = image;
        self._image = OCRHelperImplementation.prepareOCR(image)
        let result :String = self.recognizeMRZ(self._image!)
        self._resultText = result
        print("scan result", result)
        let mrz = self.parseMRZ(result)
        
        if(mrz == nil) {
            if(result.characters.count > 5) {
                //go to showEditText
                self._resultText = result
                self.presentedViewController?.dismissViewControllerAnimated(true,completion: {
                    print("completed")
                    self.performSegueWithIdentifier("showResultText", sender: nil)
                })
            } else {
                print("Try again quality insufficient!")
                self.presentedViewController?.dismissViewControllerAnimated(true,completion: nil)
            }
            return
        }
        
        if (mrz!.isValid < 0.5) {
            print("Scan quality insufficient : \(mrz!.isValid)")
            self.presentedViewController?.dismissViewControllerAnimated(true,completion: nil)
            return
        }
        
        self._mrz = mrz
        
        self.presentedViewController?.dismissViewControllerAnimated(true,completion: {
            print("completed")
            self.performSegueWithIdentifier("showResultText", sender: nil)
        })
        
    }
    
    private func parseMRZ(text: String) -> MRZ? {
        // Perform OCR
        let mrz = MRZ(scan: text, debug: true)
        print("mrz", mrz)
        if (mrz.isValid < 0.5) {
            print("Scan quality insufficient : \(mrz.isValid)")
            return nil
        }
        print("- birthday", mrz.dateOfBirth)
        print("- firstname", mrz.firstName)
        print("- lastname", mrz.lastName)
        
        return mrz
        // to editMRZ scene only if found - may be stiff editing text instead of not found
        //self.performSegueWithIdentifier("showEditMRZ", sender: nil)
    }
    
    private func recognizeMRZ(image: UIImage) -> String {
        var result:String = ""
        autoreleasepool {
            print("setup tesseract")
            self.tesseract.setVariableValue("0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ<.", forKey: "tessedit_char_whitelist");
            
            self.tesseract.setVariableValue("FALSE", forKey: "x_ht_quality_check")
            //user_words_suffix           user-words
            //user_patterns_suffix        user-patterns
            self.tesseract.setVariableValue("user-words", forKey: "user_words_suffix")
            self.tesseract.setVariableValue("user-patterns", forKey: "user_patterns_suffix")
            
            //Testing OCR optimisations
            self.tesseract.setVariableValue("FALSE", forKey: "load_system_dawg")
            self.tesseract.setVariableValue("FALSE", forKey: "load_freq_dawg")
            self.tesseract.setVariableValue("FALSE", forKey: "load_unambig_dawg")
            self.tesseract.setVariableValue("FALSE", forKey: "load_punc_dawg")
            self.tesseract.setVariableValue("FALSE", forKey: "load_number_dawg")
            self.tesseract.setVariableValue("FALSE", forKey: "load_fixed_length_dawgs")
            self.tesseract.setVariableValue("FALSE", forKey: "load_bigram_dawg")
            self.tesseract.setVariableValue("FALSE", forKey: "wordrec_enable_assoc")
            
            self.tesseract.image = image
            print("- Start recognize")
            self.tesseract.recognize()
            result = self.tesseract.recognizedText

            print("- recognized", result)
            
            //tesseract = nil
            G8Tesseract.clearCache()
        }
        return result
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
    
    @IBAction func filterSliderChanged(sender: AnyObject) {
        print("new filter value", self.filterSlider.value)
        self.cameraView.filterValue = self.filterSlider.value
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