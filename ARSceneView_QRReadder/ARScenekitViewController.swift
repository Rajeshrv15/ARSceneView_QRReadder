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
    var _ParentNodeAnchor : ARObjectAnchor!
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
                _ParentNodeAnchor = anchor as! ARObjectAnchor
                //_ParentNodeForTextNode.position = SCNVector3Make(anchor.transform.columns.3.x, anchor.transform.columns.3.y, anchor.transform.columns.3.z)
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
                        anEmitParam = "de1 \(_timerCount),de2 \(_timerCount),de3 \(_timerCount),de4 \(_timerCount)"
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
        
        //let lstSCNNodes = GetIndividualTextNode(stDisplayText: self._sDisplayMessage)
        let lstSCNNodes = GetIndividualSpiteTextNode2(stDisplayText: self._sDisplayMessage)
        if lstSCNNodes.count == 0 {
            return
        }
        var iYPosition = 0.1
        lstSCNNodes .forEach { item in
            item.position = SCNVector3(_ParentNodeAnchor.transform.columns.3.x, Float(iYPosition), _ParentNodeAnchor.transform.columns.3.z)
            _ParentNodeForTextNode.addChildNode(item)
            iYPosition = iYPosition + 0.015
        }
    }
    
    func GetIndividualSpiteTextNode2(stDisplayText: String) -> Array<SCNNode> {
        
        var lstSCNodesText = [SCNNode()]
        let splitTextArray = stDisplayText.split(separator: ",")
        //let stDisplayText2 = stDisplayText.replacingOccurrences(of: ",", with: "\n")
        var iYPosition = 5
        var iXPosition = CGFloat(5)
        
        
            let skScene = SKScene(size:CGSize(width: 1600, height: 200))
            skScene.scaleMode = .aspectFit
            skScene.shouldEnableEffects = true
            skScene.backgroundColor = UIColor.clear
            skScene.blendMode = .alpha
            //skScene.position = SCNVector3(_ParentNodeAnchor.transform.columns.3.x, Float(iYPosition), _ParentNodeAnchor.transform.columns.3.z)
        var i : integer_t = 0
        splitTextArray.forEach { item in
            let box = SKSpriteNode(color: UIColor.black, size: CGSize(width: 200, height: 50))
            //let box = SKShapeNode(rect: CGRect(x: 0, y: 0, width: 200, height: 50), cornerRadius: 10)
            //box.fillColor = UIColor.black
            /*if (i == 1)
            {
                box.color = UIColor.black
            }
            if (i == 2) {
                box.color = UIColor.green
            }*/
            iXPosition = iXPosition + skScene.frame.minX + CGFloat(250)
            let label = SKLabelNode(fontNamed:"ArialMT")
            label.text = String(item)
            label.position = CGPoint(x: 0, y: 0)
            label.horizontalAlignmentMode = .center
            label.verticalAlignmentMode = .center
            label.fontSize =  50
            label.fontColor = UIColor.red
            //to show in row
            //box.position = CGPoint(x: skScene.frame.minX , y: skScene.frame.minY + (box.size.height/2) + CGFloat(iYPosition))
            //to show in column
            box.position = CGPoint(x: CGFloat(iXPosition), y: skScene.frame.minY + (box.size.height/2))
            //box.position = CGPoint(x: CGFloat(iXPosition), y: skScene.frame.minY + CGFloat(25))
            
            //box.anchorPoint = CGPoint(x:0 + CGFloat(iYPosition), y: 0.5 + CGFloat(iYPosition))
            box.addChild(label)
            box.yScale=box.yScale * -1
            skScene.addChild(box)
            iYPosition = iYPosition + 100
            
            i = i + 1
        }
            let plane = SCNPlane(width: CGFloat(0.4), height: CGFloat(0.1))
            //plane.position = SCNVector3(_ParentNodeAnchor.transform.columns.3.x, Float(iYPosition), _ParentNodeAnchor.transform.columns.3.z)
            plane.firstMaterial!.diffuse.contents = skScene
            
            let finalDisplayNode = SCNNode(geometry: plane)
            //finalDisplayNode.position = SCNVector3(_ParentNodeAnchor.transform.columns.3.x, Float(iYPosition), _ParentNodeAnchor.transform.columns.3.z)
            
            lstSCNodesText.append(finalDisplayNode)
            //iYPosition = iYPosition + 0.015
        
        return lstSCNodesText
    }
    
    func GetIndividualSpiteTextNode1(stDisplayText: String) -> Array<SCNNode> {
        
        var lstSCNodesText = [SCNNode()]
        let splitTextArray = stDisplayText.split(separator: ",")
        //let stDisplayText2 = stDisplayText.replacingOccurrences(of: ",", with: "\n")
        var iYPosition = 1
        
        
        let skScene = SKScene(size:CGSize(width: 600, height: 200))
        skScene.scaleMode = .aspectFit
        skScene.shouldEnableEffects = true
        skScene.backgroundColor = UIColor.yellow
        skScene.blendMode = .alpha
        //skScene.position = SCNVector3(_ParentNodeAnchor.transform.columns.3.x, Float(iYPosition), _ParentNodeAnchor.transform.columns.3.z)
        splitTextArray.forEach { item in
            let box = SKSpriteNode(color: UIColor.black, size: CGSize(width: 50, height: 50))
            
            let label = SKLabelNode(fontNamed:"ArialMT")
            label.text = String(item)
            label.position = CGPoint(x: box.frame.width/2, y: 0)
            label.horizontalAlignmentMode = .center
            label.verticalAlignmentMode = .center
            label.fontSize =  25
            label.fontColor = UIColor.red
            //box.position = CGPoint(x: skScene.frame.minX, y: skScene.frame.minY + (box.size.height/2))
            box.position = CGPoint(x: skScene.frame.minX + CGFloat(iYPosition), y: skScene.frame.minY + (box.size.height/2))
            box.anchorPoint = CGPoint(x:0 + CGFloat(iYPosition), y: 0.5 + CGFloat(iYPosition))
            box.addChild(label)
            box.yScale=box.yScale * -1
            skScene.addChild(box)
            iYPosition = iYPosition + 60
        }
        let plane = SCNPlane(width: CGFloat(0.1), height: CGFloat(0.1))
        //plane.position = SCNVector3(_ParentNodeAnchor.transform.columns.3.x, Float(iYPosition), _ParentNodeAnchor.transform.columns.3.z)
        plane.firstMaterial!.diffuse.contents = skScene
        
        let finalDisplayNode = SCNNode(geometry: plane)
        //finalDisplayNode.position = SCNVector3(_ParentNodeAnchor.transform.columns.3.x, Float(iYPosition), _ParentNodeAnchor.transform.columns.3.z)
        
        lstSCNodesText.append(finalDisplayNode)
        //iYPosition = iYPosition + 0.015
        
        return lstSCNodesText
    }
    
    func GetIndividualSpiteTextNode(stDisplayText: String) -> Array<SCNNode> {
        
        var lstSCNodesText = [SCNNode()]
        let splitTextArray = stDisplayText.split(separator: ",")
        //let stDisplayText2 = stDisplayText.replacingOccurrences(of: ",", with: "\n")
        //var iYPosition = 0.01
        
        splitTextArray.forEach { item in
            let skScene = SKScene(size:CGSize(width: 350, height: 350))
            skScene.scaleMode = .aspectFit
            skScene.shouldEnableEffects = true
            skScene.backgroundColor = UIColor.yellow
            skScene.blendMode = .alpha
            //skScene.position = SCNVector3(_ParentNodeAnchor.transform.columns.3.x, Float(iYPosition), _ParentNodeAnchor.transform.columns.3.z)
            
            let box = SKSpriteNode(color: UIColor.black, size: CGSize(width: 350, height: 350))
            
            let label = SKLabelNode(fontNamed:"Helvetica Neue")
            label.text = String(item)
            label.position = CGPoint(x: box.frame.width/2, y: 0)
            label.horizontalAlignmentMode = .center
            label.verticalAlignmentMode = .center
            label.fontSize =  box.frame.size.height / 4
            label.fontColor = UIColor.red
            box.position = CGPoint(x: skScene.frame.minX, y: skScene.frame.minY + (box.size.height/2))
            box.anchorPoint = CGPoint(x:0, y: 0.5)
            box.addChild(label)
            box.yScale=box.yScale * -1
            skScene.addChild(box)
            
            let plane = SCNPlane(width: CGFloat(0.1), height: CGFloat(0.1))
            //plane.position = SCNVector3(_ParentNodeAnchor.transform.columns.3.x, Float(iYPosition), _ParentNodeAnchor.transform.columns.3.z)
            plane.firstMaterial!.diffuse.contents = skScene

            let finalDisplayNode = SCNNode(geometry: plane)
            //finalDisplayNode.position = SCNVector3(_ParentNodeAnchor.transform.columns.3.x, Float(iYPosition), _ParentNodeAnchor.transform.columns.3.z)
            
            lstSCNodesText.append(finalDisplayNode)
            //iYPosition = iYPosition + 0.015
        }
        return lstSCNodesText
    }
    
    func GetIndividualTextNode(stDisplayText : String) -> Array<SCNNode> {
        var lstSCNodesText = [SCNNode()]
        let splitTextArray = stDisplayText.split(separator: ",")
        var iYPosition = 0.01
        //let eulerAngles = self.anSceneView.session.currentFrame?.camera.eulerAngles
        
        splitTextArray.forEach { item in
            //print(item)
            let anTxtScnText = SCNText(string: item, extrusionDepth: 1)
            let material = SCNMaterial()
            material.diffuse.contents = UIColor.black
            anTxtScnText.materials = [material]
            //anTxtScnText.containerFrame = CGRect(origin: .zero, size: CGSize(width: 250, height: 100))
            anTxtScnText.font = UIFont(name: "Helvetica Neue", size: 15)
            let anTxtNode = SCNNode()
            anTxtNode.scale = SCNVector3(x:0.001, y:0.001, z:0.001)
            if _ParentNodeAnchor != nil {
                //anTxtNode.position = SCNVector3(x: 0, y:Float(iYPosition), z:0)
                anTxtNode.position = SCNVector3(_ParentNodeAnchor.transform.columns.3.x, Float(iYPosition), _ParentNodeAnchor.transform.columns.3.z)
            }
            //anTxtNode.position = SCNVector3(x 0, y:Float(iYPosition), z:0)
           // anTxtNode.simdPosition = simd_float3.init(x: 0, y:Float(iYPosition), z:0)
            anTxtNode.geometry = anTxtScnText
            //anTxtNode.eulerAngles = SCNVector3((eulerAngles?.x)!, (eulerAngles?.y)!, (eulerAngles?.z)! + Float(1.57))
            lstSCNodesText.append(anTxtNode)
            iYPosition = iYPosition + 0.015
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
