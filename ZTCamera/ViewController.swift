//
//  ViewController.swift
//  ZTCamera
//
//  Created by Tony.su on 2017/12/26.
//  Copyright © 2017年 Tony.su. All rights reserved.
//

import UIKit
import MobileCoreServices
import AVFoundation

class ViewController: UIViewController {
    
    @IBOutlet weak var previewView: ZTPreviewView!
    @IBOutlet weak var overlayView: ZTOverlayView!
    var cameraMode = ZTCameraMode.video
    var cameraController:ZTCameraController!
    @IBOutlet weak var thumbnailButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        NotificationCenter.default.addObserver(self, selector: #selector(updateTumbnail(notification:)), name: NSNotification.Name(ZTThumbnailCreatedNotification), object: nil)
        cameraController = ZTCameraController()
        if cameraController.setupSession(error: NSError()) {
            self.previewView.session = self.cameraController?.captureSession
            self.previewView.delegate = self
            self.cameraController.startSession()
        }
        self.previewView.tapToExposeEnable = self.cameraController.cameraSupportsTapToExpose
        self.previewView.tapTopFocusEnabled = self.cameraController.cameraSupportsTapToFocus
        
        self.overlayView.modeView.addTarget(self, action: #selector(cameraModeChange(sender:)), for: .valueChanged)
        self.overlayView.modeView.captureButton.addTarget(self, action: #selector(captureOrRecord(_:)), for: .touchUpInside)
        self.overlayView.statusView.flashControl.addTarget(self, action: #selector(flashControlChange(sender:)), for: .valueChanged)
        
        
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    @objc func cameraModeChange(sender: ZTCameraModeView) {
        self.cameraMode = sender.cameraMode
        if self.cameraMode == .photo {
            self.cameraController.torchMode = .auto //切换到photo的时候把video的手电筒重置为auto
        }
        print(self.cameraMode)
    }
    
    @objc func flashControlChange(sender: ZTFlashContrrol) {
        let mode = sender.selectedMode
        if self.cameraMode == .photo {
            if let flashMode = AVCaptureDevice.FlashMode(rawValue: mode) {
                self.cameraController.flashMode = flashMode
            }
        }else{
            if let torchMode = AVCaptureDevice.TorchMode(rawValue: mode) {
                self.cameraController.torchMode = torchMode
            }
            
        }
    }
    
    @IBAction func swapCameras(_ sender: UIButton) {
        
        if self.cameraController.switchCameras() {
            var hidden = false
            if self.cameraMode == .photo {
                hidden = !self.cameraController.cameraHasFlash
            }else{
                hidden = !self.cameraController.cameraHasTorch
            }
            self.overlayView.flashControlHidden = hidden;
            self.previewView.tapToExposeEnable = self.cameraController.cameraSupportsTapToExpose
            self.previewView.tapTopFocusEnabled = self.cameraController.cameraSupportsTapToFocus
            self.cameraController .resetFocusAndExposureModes()
        }
        
    }
    
    @objc func captureOrRecord(_ sender: UIButton) {
        
        if self.cameraMode == .photo {
            self.cameraController.captureStillImage()
        }else{
            if !self.cameraController.isRecording() {
                DispatchQueue(label: "com.tony.kcmera").async {
                    self.cameraController.startRecording()
                }
            }else{
                self.cameraController.stopRecording()
            }
            sender.isSelected = !sender.isSelected
        }
        
    }
    
    @objc func updateTumbnail(notification: NSNotification){
        guard let image = notification.object as? UIImage else {
            return
        }
        self.thumbnailButton.setBackgroundImage(image, for: .normal)
        self.thumbnailButton.layer.borderColor = UIColor.white.cgColor
        self.thumbnailButton.layer.borderWidth = 1.0
        
    }
    
    @IBAction func showCameraRoll(_ sender: UIButton) {
        
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.mediaTypes = [kUTTypeImage as String,kUTTypeMovie as String]
        self.present(vc, animated: true, completion: nil)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

extension ViewController :ZTPreviewViewDelegate {
    
    func tappedToFocusAt(point: CGPoint) {
        self.cameraController.focusAt(point: point)
    }
    
    func tappedToExposeAt(point: CGPoint) {
        self.cameraController.exposeAt(point: point)
    }
    
    func tappedToResetFocusAndExposure() {
        self.cameraController .resetFocusAndExposureModes()
    }
}

