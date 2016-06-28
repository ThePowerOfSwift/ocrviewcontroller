//
//  MRZEditViewController.swift
//  GPUImageOCR
//
//  Created by Mario Scheliga on 6/23/16.
//  Copyright © 2016 Mario Scheliga. All rights reserved.
//

import Foundation
import UIKit

class MRZEditViewController : UIViewController {
    
    @IBOutlet var firstNameTF: UITextField!
    @IBOutlet var dayOfBirthTF: UITextField!
    @IBOutlet var lastNameTF: UITextField!
    
    var mrz: MRZ?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.firstNameTF.text = self.mrz!.firstName
        self.lastNameTF.text = self.mrz!.lastName
        self.dayOfBirthTF.text = self.mrz!.dateOfBirth?.description
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
        let shared = SharedData.sharedInstance
        if(shared.mainDelegate != nil) {
            shared.mainDelegate?.onResult([
                "firstName": self.mrz!.firstName,
                "lastName": self.mrz!.lastName,
                "dateOfBirth": self.mrz!.dateOfBirth!.description
            ])
        }
    }
    
    @IBAction func recaptureImage(sender: AnyObject?) {
        self.performSegueWithIdentifier("recapture2", sender: nil)
    }
}