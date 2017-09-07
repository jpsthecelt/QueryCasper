//#! /usr/bin/swift
//
//  main.swift
//  parseCmdLine
//
//  Created by John Singer on 7/13/17.
//  Copyright © 2017 John Singer. All rights reserved.
//
// This has recently shown very odd behavior: When I run this in the debugger, it fails and shows the
//      equivalent CURL command, when I run it on the commandline, it works (but shows XML).

import SwiftyJSON
import Foundation
import Alamofire

let pattern = "f:u:p:"
var fFlag = false
var fVal: String?

var uFlag = false
var uValue: String?

var pFlag = false
var pValue: String?

let url = "https://casper.csueastbay.edu:8443/JSSResource/"
var headers: HTTPHeaders = [:]




// Usage: QueryCasper -f json_authorization_file.txt -p sub_url or
//        QueryCasper -u username:password -p sub_url 
// NOTE: -f & -u are mutually-exclusive

while case let option = getopt(CommandLine.argc, CommandLine.unsafeArgv, pattern), option != -1 {
    switch UnicodeScalar(CUnsignedChar(option)) {
    case "u":
        uFlag = true
        uValue = String(cString: optarg)
        
    case "f":
        fFlag = true
        fVal = String(cString: optarg)
        
    case "p":
        pFlag = true
        pValue = String(cString: optarg)
        
    default:
//        fatalError("Unknown option")
        print("Unknown Option: \(CommandLine.arguments[0])")
        exit(EXIT_FAILURE)
    }
}

// the following is the same thing as a logical XOR
guard  uFlag != fFlag else {
    print("-u or -f, Either command-line flag option may be used; not both")
    exit(EXIT_FAILURE)
}


print("fFlag = \(fFlag) and fValue = ", fVal ?? "?")
print("uFlag = \(uFlag) and uValue = ", uValue ?? "?", "\n")
print("pFlag = \(pFlag) and pValue = ", pValue ?? "?", "\n")

// Now, if the fFlag is set, we've gotten our parameter file from the command-line, so we'll try to read it, parse, it and
//    use it to access JAMF.
if fFlag {
    do {
        var filedata = try String(contentsOfFile: fVal!, encoding: String.Encoding.utf8)

        if let authProps = filedata.data(using: String.Encoding.utf8, allowLossyConversion: false) {
            let json = JSON(data: authProps)
            let user = json["username"].string
            let password = json["password"].string

            if let authorizationHeader = Request.authorizationHeader(user: user!, password: password!) {
                headers[authorizationHeader.key] = authorizationHeader.value
                headers["Accept"] = "application/json"
            }
            
            print("headers: \(headers)\n")
            
            var r = Alamofire.request(url+pValue!, headers: headers)

                .responseJSON { response in
                    debugPrint(response)
            }
            debugPrint(r)
        }
   }
}

