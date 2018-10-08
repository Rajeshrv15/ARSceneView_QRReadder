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
        
        // Do any additional setup after loading the view.
        
        // Set the view's delegate
        anSceneView.delegate = self
        
        // Show statistics such as fps and timing information
        anSceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        anSceneView.scene = scene
        
        self.anSceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]//ARSCNDebugOptions.showWorldOrigin,
        self.anSceneView.showsStatistics = true
        //self.anSceneView.session.run(configuration)
        self.anSceneView.delegate = self
        /*let anTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ShowInThisLocation))
        self.anSceneView.addGestureRecognizer(anTapGestureRecognizer)*/
        
        ReadConnectionDetails() //Read the connection details from QR code
        
        timerReadFromServer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(ReadDisplayValueFromServer), userInfo: nil, repeats: true)
        timerUpdateTextNode = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(UpdateTextNode), userInfo: nil, repeats: true)
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
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if #available(iOS 12.0, *) {
            if anchor is ARObjectAnchor {
                print ("Calendar detected")
                _ParentNodeForTextNode = node
            }
        } else {
            print ("Calendar not detected")
        }
    }
    
    @objc func ShowInThisLocation(recognizer: UITapGestureRecognizer) {
        /*let sceneView = recognizer.view as! SCNView
        let touchPosition = recognizer.location(in: sceneView)
        let hitResult = sceneView.hitTest(touchPosition, options: [:])
        sceneView.hitTest(touchPosition, options: [SCNHitTestOption.boundingBoxOnly: true])
        
        if !hitResult.isEmpty {
            print("Am hit ...")
            //PositionTextNode(hitTestResult: hitResult)
        }
        print("Am hit 2 ...")
        hitResult.
        textNode.position = SCNVector3(hitResult.worldTransform.)*/
    }
    
    func PlaceTextNode() {
        textNode.scale = SCNVector3(x:0.001, y:0.001, z:0.001)
        textNode.geometry = txtScnText
        textNode.position = SCNVector3(x:-0.1,y:-0.15,z:-0.1)
        //self.anSceneView.scene.rootNode.addChildNode(textNode)
        if _ParentNodeForTextNode == nil {
            return
        }
        _ParentNodeForTextNode.addChildNode(textNode)
    }
    
    /*func PositionTextNode(hitTestResult : SCNHitTestResult) {
        textNode.position = SCNVector3(hitTestResult.modelTransform.columns.3.x,hitTestResult.worldTransform.columns.3.y, hitTestResult.worldTransform.columns.3.z)
    }*/

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
       //print(" DeviceID : \(oDevID)")
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
        guard let pointofView = self.anSceneView.pointOfView else {return}
        let transform = pointofView.transform
        let orientation = SCNVector3(-transform.m31, -transform.m32, -transform.m33)
        let location = SCNVector3(transform.m41, transform.m42, transform.m43)
        let position = orientation + location
        //if let imageAnchor = anchor as? ARImageAnchor {
        textNode.removeFromParentNode()
        //self._sDisplayMessage += " Try adding this text ..."
        txtScnText = SCNText(string: String(self._sDisplayMessage), extrusionDepth:1)
        //Anj pH - To show dynamic text message
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.black
        txtScnText.materials = [material]
        //txtScnText.containerFrame = CGRect(origin: .zero, size: CGSize(width: 180, height: 180))
        txtScnText.font = UIFont(name: "Helvetica Neue", size: 15)
        
        txtScnText.isWrapped = true
        
        let eulerAngles = self.anSceneView.session.currentFrame?.camera.eulerAngles
        textNode.eulerAngles = SCNVector3((eulerAngles?.x)!, (eulerAngles?.y)!, (eulerAngles?.z)! + Float(1.57))
        
        PlaceTextNode()
        /*textNode.scale = SCNVector3(x:0.001, y:0.001, z:0.001)
        textNode.geometry = txtScnText
        //textNode.position = position
        textNode.position = SCNVector3(x:0,y:0,z:-0.5)
        //textNode.constraints = [SCNBillboardConstraint()]
        //textNode.orientation = SCNVector3Make(transform.m41, transform.m42, transform.m43)
        self.anSceneView.scene.rootNode.addChildNode(textNode)*/
        //print("Received message : " + self._sDisplayMessage + " Trying to show @ ", position.x, position.y, position.z)
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

func + (left: SCNVector3, right:SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x+right.x, left.y+right.y, left.z+right.z)
}
