//
//  main.swift
//
//  Created by John Singer on 7/13/17.
//  Copyright © 2017 John Singer. All rights reserved.
//
// This was originally written as a learning-experience task, intended to get/push info to/from Casper/JSS

import SwiftyJSON
import Foundation
import Just

enum jssRestFunction: String {
    case computers
    case mobiledevices
    case computerrecord
    case computergroups
    case removecomputerfromgroup
    case addcomputertogroup
    case createplaceholder
}

let pattern = "g:s:a:u:p:"
let jssUrl = "https://casper.csueastbay.edu:8443/JSSResource/"

var jssGroupName: String
var textField: String

// Usage: QueryCasper -a json_authorization_file.txt -p sub_url -g group -s serialnumber or
//        QueryCasper -u username:password -p sub_url
// NOTE: -a & -u are mutually-exclusive

class JSS {
    
    private var baseJssUrl: String
    private var jssUsername: String = ""
    private var jssPassword: String = ""

    private var aFlag = false
    private var aVal: String?
    private var uFlag = false
    private var uValue: String?
    private var sFlag = false
    var sValue: String?
    private var pFlag = false
    var pValue: String?
    private var gFlag = false
    var gValue: String?

    init?(serverURL: String = jssUrl, ac: Int32, av: UnsafePointer<UnsafeMutablePointer<Int8>?>!) {
//  init(serverURL: String = jssUrl, jamfUsername: String, jamfPassword: String) {
        self.baseJssUrl = serverURL
//        self.auth = "\(jamfUsername):\(jamfPassword)".dataUsingEncoding(NSUTF8StringEncoding)!.base64EncodedStringWithOptions(NSData.Base64EncodingOptions.Encoding64CharacterLineLength)

    while case let option = getopt(CommandLine.argc, CommandLine.unsafeArgv, pattern), option != -1 {
        switch UnicodeScalar(CUnsignedChar(option)) {
        case "u":
            uFlag = true
            uValue = String(cString: optarg)
            
        case "a":
            aFlag = true
            aVal = String(cString: optarg)
            
        case "p":
            pFlag = true
            pValue = String(cString: optarg)
    
        case "g":
            gFlag = true
            gValue = String(cString: optarg)
    
        case "s":
            sFlag = true
            sValue = String(cString: optarg)
    
        default:
    //        fatalError("Unknown option")
            print("Unknown Option: \(CommandLine.arguments[0])")
            exit(EXIT_FAILURE)
        }
    }

    // the following is the same thing as a logical XOR
    guard  uFlag != aFlag else {
        print("-u or -a, Either command-line flag option may be used; not both")
        exit(EXIT_FAILURE)
    }
    print("aFlag = \(aFlag) and aValue = ", aVal ?? "?")
    print("uFlag = \(uFlag) and uValue = ", uValue ?? "?", "\n")
    print("pFlag = \(pFlag) and pValue = ", pValue ?? "?", "\n")
    
    // Now, if the fFlag is set, we've gotten our parameter file from the command-line, so we'll try to read it, parse, it and
    //    use it to access JAMF.
    if self.aFlag {
        do {
            let filedata = try String(contentsOfFile: self.aVal!, encoding: String.Encoding.utf8)
    
            if let authProps = filedata.data(using: String.Encoding.utf8, allowLossyConversion: false) {
                let json = JSON(data: authProps)

               self.jssUsername = json["username"].string ?? ""
               self.jssPassword = json["password"].string ?? ""
               return
        }
        } catch {
            print(error)
        }
        
//        } catch e: NSError {
//            print("Error reading init-file: \(e)")
//        }
    }
    
    
        }
    
    func getComputerRecord(subPath: String, serialNumber: String) {
        
        let computersUrl: String = self.baseJssUrl + "computers/match/\(serialNumber)"
        let getResult = Just.get(computersUrl, headers: ["accept":"application/json"], auth: (self.jssUsername,self.jssPassword))
        if (getResult.ok) {
            // Success Function
            print("GET Status: \(getResult.statusCode!)")
        }
        else {
            print("Unable to connect to your JSS!", "Please check that the JSS URL, username and password are correct and then try your request again.")
        } // Close Else

        // Try JSON extraction, looking for dictionary at 'computers' index; then loop through all elements...
        let resultText = getResult.text!.data(using: String.Encoding.utf8)!
        //    do {
        if let json = try? JSONSerialization.jsonObject(with: resultText) as? [String:Any],
           let computers = json?["computers"] as? [[String:Any]] {

            let loopCount: Int = computers.count
            for index in 0 ..< loopCount {
                print(computers[index])
            }
        } else {
            print("bad json - do some recovery")
        }
// } catch error as NSError { }
    }


    func createPlaceholder(subPath: String, serialNumber: String, macAddress: String) {
        let xml = "<computer>" +
                    "<general>" +
                        "<name>Placeholder-\(serialNumber)</name>" +
                        "<serial_number>\(serialNumber)</serial_number>" +
                        "<mac_address>\(macAddress)</mac_address>" +
                    "</general>" +
                "</computer>"
        
        let createUrl = self.baseJssUrl + "/computers/id/0\(serialNumber)"
        let xPayload = xml.data(using: String.Encoding.utf8, allowLossyConversion: true)
//        let xPayload = xml.dataUsingEncoding(dataUsingEncoding: String.Encoding.utf8)
        let postResult = Just.post(createUrl,
                headers: ["accept":"application/xml"],
                auth: (self.jssUsername,self.jssPassword),
               requestBody: xPayload)
        
        if (postResult.ok) {
            // Success Function
            print("POST Status: \(postResult.statusCode!)")
        }
        
        let computersUrl: String = self.baseJssUrl + "/computers/match/" + serialNumber
        let getResult = Just.get(computersUrl, headers: ["accept":"application/xml"],
                auth: (self.jssUsername,self.jssPassword))
        if (getResult.ok) {
            // Success Function
            print("GET Status: \(getResult.statusCode!)")

        }
        else {
            print("Unable to connect to your JSS!", "Please check that the JSS URL, username and password are correct and then try your request again.")
        } // Close Else

        // Try JSON extraction, looking for dictionary at 'computers' index; then loop through all elements...
        let resultText = getResult.text!.data(using: String.Encoding.utf8)!
        //    do {
        if let json = try? JSONSerialization.jsonObject(with: resultText) as? [String:Any],
           let computers = json?["computers"] as? [[String:Any]] {

            let loopCount: Int = computers.count
            for index in 0 ..< loopCount {
                print(computers[index])
            }
        } else {
            print("bad json - do some recovery")
        }
// } catch error as NSError { }
    }

    func addComputerToGroup(subPath: String, serialNumber: String, groupName: String) {
        let xml = "<computer_group>" +
                    "<computer_additions>" +
                        "<computer>" +
                            "<serial_number>\(serialNumber)</serial_number>" +
                        "</computer>" +
                    "</computer_additions>" +
                "</computer_group>"
        
//        let urlEncodedGroupName = groupName.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!
        
        let groupsUrl: String = self.baseJssUrl + "/computergroups/name/\(groupName)"
        let postResult = Just.post(groupsUrl,
                                   headers: ["accept":"application/xml"],
                                   auth: (self.jssUsername, self.jssPassword),
                requestBody: (xml.data(using: String.Encoding.utf8, allowLossyConversion: true))
)

        if (postResult.ok) {
            // Success Function
            print("GET Status: \(postResult.statusCode!)")

        }
        else {
            print("Unable to connect to your JSS!", "Please check that the JSS URL, username and password are correct and then try your request again.")
        } // Close Else

        // Try JSON extraction, looking for dictionary at 'computers' index; then loop through all elements...
        let resultText = postResult.text!.data(using: String.Encoding.utf8)!
        if let json = try? JSONSerialization.jsonObject(with: resultText) as? [String:Any],
           let groups = json?["mobile_devices"] as? [[String:Any]] {

            let loopCount: Int = groups.count
            for index in 0 ..< loopCount {
                print(groups[index])
            }
        } else {
            print("bad json - do some recovery")
        }
    }
    
    func removeComputerFromGroup(subPath: String, serialNumber: String, groupName: String) {
        let xml = "<computer_group>" +
                    "<computer_deletions>" +
                        "<computer>" +
                            "<serial_number>\(serialNumber)</serial_number>" +
                        "</computer>" +
                    "</computer_deletions>" +
                "</computer_group>"
        
        let removeUrl: String = self.baseJssUrl + "/computergroups/name/\(groupName)"
        print("The removeURL is: \(removeUrl)")
        
        let xmlData = xml.data(using: String.Encoding.utf8, allowLossyConversion: true)

        let groupsUrl: String = jssUrl + subPath
        let postResult = Just.post(groupsUrl,
                headers: ["accept":"application/xml"],
                auth: (self.jssUsername, self.jssPassword),
                requestBody: xmlData)

        if (postResult.ok) {
            // Success Function
            print("GET Status: \(postResult.statusCode!)")

        }
        else {
            print("Unable to connect to your JSS!", "Please check that the JSS URL, username and password are correct and then try your request again.")
        } // Close Else

        // Try JSON extraction, looking for dictionary at 'computers' index; then loop through all elements...
        let resultText = postResult.text!.data(using: String.Encoding.utf8)!
        if let json = try? JSONSerialization.jsonObject(with: resultText) as? [String:Any],
           let groups = json?["mobile_devices"] as? [[String:Any]] {

            let loopCount: Int = groups.count
            for index in 0 ..< loopCount {
                print(groups[index])
            }
        } else {
            print("bad json - do some recovery")
        }
    }
    
    func getComputerGroups(subPath: String) {
        
        let groupsUrl: String = jssUrl + subPath
        let getResult = Just.get(groupsUrl, headers: ["accept":"application/json"],
                auth: (self.jssUsername, self.jssPassword))

        if (getResult.ok) {
            // Success Function
            print("GET Status: \(getResult.statusCode!)")

        }
        else {
            print("Unable to connect to your JSS!", "Please check that the JSS URL, username and password are correct and then try your request again.")
        } // Close Else

        // Try JSON extraction, looking for dictionary at 'computers' index; then loop through all elements...
        let resultText = getResult.text!.data(using: String.Encoding.utf8)!
        if let json = try? JSONSerialization.jsonObject(with: resultText) as? [String:Any],
           let groups = json?["computer_groups"] as? [[String:Any]] {

            let loopCount: Int = groups.count
            for index in 0 ..< loopCount {
                print(groups[index])
            }
        } else {
            print("bad json - do some recovery")
        }
    }

    func getMobiles(subPath: String) {
        let mobileUrl: String = jssUrl + subPath
        let getResult = Just.get(mobileUrl, headers: ["accept":"application/json"],
                auth: (self.jssUsername, self.jssPassword))

        if (getResult.ok) {
            // Success Function
            print("GET Status: \(getResult.statusCode!)")

        }
        else {
            print("Unable to connect to your JSS!", "Please check that the JSS URL, username and password are correct and then try your request again.")
        } // Close Else

        // Try JSON extraction, looking for dictionary at 'computers' index; then loop through all elements...
        let resultText = getResult.text!.data(using: String.Encoding.utf8)!
            if let json = try? JSONSerialization.jsonObject(with: resultText) as? [String:Any],
              let mobiles = json?["mobile_devices"] as? [[String:Any]] {

                let loopCount: Int = mobiles.count
                for index in 0 ..< loopCount {
                    print(mobiles[index])
                    }
            } else {
                print("bad json - do some recovery")
            }
    } // End MobileDevices function

    func getComputers(subPath: String) {
        let computersUrl: String = jssUrl + subPath
        let getResult = Just.get(computersUrl, headers: ["accept":"application/json"],
                                 auth: (self.jssUsername, self.jssPassword))
        if (getResult.ok) {
            // Success Function
            print("GET Status: \(getResult.statusCode!)")
    
            // Keeping these here so I remember they exist
            //print(jssSites.json!.valueForKey("sites")!.valueForKey("id"))
            //print(jssSites.json!.valueForKey("sites")!.valueForKey("name"))
        }
        else {
            print("Unable to connect to your JSS!", "Please check that the JSS URL, username and password are correct and then try your request again.")
        } // Close Else
    
        // Try JSON extraction, looking for dictionary at 'computers' index; then loop through all elements...
        let resultText = getResult.text!.data(using: String.Encoding.utf8)!
//    do {
            if let json = try? JSONSerialization.jsonObject(with: resultText) as? [String:Any],
                              let computers = json?["computers"] as? [[String:Any]] {

                let loopCount: Int = computers.count
                for index in 0 ..< loopCount {
                    print(computers[index])
                }
            } else {
                print("bad json - do some recovery")
          }
// } catch (error as NSError) { }

    } // End getComputers function
} // End jss class

// Start of main logic... If all goes well with initialization, switch on indicated JSS command-function
        if let jssRoot = JSS(ac: CommandLine.argc, av: CommandLine.unsafeArgv) {
            
            switch jssRoot.pValue! {

            case jssRestFunction.computers.rawValue:
                jssRoot.getComputers(subPath: jssRoot.pValue!)
                
            case jssRestFunction.mobiledevices.rawValue:
                jssRoot.getMobiles(subPath: jssRoot.pValue!)

            case jssRestFunction.computerrecord.rawValue:
                jssRoot.getComputerRecord(subPath: "computers/match", serialNumber: jssRoot.sValue!)

            case jssRestFunction.computergroups.rawValue:
                jssRoot.getComputerGroups(subPath: "computergroups")

            case jssRestFunction.removecomputerfromgroup.rawValue:
                jssRoot.removeComputerFromGroup(subPath: "computergroups", serialNumber: jssRoot.sValue!, groupName: jssRoot.gValue!)

            case jssRestFunction.addcomputertogroup.rawValue:
                jssRoot.addComputerToGroup(subPath: "computergroups", serialNumber: jssRoot.sValue!, groupName: jssRoot.gValue!)

            case jssRestFunction.createplaceholder.rawValue:
                jssRoot.createPlaceholder(subPath: "computergroups", serialNumber: jssRoot.sValue!, macAddress: jssRoot.gValue!)

            default:
                print("Jss Function not matched by input! (terminating)")
            }
        } else {
            print("Improper JSS-access initialization: exiting...")
            exit(EXIT_FAILURE)
        }
