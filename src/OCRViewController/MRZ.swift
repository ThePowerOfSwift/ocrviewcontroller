//
//  MRZ.swift
//  PassportScanner
//
//  Created by Edwin Vermeer on 12/5/14.
//  Copyright (c) 2015. All rights reserved.
//

import Foundation

public class MRZ:NSObject {
    // check data with http://en.wikipedia.org/wiki/Machine-readable_passport
    
    public var isValid : Float = 0             // A value of 1 is for when all validations are OK
    private var debug = false                  // Set to true (see init) to see what's going on
    
    
    // MRZ type see: http://www.icao.int/publications/pages/publication.aspx?docnum=9303 for more
    public var mrzType: String = ""            // could be td-1, td-2, td-3
    
    public var documentType : String = ""
    public var documentSubType : String = ""
    public var countryCode : String = ""
    public var lastName : String = ""
    public var firstName : String = ""
    public var passportNumber : String = ""
    private var passportNumberIsValid = false
    public var nationality : String = ""
    public var dateOfBirth : NSDate?
    private var dateOfBirthIsValid = false
    public var sex : String = ""
    public var expirationDate : NSDate?
    private var expirationDateIsValid = false
    public var personalNumber : String = ""
    private var personalNumberIsValid = false
    private var dataIsValid = false
    
    
    /**
     Convenience method for getting all data in a dictionary
     
     :returns: Return all fields in a dictionary
     */
    public func data() -> Dictionary<String, AnyObject> {
        return ["documentType":documentType, "documentSubType":documentSubType, "countryCode":countryCode, "lastName":lastName, "firstName":firstName, "passportNumber":passportNumber, "nationality":nationality, "dateOfBirth":MRZ.stringFromDate(dateOfBirth), "sex":sex, "expirationDate":MRZ.stringFromDate(expirationDate), "personalNumber":personalNumber]
    }
    
    /**
     Get the discription of the MRZ
     
     :returns: a string with all fields plus fieldname (each field on a new line)
     */
    public override var description: String {
        get {
            return self.data().map {"\($0) = \($1)"}.reduce("") {"\($0)\n\($1)"}
        }
    }
    
    /**
     Initiate the MRZ object with the scanned data.
     
     :param: scan  the scanned string
     :param: debug true if you want to see debug messages.
     
     :returns: Instance of MRZ
     */
    public init(scan:String, debug:Bool = false) {
        super.init()
        print("scan", scan)
        self.debug = debug
        let lines:[String] = scan.characters.split(isSeparator: {$0 == "\n"}).map({String($0)})
        var longLines:[String] = []
        var longestLine = 0
        for line in lines {
            let cleaned = line.replace(" ", withString: "")
            if (longestLine < cleaned.characters.count) {
                longestLine = cleaned.characters.count
            }
            print("cleaned", cleaned.characters.count)
            if cleaned.characters.count > 28 {
                longLines.append(line)
            }
        }
        
        // nothing to parse here
        if (longLines.count < 2) {
            return
        }
        // choosed smaller amount of characters per type by intention here
        if (longLines.count == 2 && longestLine > 38) {
            self.mrzType = "td-3"
            self.processTD3(longLines[0], l2: longLines[1])
            
        } else if (longLines.count == 2 && longestLine > 28) {
            self.mrzType = "td-2"
            self.processTD3(longLines[0], l2: longLines[1])
            
        } else if (longLines.count == 3 && longestLine > 25) {
            self.mrzType = "td-1"
            processTD1(longLines[0], l2: longLines[1], l3: longLines[2])
        } else {
            // unprocessable
            return
        }
        
        
        
    }
    
    /**
     Do you want to see the progress in the log
     
     :param: line The data that will be loged
     */
    private func debugLog(line:String) {
        if debug {
            print(line)
        }
    }
    
    
    /**
     Process the 2 MRZ lines
     
     :param: l1 First line
     :param: l2 Second line
     */
    private func processTD3(l1:String, l2:String) {
        
        let line1 = MRZ.cleanup(l1)
        let line2 = MRZ.cleanup(l2)
        
        debugLog("Processing line 1 : \(line1)")
        debugLog("Processing line 2 : \(line2)")
        
        // Line 1 parsing
        documentType = line1.subString(0, to: 0)
        debugLog("Document type : \(documentType)")
        documentSubType = line1.subString(1, to: 1)
        countryCode = line1.subString(2, to: 4).replace("<", withString: " ")
        let name = line1.subString(5, to: 43).replace("0", withString: "O")
        var nameArray = name.componentsSeparatedByString("<<")
        lastName = nameArray[0].replace("<", withString: " ").capitalizedStringWithLocale(NSLocale.currentLocale())
        debugLog("Lastname : \(lastName)")
        firstName = nameArray.count > 1 ? nameArray[1].replace("<", withString: " ").capitalizedStringWithLocale(NSLocale.currentLocale()) : ""
        debugLog("Firstname : \(firstName)")
        
        // Line 2 parsing
        passportNumber = line2.subString(0, to: 8)
        debugLog("passportNumber : \(passportNumber)")
        let passportNumberCheck = line2.subString(9, to: 9)
        nationality = line2.subString(10, to: 12).replace("<", withString: " ")
        debugLog("nationality : \(nationality)")
        let birth = line2.subString(13, to: 18).replace("O", withString: "0")
        debugLog("date of birth : \(birth)")
        let birthValidation = line2.subString(19, to: 19).replace("O", withString: "0")
        dateOfBirth = MRZ.dateFromString(birth)
        sex = line2.subString(20, to: 20)
        let expiration = line2.subString(21, to: 26).replace("O", withString: "0")
        debugLog("date of expiration : \(expiration)")
        expirationDate = MRZ.dateFromString(expiration)
        let expirationValidation = line2.subString(27, to: 27).replace("O", withString: "0")
        personalNumber =  line2.subString(28, to: 41).replace("O", withString: "0")
        debugLog("personal number : \(personalNumber)")
        let personalNumberValidation = line2.subString(42, to: 42).replace("O", withString: "0")
        let data = "\(passportNumber)\(passportNumberCheck)\(birth)\(birthValidation)\(expiration)\(expirationValidation)\(personalNumber)\(personalNumberValidation)"
        let dataValidation = line2.subString(43, to: 43).replace("O", withString: "0")
        
        // Validation
        isValid = 1
        passportNumberIsValid = MRZ.validate(passportNumber, check: passportNumberCheck)
        isValid = isValid * (passportNumberIsValid ? 1 : 0.9)
        dateOfBirthIsValid = MRZ.validate(birth, check: birthValidation)
        isValid = isValid * (dateOfBirthIsValid ? 1 : 0.9)
        isValid = isValid * (MRZ.validate(expiration, check: expirationValidation) ? 1 : 0.9)
        personalNumberIsValid = MRZ.validate(personalNumber, check: personalNumberValidation)
        isValid = isValid * (personalNumberIsValid ? 1 : 0.9)
        dataIsValid = MRZ.validate(data, check: dataValidation)
        isValid = isValid * (dataIsValid ? 1 : 0.9)
        
        // Final cleaning up
        documentSubType = documentSubType.replace("<", withString: "")
        personalNumber = personalNumber.replace("<", withString: "")
    }
    
    /**
     Process the 3 MRZ lines (for id document types)
     
     :param: l1 First line
     :param: l2 Second line
     :param: l3 thrid line
     */
    private func processTD1(l1:String, l2:String, l3: String) {
        print("couldn' call?")
        
        
        
        let line1 = MRZ.cleanup(l1)
        let line2 = MRZ.cleanup(l2)
        let line3 = MRZ.cleanup(l3)
        
        debugLog("Processing line 1 : \(line1)")
        debugLog("Processing line 2 : \(line2)")
        debugLog("Processing line 3 : \(line3)")
        
        // Line 1 parsing
        documentType = line1.subString(0, to: 0)
        debugLog("Document type : \(documentType)")
        documentSubType = line1.subString(1, to: 1)
        countryCode = line1.subString(2, to: 4).replace("<", withString: " ")
        passportNumber = line1.subString(5, to: 13)
        debugLog("passportNumber : \(passportNumber)")
        let passportNumberCheck = line1.subString(14, to: 14)
        
        
        
        // Line 2 parsing
        let birth = line2.subString(0, to: 5).replace("O", withString: "0").replace("o", withString: "0")
        
        debugLog("date of birth : \(birth)")
        let birthValidation = line2.subString(6, to: 6).replace("O", withString: "0").replace("o", withString: "0")
        dateOfBirth = MRZ.dateFromString(birth)
        sex = line2.subString(7, to: 7)
        let expiration = line2.subString(8, to: 13).replace("O", withString: "0").replace("o", withString: "0")
        debugLog("date of expiration : \(expiration)")
        expirationDate = MRZ.dateFromString(expiration)
        let expirationValidation = line2.subString(14, to: 14).replace("O", withString: "0").replace("o", withString: "0")
        
        nationality = line2.subString(15, to: 17).replace("<", withString: " ")
        debugLog("nationality : \(nationality)")
        
        
        // line 3 parsing
        let name = line3.subString(0, to: 29).replace("0", withString: "O")
        var nameArray = name.componentsSeparatedByString("<<")
        lastName = nameArray[0].replace("<", withString: " ").capitalizedStringWithLocale(NSLocale.currentLocale())
        debugLog("Lastname : \(lastName)")
        firstName = nameArray.count > 1 ? nameArray[1].replace("<", withString: " ").capitalizedStringWithLocale(NSLocale.currentLocale()) : ""
        debugLog("Firstname : \(firstName)")
        
        
        
        // Validation
        isValid = 1
        passportNumberIsValid = MRZ.validate(passportNumber, check: passportNumberCheck)
        isValid = isValid * (passportNumberIsValid ? 1 : 0.9)
        dateOfBirthIsValid = MRZ.validate(birth, check: birthValidation)
        isValid = isValid * (dateOfBirthIsValid ? 1 : 0.9)
        isValid = isValid * (MRZ.validate(expiration, check: expirationValidation) ? 1 : 0.9)
        isValid = isValid * (personalNumberIsValid ? 1 : 0.9)
        isValid = isValid * (dataIsValid ? 1 : 0.9)
        
        // Final cleaning up
        documentSubType = documentSubType.replace("<", withString: "")
    }
    
    /**
     Cleanup a line of text
     
     :param: line The line that needs to be cleaned up
     :returns: Returns the cleaned up text
     */
    private class func cleanup(line:String) -> String {
        var t = line.componentsSeparatedByString(" ")
        if t.count > 1 {
            // are there extra characters added
            for p in t {
                if p.characters.count == 44 {
                    return p
                }
            }
            // was there one or more extra space added
            if "\(t[0])\(t[1])".characters.count == 44 {
                return "\(t[0])\(t[1])"
            } else if  "\(t[t.count-2])\(t[t.count-1])".characters.count == 44 {
                return "\(t[t.count-2])\(t[t.count-1])"
            } else {
                return line.replace(" ", withString: "")
            }
        }
        return line // assume the garbage characters are at the end
    }
    
    /**
     Create a date from a string
     
     :param: value The string value that needs to be converted to a date
     
     :returns: Returns the date value for the string
     */
    private class func dateFromString(value:String) -> NSDate? {
        var date : NSDate?
        let dateStringFormatter = NSDateFormatter()
        dateStringFormatter.dateFormat = "YYMMdd"
        dateStringFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        let d = dateStringFormatter.dateFromString(value)
        if d != nil {
            date = NSDate(timeInterval:0, sinceDate:d!)
        }
        return date
    }
    
    /**
     Create a string from a date
     
     :param: value The Date value that needs to be converted to a string
     
     :returns: Returns the string value for the date
     */
    private class func stringFromDate(value:NSDate?) -> String {
        if value == nil {
            return ""
        }
        let formatter = NSDateFormatter()
        formatter.dateFormat = "YYMMdd"
        formatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        return formatter.stringFromDate(value!) ?? ""
    }
    
    /**
     MRZ data validation function
     
     :param: data The data that needs to be validated
     :param: check The checksum string for the validation
     
     :returns: Returns true if the data was valid
     */
    private class func validate(data : String, check : String) -> Bool {
        // The check digit calculation is as follows: each position is assigned a value; for the digits 0 to 9 this is the value of the digits, for the letters A to Z this is 10 to 35, for the filler < this is 0. The value of each position is then multiplied by its weight; the weight of the first position is 7, of the second it is 3, and of the third it is 1, and after that the weights repeat 7, 3, 1, etcetera. All values are added together and the remainder of the final value divided by 10 is the check digit.
        
        //debugLog("Check '\(data)' for check '\(check)'")
        var i:Int = 1
        var dc : Int = 0
        var w:[Int] = [7,3,1]
        let b0:UInt8 = Array("0".utf8)[0]
        let b9:UInt8 = Array("9".utf8)[0]
        let bA:UInt8 = Array("A".utf8)[0]
        let bZ:UInt8 = Array("Z".utf8)[0]
        let bK:UInt8 = Array("<".utf8)[0]
        for c in Array(data.utf8) {
            var d:Int = 0
            if c >= b0 && c <= b9 {
                d = Int(c - b0)
            } else if c >= bA && c <= bZ {
                d = Int((10 + c) - bA)
            } else if c != bK {
                return false
            }
            dc = dc + d * w[(i-1)%3]
            //NSLog("i = \(i)   c = \(c)   d = \(d)   w = \(w[(i-1)%3])   dc = \(dc)")
            i++
        }
        if dc%10 != Int(check) {
            return false
        }
        //NSLog("Item was valid")
        return true;
    }
    
}


extension String
{
    /**
     Simple string extension for performing a replace
     
     :param: target     search this text
     :param: withString the text you want to replace it with
     
     :returns: the string with the replacements.
     */
    func replace(target: String, withString: String) -> String
    {
        return self.stringByReplacingOccurrencesOfString(target, withString: withString, options: NSStringCompareOptions.LiteralSearch, range: nil)
    }
    
    /**
     Get a substring
     
     :param: s    the string value
     :param: from from which character
     :param: to   to what character
     
     :returns: Return the substring
     */
    private func subString(from:Int, to:Int) -> String {
        var xfrom = from
        var xto = to
        if(self.characters.count < xto+1) {
            xto = self.characters.count - 1
        }
        if(self.characters.count < xfrom ) {
            xfrom = 0
        }
        return self.substringWithRange(Range<String.Index>(start: self.startIndex.advancedBy(xfrom), end: self.startIndex.advancedBy(xto+1)))
    }
}

