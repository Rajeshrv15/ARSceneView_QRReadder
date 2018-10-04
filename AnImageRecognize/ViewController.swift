//
//  ViewController.swift
//  AnImageRecognize
//
//  Created by Alpha on 25/06/18.
//  Copyright © 2018 SAG. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import AzureIoTHubClient

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    var oHud : MBProgressHUD!
    
    //Anj pH
    private let connectionString = "HostName=Ti2018IoTHub.azure-devices.net;DeviceId=MyDotnetDevice;SharedAccessKey=BgkI2sT7Xaq69BtOh5xqdl3dLy2uekYWwv86VE2jpBE="
    // Select your protocol of choice: MQTT_Protocol, AMQP_Protocol or HTTP_Protocol
    // Note: HTTP_Protocol is not currently supported
    private let iotProtocol: IOTHUB_CLIENT_TRANSPORT_PROVIDER = MQTT_Protocol
    // IoT hub handle
    private var iotHubClientHandle: IOTHUB_CLIENT_LL_HANDLE!;
    var timerDoWork: Timer!
    var _sDisplayMessage : String = "Initialization message"
    var textNode = SCNNode()
    
    //Anj pH - reading text from Hub and show it online
    var txtScnText = SCNText(string: "Initialization message...", extrusionDepth: 1)
    let configuration = ARWorldTrackingConfiguration()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        
        //Anj pH
        // Create the client handle
        iotHubClientHandle = IoTHubClient_LL_CreateFromConnectionString(connectionString, iotProtocol)
        if (iotHubClientHandle == nil) {
            print("Failed to create IoT handle")
            return
        }
        // Mangle my self pointer in order to pass it as an UnsafeMutableRawPointer
        let that = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        // Set up the message callback
        if (IOTHUB_CLIENT_OK != (IoTHubClient_LL_SetMessageCallback(iotHubClientHandle, myReceiveMessageCallback, that))) {
            print("Failed to establish received message callback")
            return
        }
        timerDoWork = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(dowork), userInfo: nil, repeats: true)
        self._sDisplayMessage = ""
        print ("Anj pH : All IoTHubClient registration done.")
        
        
        textNode.scale = SCNVector3(x:0.004, y:0.004, z:0.004)
        textNode.geometry = txtScnText
        textNode.position = SCNVector3(x:0,y:0.02,z:-0.5)
        sceneView.scene.rootNode.addChildNode(textNode)
        /*let timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.update), userInfo: nil, repeats: true)*/
        self.sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        self.sceneView.showsStatistics = true
        self.sceneView.session.run(configuration)
        self.sceneView.delegate = self
        //self.update()
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        //self.update()
        if let imageAnchor = anchor as? ARImageAnchor {
            if let name = imageAnchor.referenceImage.name {
                DispatchQueue.main.async {
                    //self.update()
                    self._sDisplayMessage = "Am waiting..."
                    Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.update), userInfo: nil, repeats: true)
                    self.oHud = MBProgressHUD.showAdded(to: self.view, animated: true)
                    self.oHud.label.text = "This is your " + name
                    self.oHud.hide(animated: true, afterDelay: 3.0)
                    //_sDisplayMessage = "self.oHud.label.text"
                }
                print("Found your " + name )
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) else { fatalError("missing images")}
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.detectionImages = referenceImages
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    //Anj pH
    // This function is called when a message is received from the IoT hub. Once again it has to get a
    // pointer to the class instance as in the function above.
    let myReceiveMessageCallback: IOTHUB_CLIENT_MESSAGE_CALLBACK_ASYNC = { message, userContext in
        print ("Anj pH : Inside myReceiveMessageCallback.")
        var mySelf: ViewController = Unmanaged<ViewController>.fromOpaque(userContext!).takeUnretainedValue()
        //var mySelf: ViewController = Unmanaged<ViewController>.fromOpaque(userContext!).takeUnretainedValue()
        
        var messageId: String!
        var correlationId: String!
        var size: Int = 0
        var buff: UnsafePointer<UInt8>?
        var messageString: String = ""
        
        messageId = String(describing: IoTHubMessage_GetMessageId(message))
        correlationId = String(describing: IoTHubMessage_GetCorrelationId(message))
        
        if (messageId == nil) {
            messageId = "<nil>"
        }
        
        if correlationId == nil {
            correlationId = "<nil>"
        }
        
        //mySelf.incrementRcvd()
        
        // Get the data from the message
        var rc: IOTHUB_MESSAGE_RESULT = IoTHubMessage_GetByteArray(message, &buff, &size)
        
        if rc == IOTHUB_MESSAGE_OK {
            // Print data in hex
            for i in 0 ..< size {
                let out = String(buff![i], radix: 16)
                print("0x" + out, terminator: " ")
            }
            
            print()
            
            // This assumes the received message is a string
            let data = Data(bytes: buff!, count: size)
            messageString = String.init(data: data, encoding: String.Encoding.utf8)!
            
            //print("Message Id:", messageId, " Correlation Id:", correlationId)
            //print("Message:", messageString)
            mySelf._sDisplayMessage = " " + messageString
            //mySelf.update()
            //mySelf.lblLastRcvd.text = messageString
        }
        else {
            print("Failed to acquire message data")
            //mySelf.lblLastRcvd.text = "Failed to acquire message data"
        }
        return IOTHUBMESSAGE_ACCEPTED
    }
    //Anj pH
    @objc func dowork() {
        IoTHubClient_LL_DoWork(iotHubClientHandle)
    }
    
    @objc func update() {
        guard let pointofView = self.sceneView.pointOfView else {return}
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
        material.diffuse.contents = UIColor.green
        txtScnText.materials = [material]
        
        let eulerAngles = self.sceneView.session.currentFrame?.camera.eulerAngles
        textNode.eulerAngles = SCNVector3((eulerAngles?.x)!, (eulerAngles?.y)!, (eulerAngles?.z)! + Float(1.57))
        
        textNode.scale = SCNVector3(x:0.004, y:0.004, z:0.004)
        textNode.geometry = txtScnText
        textNode.position = position
        //textNode.constraints = [SCNBillboardConstraint()]
        //textNode.orientation = SCNVector3Make(transform.m41, transform.m42, transform.m43)
        sceneView.scene.rootNode.addChildNode(textNode)
        print("Received message : " + self._sDisplayMessage + " Trying to show @ ", position.x, position.y, position.z)
    }
    
}

func + (left: SCNVector3, right:SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x+right.x, left.y+right.y, left.z+right.z)
}
