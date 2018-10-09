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

class ARScenekitViewController: UIViewController, ARSCNViewDelegate, QRViewControllerDelegate {
    
    
    @IBOutlet weak var anSceneView: ARSCNView!
    
    //Current Device ID & end point details
    public var _CurrentIoTDeviceToWatch : String = "CodedDeviceId"
    var oDevID : String = ""
    var oDevDataUrl : String = ""
    var oUsrName : String = ""
    var oPass : String = ""
    
    //Sceen Text to show _DeviceMetrics
    var _ParentNodeForTextNode : SCNNode!
    var _DeviceMetrics : String = ""
    var textNode = SCNNode()
    var txtScnText = SCNText(string: "Initializing...", extrusionDepth: 1)
    let configuration = ARWorldTrackingConfiguration()
    var _sDisplayMessage : String = "Initializing..."
    
    //timer controller to refresh page
    var _timerCount : Int = 0
    var timerReadFromServer: Timer!
    var timerUpdateTextNode: Timer!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Set the view's delegate
        anSceneView.delegate = self
        
        // Show statistics such as fps and timing information
        anSceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        anSceneView.scene = scene
        
        //self.anSceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        self.anSceneView.showsStatistics = true
        //self.anSceneView.session.run(configuration)
        self.anSceneView.delegate = self
        
        
        ReadConnectionDetails() //Read the connection details from QR code
        
        timerReadFromServer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(ReadDisplayValueFromServer), userInfo: nil, repeats: true)
        timerUpdateTextNode = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(UpdateTextNode), userInfo: nil, repeats: true)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(anDidTap))
        anSceneView.addGestureRecognizer(tapGesture)
    }
    
    @objc func anDidTap(recognizer : UIGestureRecognizer) {
        let scenView = recognizer.view as! SCNView
        let touchLocation = recognizer.location(in: scenView)
        let hitResults = scenView.hitTest(touchLocation, options: [:])
        
        if !hitResults.isEmpty {
            let node = hitResults[0].node
            print("Node detected on tap")
        }
        /*let results = self.anSceneView.hitTest(gesture.location(in: gesture.view), types: ARHitTestResult.ResultType.featurePoint)
        guard let result: ARHitTestResult = results.first else {
            return
        }
        
        let tappedNode = self.anSceneView.hitTest(gesture.location(in: gesture.view), options: [:])
        
        if !tappedNode.isEmpty {
            print("Tap captured")
            return
        }
        print("Not captured")*/
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if #available(iOS 12.0, *) {
            guard let anRefCalendarObject = ARReferenceObject.referenceObjects(inGroupNamed: "anARResources", bundle: nil) else {
                print("unable to load resource")
                return
            }
            configuration.detectionObjects = anRefCalendarObject
            self.anSceneView.session.run(configuration)
            print("Calendar Resource loaded...")
        } else {
            // Fallback on earlier versions
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        anSceneView.session.pause()
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if #available(iOS 12.0, *) {
            if anchor is ARObjectAnchor {
                print ("Calendar detected")
                _ParentNodeForTextNode = node
                _ParentNodeForTextNode.position = SCNVector3Make(anchor.transform.columns.3.x, anchor.transform.columns.3.y, anchor.transform.columns.3.z)
                //anchor.
                /*let text = SCNText(string: "Calendar detected", extrusionDepth: 0.1)
                text.firstMaterial?.diffuse.contents = UIColor.red
                var txtNode = SCNNode(geometry: text)
                txtNode.scale = SCNVector3(0.01,0.01,0.01)
                txtNode.position = node.position
                print(node.position.x)
                print(node.position.y)
                print(node.position.z)
                node.addChildNode(txtNode)*/
                
            }
        } else {
            print ("Calendar not detected")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func OnCloseClick(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    func finishPassing(string: String) {
        _CurrentIoTDeviceToWatch = string
    }
    
    //To read the connectivity details from QR code response
    func ReadConnectionDetails() {
        var dictionary:NSDictionary?
        if let data = _CurrentIoTDeviceToWatch.data(using: String.Encoding.utf8) {
            do {
                dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject] as NSDictionary?
                if let myDictionary = dictionary
                {
                    oDevID = ReadContentString(dictInput: myDictionary, dictKey: "DeviceID")
                    oDevDataUrl = ReadContentString(dictInput: myDictionary, dictKey: "DeviceDataUrl")
                    oUsrName = ReadContentString(dictInput: myDictionary, dictKey: "UserName")
                    oPass = ReadContentString(dictInput: myDictionary, dictKey: "Password")
                }
            } catch let error as NSError {
                print(error)
            }
        }
    }
    
    func ReadContentString(dictInput: NSDictionary, dictKey: String) -> String {
        var oResStr = "NA"
        let anEmitParam = dictInput.value(forKey: dictKey) as? String
        if (anEmitParam != nil) {
            oResStr = anEmitParam!
        }
        return oResStr;
    }
    
    //To read device metrics
    @objc func ReadDisplayValueFromServer() {
       _timerCount = _timerCount + 1
       print("Current timer count  \(_timerCount)")
       print(" DeviceID : \(oDevID)")
       //print(" DeviceDataUrl : \(oDevDataUrl)")
       //print(" UserName : \(oUsrName)")
       //print(" Password : \(oPass)")
       //print(" Previous Response : \(self._DeviceMetrics)")
       GetDeviceMetricsFromServer(anAccessURL: oDevDataUrl, anUserName: oUsrName, anPassword: oPass)
       
        if _DeviceMetrics.isEmpty {
            //print("Value yet to assign")
            return
        }
       var dictionary:NSDictionary?
       if let data = _DeviceMetrics.data(using: String.Encoding.utf8) {
            do {
                dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject] as NSDictionary?
                if let myDictionary = dictionary
                {
                    //print("DeviceID : \(myDictionary["DeviceID"] ?? "default DeviceID")")
                    var anEmitParam = myDictionary.value(forKey: "DeviceEmittingParams") as? String
                    if (anEmitParam == nil) {
                        //print("DeviceEmittingParams 1 : \(self._sDisplayMessage)")
                        anEmitParam = "default text \(_timerCount)"
                        self._sDisplayMessage = anEmitParam!
                    }
                    else {
                        self._sDisplayMessage = anEmitParam!
                    }
                    //print("DeviceEmittingParams 2 : \(self._sDisplayMessage)")
                }
            } catch let error as NSError {
                print(error)
            }
        }
    }
    
    //Read device metrics from Server URL
    func GetDeviceMetricsFromServer(anAccessURL : String, anUserName: String, anPassword: String ) {
        let config = URLSessionConfiguration.default
        
        if (!anUserName.isEmpty && !anPassword.isEmpty) {
            let userPasswordData = "\(anUserName):\(anPassword)".data(using: .utf8)
            let base64EncodedCredential = userPasswordData!.base64EncodedString(options: Data.Base64EncodingOptions.init(rawValue: 0))
            let authString = "Basic \(base64EncodedCredential)"
            config.httpAdditionalHeaders = ["Authorization" : authString]
        }
        
        //print("URL : " + anAccessURL)
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
        }).resume()
    }
    
    @objc func UpdateTextNode() {
        if _ParentNodeForTextNode == nil {
            return
        }
        if _ParentNodeForTextNode != nil && _ParentNodeForTextNode.childNodes.count > 0 {
            _ParentNodeForTextNode.childNodes .forEach { item in
                item.removeFromParentNode()
            }
        }
        
        let lstSCNNodes = GetIndividualTextNode(stDisplayText: self._sDisplayMessage)
        if lstSCNNodes.count == 0 {
            return
        }
        lstSCNNodes .forEach { item in
            _ParentNodeForTextNode.addChildNode(item)
        }
    }
    
    func GetIndividualTextNode(stDisplayText : String) -> Array<SCNNode> {
        var lstSCNodesText = [SCNNode()]
        let splitTextArray = stDisplayText.split(separator: ",")
        var iYPosition = 0.01
        let eulerAngles = self.anSceneView.session.currentFrame?.camera.eulerAngles
        
        splitTextArray.forEach { item in
            //print(item)
            let anTxtScnText = SCNText(string: item, extrusionDepth: 1)
            let material = SCNMaterial()
            material.diffuse.contents = UIColor.black
            anTxtScnText.materials = [material]
            anTxtScnText.containerFrame = CGRect(origin: .zero, size: CGSize(width: 250, height: 100))
            anTxtScnText.font = UIFont(name: "Helvetica Neue", size: 15)
            let anTxtNode = SCNNode()
            anTxtNode.scale = SCNVector3(x:0.01, y:0.01, z:0.01)
            //anTxtNode.position = SCNVector3(x: 0, y:Float(iYPosition), z:0)
            anTxtNode.simdPosition = simd_float3.init(x: 0, y:Float(iYPosition), z:0)
            anTxtNode.geometry = anTxtScnText
            anTxtNode.eulerAngles = SCNVector3((eulerAngles?.x)!, (eulerAngles?.y)!, (eulerAngles?.z)! + Float(1.57))
            lstSCNodesText.append(anTxtNode)
            iYPosition = iYPosition + 0.4
            //print(iYPosition)
        }
        
        return lstSCNodesText
    }    
}

struct IoTDeviceData {
    let DeviceID: String
    let DeviceIoTHub: String
    let DeviceEmittingParams: String
}

func + (left: SCNVector3, right:SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x+right.x, left.y+right.y, left.z+right.z)
}
