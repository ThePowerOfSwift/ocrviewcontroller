//
//  MRZEditViewController.swift
//  GPUImageOCR
//
//  Created by Mario Scheliga on 6/23/16.
//  Copyright © 2016 Mario Scheliga. All rights reserved.
//

import Foundation
import UIKit

class ResultViewController : UIViewController {
    
    @IBOutlet var resultLabel: UILabel!
    @IBOutlet var textTF: UITextField!
    
    var data: NSDictionary = [:]
    var text: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.resultLabel.text = self.text
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    @IBAction func closeandSend(sender: AnyObject?) {
        print("close and send back")
        print("data?", self.data)
        let shared = SharedData.sharedInstance
        if(shared.mainDelegate != nil) {
            shared.mainDelegate?.onResult(self.data)
        }
    }
    
    @IBAction func recaptureImage(sender: AnyObject?) {
        self.performSegueWithIdentifier("showRecapture", sender: nil)
    }
}