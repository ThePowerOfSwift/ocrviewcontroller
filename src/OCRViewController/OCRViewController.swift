//
//  OCRViewController.swift
//  GPUImageOCR
//
//  Created by Mario Scheliga on 6/22/16.
//  Copyright © 2016 Mario Scheliga. All rights reserved.
//

import Foundation
import UIKit
import TesseractOCR

extension UIImage {
    public func imageRotatedByDegrees(degrees: CGFloat, flip: Bool) -> UIImage {
        let radiansToDegrees: (CGFloat) -> CGFloat = {
            return $0 * (180.0 / CGFloat(M_PI))
        }
        let degreesToRadians: (CGFloat) -> CGFloat = {
            return $0 / 180.0 * CGFloat(M_PI)
        }
        
        // calculate the size of the rotated view's containing box for our drawing space
        let rotatedViewBox = UIView(frame: CGRect(origin: CGPointZero, size: size))
        let t = CGAffineTransformMakeRotation(degreesToRadians(degrees));
        rotatedViewBox.transform = t
        let rotatedSize = rotatedViewBox.frame.size
        
        // Create the bitmap context
        UIGraphicsBeginImageContext(rotatedSize)
        let bitmap = UIGraphicsGetCurrentContext()
        
        // Move the origin to the middle of the image so we will rotate and scale around the center.
        CGContextTranslateCTM(bitmap, rotatedSize.width / 2.0, rotatedSize.height / 2.0);
        
        //   // Rotate the image context
        CGContextRotateCTM(bitmap, degreesToRadians(degrees));
        
        // Now, draw the rotated/scaled image into the context
        var yFlip: CGFloat
        
        if(flip){
            yFlip = CGFloat(-1.0)
        } else {
            yFlip = CGFloat(1.0)
        }
        
        CGContextScaleCTM(bitmap, yFlip, -1.0)
        CGContextDrawImage(bitmap, CGRectMake(-size.width / 2, -size.height / 2, size.width, size.height), CGImage)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}

class OCRViewController : UIViewController {

    @IBOutlet var capturedView: UIImageView!
    @IBOutlet var resultLabel: UILabel!
    
    var sourceImage: UIImage?
    /// The tesseract OCX engine
    var tesseract:G8Tesseract = G8Tesseract(language: "eng")
    
    var mrz: MRZ?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.capturedView.contentMode = .ScaleAspectFit
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.capturedView.image = self.sourceImage
        print("capture dim(width,height):", self.sourceImage?.size.width, self.sourceImage?.size.height)
        
    }
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "recapture" {
                (segue.destinationViewController as! CaptureViewController)
        }
        if segue.identifier == "showEditMRZ" {
            (segue.destinationViewController as! MRZEditViewController).mrz = self.mrz
        }
    }
    
    private func updateDisplay() {
        self.capturedView.image = self.sourceImage
    }
    
    private func parseMRZ(text: String) {
        // Perform OCR
        self.mrz = MRZ(scan: text, debug: true)
        if (self.mrz!.isValid < 0.5) {
            print("Scan quality insufficient : \(mrz!.isValid)")
            return
        }
        print("- birthday", self.mrz!.dateOfBirth)
        print("- firstname", self.mrz!.firstName)
        print("- lastname", self.mrz!.lastName)
        
        // to editMRZ scene only if found - may be stiff editing text instead of not found
        self.performSegueWithIdentifier("showEditMRZ", sender: nil)
    }
    
    
    //MARK: Actions
    @IBAction private func cropMRZ() {
        self.sourceImage = OCRHelper.extractMRZ(self.sourceImage!)
        self.updateDisplay()
    }
    
    @IBAction private func rotateClockwise() {
        self.sourceImage = sourceImage?.imageRotatedByDegrees(90, flip: false)
        self.updateDisplay()
    }
    
    @IBAction private func recognize() {
        var result:String?
        autoreleasepool {
            print("setup tesseract")
            self.tesseract.setVariableValue("0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ<", forKey: "tessedit_char_whitelist");
            
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
        
            self.tesseract.image = self.sourceImage
            print("- Start recognize")
            self.tesseract.recognize()
            result = self.tesseract.recognizedText
            self.resultLabel.text = result
            self.parseMRZ(result!)
            print("- recognized", result)
            
            //tesseract = nil
            G8Tesseract.clearCache()
        }
    }
    
    @IBAction func recaptureImage(sender: AnyObject?) {
        self.performSegueWithIdentifier("recapture", sender: nil)
    }
}