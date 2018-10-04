//
//  APIManager.swift
//  ARSceneView_QRReadder
//
//  Created by Alpha on 01/10/18.
//  Copyright © 2018 SAG. All rights reserved.
//

import UIKit
import Foundation

protocol APIManagerDelegate {
    func finishReadingResponse(code: String)
}

class APIManager {
    let urlCumulocity = "http://nikarin.cumulocity.com"
    let pstEndMeasurement = "/measurement/measurements?dateTo=2018-10-01T14:35:58.453%2B05:30&pageSize=5&source=568&dateFrom=2018-10-01T14:35:57.600%2B05:30"
    let userName = "balaji.thilagar@softwareag.com"
    let userPass = "manage"
    var delegate : APIManagerDelegate?
    var anjResponseToSend : String = " "
    
    func AnPerformCallToServer(anAccessURL : String, anUserName: String, anPassword: String, _completion: @escaping (String) -> ()) {
        let config = URLSessionConfiguration.default
    
        if (!anUserName.isEmpty && !anPassword.isEmpty) {
        let userPasswordData = "\(anUserName):\(anPassword)".data(using: .utf8)
        let base64EncodedCredential = userPasswordData!.base64EncodedString(options: Data.Base64EncodingOptions.init(rawValue: 0))
        let authString = "Basic \(base64EncodedCredential)"
        config.httpAdditionalHeaders = ["Authorization" : authString]
        }
    
        print("URL : " + anAccessURL)
        let session = URLSession(configuration: config)
    
        //let anUrl = URL(string: urlCumulocity + pstEndMeasurement)!
        let anUrl = URL(string: anAccessURL)!
        let anUrlRequest : URLRequest = URLRequest(url: anUrl)
        var anResponse : String = ""
        let task  = session.dataTask(with: anUrlRequest as URLRequest ) { (data, response, error) in
        guard error == nil else {
        print(error?.localizedDescription ?? "")
        _completion("")
            return;
        }
            DispatchQueue.main.async {
                self.anjResponseToSend = String(data: data!, encoding: .utf8)!
            }
        
        _completion(anResponse)
            return;
        //print(" AnjResponse : \(anResponse)" )
        //print(String(data: data!, encoding: .utf8)!)
        //return String(data: data!, encoding: .utf8)
        }.resume()
        
        print(" AnjResponse : \(self.anjResponseToSend)" )
        //return anResponse
    }
    
    func AnPerformCall(anAccessURL : String, anUserName: String, anPassword: String ) {
        //print("AnPerformCall called 2")
        let config = URLSessionConfiguration.default
        
        if (!anUserName.isEmpty && !anPassword.isEmpty) {
            let userPasswordData = "\(anUserName):\(anPassword)".data(using: .utf8)
            let base64EncodedCredential = userPasswordData!.base64EncodedString(options: Data.Base64EncodingOptions.init(rawValue: 0))
            let authString = "Basic \(base64EncodedCredential)"
            config.httpAdditionalHeaders = ["Authorization" : authString]
        }
        
        print("URL : " + anAccessURL)
        let session = URLSession(configuration: config)
        
        //let anUrl = URL(string: urlCumulocity + pstEndMeasurement)!
        let anUrl = URL(string: anAccessURL)!
        let anUrlRequest : URLRequest = URLRequest(url: anUrl)
        var anResponse : String = ""
        let task  = session.dataTask(with: anUrlRequest as URLRequest ) { (data, response, error) in
            guard error == nil else {
                print(error?.localizedDescription ?? "")
                return //""
            }
            anResponse = String(data: data!, encoding: .utf8)!
            //self.fnFinishReadingResponse(anCode: anResponse)
            return //anResponse
            //print(" AnjResponse : \(anResponse)" )
            //print(String(data: data!, encoding: .utf8)!)
            //return String(data: data!, encoding: .utf8)
        }.resume()
        
        //print(" AnjResponse : \(anResponse)" )
        
    }
    
    func AnPerformCallToServerPls(anAccessURL : String, anUserName: String, anPassword: String) -> String {
        let config = URLSessionConfiguration.default
        
        if (!anUserName.isEmpty && !anPassword.isEmpty) {
            let userPasswordData = "\(anUserName):\(anPassword)".data(using: .utf8)
            let base64EncodedCredential = userPasswordData!.base64EncodedString(options: Data.Base64EncodingOptions.init(rawValue: 0))
            let authString = "Basic \(base64EncodedCredential)"
            config.httpAdditionalHeaders = ["Authorization" : authString]
        }
        
        print("URL : " + anAccessURL)
        let session = URLSession(configuration: config)
        
        //let anUrl = URL(string: urlCumulocity + pstEndMeasurement)!
        let anUrl = URL(string: anAccessURL)!
        let anUrlRequest : URLRequest = URLRequest(url: anUrl)
        var anResponse : String = ""
        let task = session.dataTask(with: anUrlRequest as URLRequest, completionHandler: { (data, response, error) in
            guard error == nil else {
                print(error?.localizedDescription ?? "")
                return //""
            }
            anResponse = String(data: data!, encoding: .utf8)!
            //print(response)
            //self.anjResponseToSend = anResponse
            DispatchQueue.main.async {
            self.fnFinishReadingResponse(anCode: anResponse)
                self.anjResponseToSend = anResponse
            }
            //self.fnFinishReadingResponse(anCode: anResponse)
            //return
        })
    task.resume()
        /*let task  = session.dataTask(with: anUrlRequest as URLRequest ) { (data, response, error) in
            guard error == nil else {
                print(error?.localizedDescription ?? "")
                return //""
            }
            anResponse = String(data: data!, encoding: .utf8)!
            self.anjResponseToSend = anResponse
            //self.fnFinishReadingResponse(anCode: anResponse)
            return //anResponse
            //print(" AnjResponse : \(anResponse)" )
            //print(String(data: data!, encoding: .utf8)!)
            //return String(data: data!, encoding: .utf8)
            }.resume()*/
        print("Anj Please help me : \(self.anjResponseToSend)")
        return self.anjResponseToSend
    }
    
    func fnFinishReadingResponse(anCode: String) {
        DispatchQueue.main.async {
            self.delegate?.finishReadingResponse(code: anCode)
        }
        self.anjResponseToSend = anCode
        print("Sending : \(anjResponseToSend)")
        
    }
}
