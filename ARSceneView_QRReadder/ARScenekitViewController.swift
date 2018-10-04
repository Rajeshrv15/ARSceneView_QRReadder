//
//  ARScenekitViewController.swift
//  ARSceneView_QRReadder
//
//  Created by Alpha on 03/08/18.
//  Copyright © 2018 SAG. All rights reserved.
//

import UIKit
import ARKit
import SceneKit
import Foundation

class ARScenekitViewController: UIViewController, ARSCNViewDelegate, APIManagerDelegate {
    
    @IBOutlet weak var anSceneView: ARSCNView!
    public var _CurrentIoTDeviceToWatch : String = "testmessage"
    let configuration = ARWorldTrackingConfiguration()
    
    var oDevID : String = ""
    var oDevDataUrl : String = ""
    var oUsrName : String = ""
    var oPass : String = ""
    
    var _timerCount : Int = 0
    var timerDoWork: Timer!
    
    var _DeviceMetrics : String = ""
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        // Set the view's delegate
        anSceneView.delegate = self
        
        // Show statistics such as fps and timing information
        anSceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        anSceneView.scene = scene
        
        self.anSceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        self.anSceneView.showsStatistics = true
        self.anSceneView.session.run(configuration)
        self.anSceneView.delegate = self
        
        ReadConnectionDetails() //Read the connection details from QR code
        
        timerDoWork = Timer.scheduledTimer(timeInterval: 9, target: self, selector: #selector(ReadDisplayValueFromServer), userInfo: nil, repeats: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func OnCloseClick(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    func ReadConnectionDetails() {
        var dictionary:NSDictionary?
        if let data = _CurrentIoTDeviceToWatch.data(using: String.Encoding.utf8) {
            do {
                
                dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject] as! NSDictionary
                
                if let myDictionary = dictionary
                {
                    oDevID = myDictionary["DeviceID"] as! String
                    oDevDataUrl = myDictionary["DeviceDataUrl"] as! String
                    oUsrName = myDictionary["UserName"] as! String
                    oPass = myDictionary["Password"] as! String
                }
                
            } catch let error as NSError {
                print(error)
            }
        }
    }
    
    @objc func ReadDisplayValueFromServer() -> String {
       _timerCount = _timerCount + 1
        print("Current timer count  \(_timerCount)")
       print(" DeviceID : \(oDevID)")
       print(" DeviceDataUrl : \(oDevDataUrl)")
       print(" UserName : \(oUsrName)")
       print(" Password : \(oPass)")
       print("AnjRes 2 : \(self._DeviceMetrics)")
       AnjInhousePerformCall(anAccessURL: oDevDataUrl, anUserName: oUsrName, anPassword: oPass)
       
       var dictionary:NSDictionary?
       if let data = _DeviceMetrics.data(using: String.Encoding.utf8) {
            do {
                dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject] as! NSDictionary
                
            } catch let error as NSError {
                print(error)
            }
        }
        
        return "AnjRes"
    }
    
    func AnjInhousePerformCall(anAccessURL : String, anUserName: String, anPassword: String ) {
        let config = URLSessionConfiguration.default
        
        if (!anUserName.isEmpty && !anPassword.isEmpty) {
            let userPasswordData = "\(anUserName):\(anPassword)".data(using: .utf8)
            let base64EncodedCredential = userPasswordData!.base64EncodedString(options: Data.Base64EncodingOptions.init(rawValue: 0))
            let authString = "Basic \(base64EncodedCredential)"
            config.httpAdditionalHeaders = ["Authorization" : authString]
        }
        
        print("URL : " + anAccessURL)
        let session = URLSession(configuration: config)
        
        let anUrl = URL(string: anAccessURL)!
        let anUrlRequest : URLRequest = URLRequest(url: anUrl)
        var anResponse : String = ""
        session.dataTask(with: anUrlRequest as URLRequest, completionHandler: { (data, response, error) -> Void in
            guard error == nil else {
                print(error?.localizedDescription ?? "")
                return
            }
            anResponse = String(data: data!, encoding: .utf8)!
            self._DeviceMetrics = anResponse
            
            print("Am Called after completion")
        }).resume()
        print("Anj Please help me : \(self._DeviceMetrics)")
    }
    
    
    func finishReadingResponse(code: String) {
        print("REceived : \(code)")
        self._DeviceMetrics = code
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

struct IoTDeviceData {
    let DeviceID: String
    let DeviceIoTHub: String
    let DeviceEmittingParams: String
}
