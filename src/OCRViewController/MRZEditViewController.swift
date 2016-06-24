//
//  MRZEditViewController.swift
//  GPUImageOCR
//
//  Created by Mario Scheliga on 6/23/16.
//  Copyright © 2016 Mario Scheliga. All rights reserved.
//

import Foundation
import UIKit

protocol MRZResultDelegate {
    func onMRZResult(result: MRZ)
}

class MRZEditViewController : UIViewController {
    
    @IBOutlet var firstNameTF: UITextField!
    @IBOutlet var dayOfBirthTF: UITextField!
    @IBOutlet var lastNameTF: UITextField!
    
    var mrz: MRZ?
    var resultDelegate: MRZResultDelegate? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.firstNameTF.text = self.mrz!.firstName
        self.lastNameTF.text = self.mrz!.lastName
        //self.dayOfBirthTF.text = self.mrz.dateOfBirth
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "recapture2" {
            (segue.destinationViewController as! CaptureViewController)
        }
    }
    
    @IBAction func closeandSend(sender: AnyObject?) {
        print("close and send back")
        if(self.resultDelegate != nil) {
            self.resultDelegate!.onMRZResult(self.mrz!)
        }
        
    }
    
    @IBAction func recaptureImage(sender: AnyObject?) {
        self.performSegueWithIdentifier("recapture2", sender: nil)
    }
}