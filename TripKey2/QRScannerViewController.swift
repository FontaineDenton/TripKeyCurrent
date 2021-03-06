//
//  QRScannerViewController.swift
//  TripKey
//
//  Created by Peter on 16/02/19.
//  Copyright © 2019 Fontaine. All rights reserved.
//

import UIKit
import AVFoundation
import Parse

class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let activityCenter = CenterActivityView()
    let imagePicker = UIImagePickerController()
    let backButton = UIButton()
    let uploadButton = UIButton()
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.black
        captureSession = AVCaptureSession()
        imagePicker.delegate = self
        
        let videoCaptureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            failed()
            return
        }
        
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
        } else {
            failed()
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        captureSession.startRunning()
        
        addButtons()
    }
    
    func addButtons() {
        
        DispatchQueue.main.async {
            
            self.backButton.removeFromSuperview()
            let device = UIDevice.modelName
            if device == "Simulator iPhone X" || device == "iPhone X" || device == "Simulator iPhone XS" || device == "Simulator iPhone XR" || device == "Simulator iPhone XS Max" {
                self.backButton.frame = CGRect(x: 5, y: 40, width: 25, height: 25)
            } else {
                self.backButton.frame = CGRect(x: 5, y: 20, width: 25, height: 25)
            }
            self.backButton.showsTouchWhenHighlighted = true
            let image = UIImage(imageLiteralResourceName: "backButton.png")
            self.backButton.setImage(image, for: .normal)
            self.backButton.addTarget(self, action: #selector(self.goBack), for: .allTouchEvents)
            self.view.addSubview(self.backButton)
            
            self.uploadButton.removeFromSuperview()
            self.uploadButton.showsTouchWhenHighlighted = true
            self.uploadButton.setTitleColor(UIColor.white, for: .normal)
            self.uploadButton.backgroundColor = UIColor.clear
            self.uploadButton.titleLabel?.font = UIFont.init(name: "HelveticaNeue-Bold", size: 20)
            self.uploadButton.frame = CGRect(x: 0, y: self.view.frame.maxY - 50, width: self.view.frame.width, height: 30)
            self.uploadButton.showsTouchWhenHighlighted = true
            self.uploadButton.titleLabel?.textAlignment = .center
            self.uploadButton.setTitle("Upload from photos", for: .normal)
            self.uploadButton.addTarget(self, action: #selector(self.chooseQRCodeFromLibrary), for: .touchUpInside)
            self.view.addSubview(self.uploadButton)
            
        }
        
    }
    
    @objc func goBack() {
        
        self.dismiss(animated: true, completion: nil)
        
    }
    
    func failed() {
        print("failed")
        addButtons()
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if (captureSession?.isRunning == false) {
            captureSession.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (captureSession?.isRunning == true) {
            captureSession.stopRunning()
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        captureSession.stopRunning()
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            found(code: stringValue)
        }
        
    }
    
    func captureOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        captureSession.stopRunning()
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            found(code: stringValue)
        }
        
    }
    
    func found(code: String) {
        print(code)
        DispatchQueue.main.async {
            self.followUser(userid: code)
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    @objc func chooseQRCodeFromLibrary() {
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
            let detector:CIDetector=CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy:CIDetectorAccuracyHigh])!
            let ciImage:CIImage = CIImage(image:pickedImage)!
            var qrCodeLink = ""
            let features = detector.features(in: ciImage)
            
            for feature in features as! [CIQRCodeFeature] {
                qrCodeLink += feature.messageString!
            }
            
            print(qrCodeLink)
            
            if qrCodeLink != "" {
                
                DispatchQueue.main.async {
                    
                    self.followUser(userid: qrCodeLink)
                    
                }
                
            }
            
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func followUser(userid: String) {
        
        self.addActivityIndicatorCenter(description: "Searching for user")
        
        //follow user
        let query = PFQuery(className: "Posts")
        query.whereKey("userid", equalTo: userid)
        
        query.findObjectsInBackground(block: { (objects, error) in
            
            if let posts = objects {
                
                if posts.count > 0 {
                    
                    //user exists, follow them, add username to coredata
                    let username = posts[0]["username"] as! String
                    
                   let followed = saveFollowedUserToCoreData(viewController: self, username: username, userId: userid)
                    
                    if followed {
                        
                        func success() {
                           
                            self.activityCenter.remove()
                            let successView = SuccessAlertView()
                            successView.labelText = "You followed \(username)"
                            successView.addSuccessView(viewController: self)
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                
                                self.dismiss(animated: true, completion: nil)
                                
                            }
                            
                        }
                        
                        if let imagedata = posts[0]["userProfile"] as? PFFileObject {
                            
                            if let photo = imagedata as? PFFileObject {
                                photo.getDataInBackground(block: {
                                    PFDataResultBlock in
                                    if PFDataResultBlock.1 == nil {//PFDataResultBlock.1 is Error
                                        saveImageToCoreData(viewController: self, imageData: PFDataResultBlock.0!, userId: userid)
                                        success()
                                    } else {
                                        success()
                                    }
                                })
                            } else {
                                success()
                            }
                        } else {
                            
                            success()
                        }
                        
                    } else {
                        
                        self.activityCenter.remove()
                        displayAlert(viewController: self, title: "Error", message: "We had an error following that user, please check your internet connection")
                    }
                    
                    
                } else {
                    
                    self.activityCenter.remove()
                    
                    //user doesnt exist
                    let alert = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: NSLocalizedString("\(userid), does not exist!", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
                    
                    alert.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .default, handler: { (action) in
                        
                        DispatchQueue.main.async {
                            self.captureSession.startRunning()
                        }
                        
                    }))
                    
                    self.present(alert, animated: true, completion: nil)
                    
                }
                
            }
            
        })
        
    }
    
    func addActivityIndicatorCenter(description: String) {
        
        DispatchQueue.main.async {
            
            self.activityCenter.activityDescription = description
            self.activityCenter.add(viewController: self)
            
        }
        
    }

}
