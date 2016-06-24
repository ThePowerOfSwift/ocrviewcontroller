import Foundation
import UIKit

func JSONStringify(value: AnyObject,prettyPrinted:Bool = false) -> String{
    
    let options = prettyPrinted ? NSJSONWritingOptions.PrettyPrinted : NSJSONWritingOptions(rawValue: 0)
    
    
    if NSJSONSerialization.isValidJSONObject(value) {
        
        do{
            let data = try NSJSONSerialization.dataWithJSONObject(value, options: options)
            if let string = NSString(data: data, encoding: NSUTF8StringEncoding) {
                return string as String
            }
        }catch {
            
            print("error")
            //Access error here
        }
        
    }
    return ""
    
}

@objc(OCRViewCDVPlugin) class OCRViewCDVPlugin : CDVPlugin, OCRResultDelegate {
    
    var command: CDVInvokedUrlCommand? = nil
    
    func onResult(res: NSDictionary) {
        print("GOT RESULT", res)
        let msg: String = JSONStringify(res)
        let pluginResult = CDVPluginResult(
            status: CDVCommandStatus_OK,
            messageAsString: msg
        )
        
        self.commandDelegate!.sendPluginResult(
            pluginResult,
            callbackId: self.command!.callbackId
        )
        //close
        self.viewController.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func scan(command: CDVInvokedUrlCommand) {
        self.command = command
        var pluginResult = CDVPluginResult(
            status: CDVCommandStatus_ERROR
        )

        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let scanVC: CaptureViewController = storyboard.instantiateViewControllerWithIdentifier("CaptureViewController") as! CaptureViewController
        self.viewController?.presentViewController(scanVC, animated: true, completion: nil)
        
        scanVC.resultDelegate = self

    }
}
