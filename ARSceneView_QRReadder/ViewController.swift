//
//  ViewController.swift
//  ARSceneView_QRReadder
//
//  Created by Alpha on 03/08/18.
//  Copyright © 2018 SAG. All rights reserved.
//

import UIKit

class ViewController: UIViewController, QRViewControllerDelegate {
       
    var _anQRString : String = "QRText"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func onReadDeviceData(_ sender: UIButton) {
        performSegue(withIdentifier: "AnjShowDeviceData", sender: self)
    }
    
    
    @IBAction func onLoadQRReader(_ sender: UIButton) {
        performSegue(withIdentifier: "AnjShowQRReader", sender: self)
    }
    
    func finishPassing(string: String) {
        self._anQRString = string
        //print("Received from QR Reader : " + self._anQRString)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? QRViewController {
            destination.delegate = self
        }
        if segue.identifier == "AnjShowDeviceData" {
            guard let destinationVC = segue.destination as? ARScenekitViewController else {
                //print("Nee neikiera sender nan illai " + segue.debugDescription)
                return
            }            
            destinationVC._CurrentIoTDeviceToWatch = self._anQRString
         }
    }
    
}

