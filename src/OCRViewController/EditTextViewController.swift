//
//  MRZEditViewController.swift
//  GPUImageOCR
//
//  Created by Mario Scheliga on 6/23/16.
//  Copyright © 2016 Mario Scheliga. All rights reserved.
//

import Foundation
import UIKit

class EditTextViewController : UIViewController {
    
    @IBOutlet var textTF: UITextField!
    var text: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.textTF.text = self.text
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    @IBAction func closeandSend(sender: AnyObject?) {
        print("close and send back")
        let shared = SharedData.sharedInstance
        if(shared.mainDelegate != nil) {
            shared.mainDelegate?.onResult([
                "text": self.textTF.text!
                ])
        }
    }
    
    @IBAction func recaptureImage(sender: AnyObject?) {
        self.performSegueWithIdentifier("showRecapture", sender: nil)
    }
}