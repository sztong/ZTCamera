//
//  ZTCameraModeView.swift
//  ZTKamera
//
//  Created by Tony.su on 2017/12/23.
//  Copyright © 2017年 Tony.su. All rights reserved.
//

import UIKit

enum ZTCameraMode {
    case photo
    case video
}

class ZTCameraModeView: UIControl {
    
    let captureButton:ZTCaptureButton={
       var btn = ZTCaptureButton(withCaptureButtonMode: .video)
        return btn
    }()
    var cameraMode:ZTCameraMode = .photo{
        didSet {
            if  cameraMode == .photo {
                self.captureButton.isSelected = false
                self.captureButton.captureButtonMode = .photo
                self.layer.backgroundColor = UIColor.black.cgColor
            }else{
                self.captureButton.captureButtonMode = .video
                self.layer.backgroundColor = UIColor(white: 0.0, alpha: 0.5).cgColor
            }
            self.sendActions(for: .valueChanged)
        }
    }
    
    private let foregroundColor = {
       return UIColor(red: 1.000, green: 0.734, blue: 0.006, alpha: 1.000)
    }()
    var videoTextLayer: CATextLayer!
    var photoTextLayer: CATextLayer!
    var labelContainerView: UIView!
    var maxLeft:Bool! = false
    var maxRight:Bool! = false
    var videoStringWidth:CGFloat = 0.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    func setupView() {
        
        maxRight = true
        self.cameraMode = .video
        
        self.backgroundColor = UIColor(white: 0.000, alpha: 0.500)
        videoTextLayer = textLayer(withTitle: "VIDEO")
        videoTextLayer.foregroundColor = self.foregroundColor.cgColor
        photoTextLayer = textLayer(withTitle: "PHOTO")
        
        let str:NSString = "VIDEO"
        let size = str.size(withAttributes: fontAttrributes())
        videoStringWidth = size.width
        videoTextLayer.frame = CGRect(x: 0, y: 0, width: 40, height: 20)
        photoTextLayer.frame = CGRect(x: 60, y: 0, width: 50, height: 20)
        let containerRect = CGRect(x: 0, y: 8, width: 120, height: 20)
        labelContainerView = UIView(frame: containerRect)
        labelContainerView.backgroundColor = UIColor.clear
        
        labelContainerView.layer.addSublayer(videoTextLayer)
        labelContainerView.layer.addSublayer(photoTextLayer)
        self.addSubview(labelContainerView)
        
        self.addSubview(self.captureButton)
        
        let rightRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(switcMode(recognizer:)))
        let leftRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(switcMode(recognizer:)))
        leftRecognizer.direction = .left
        self.addGestureRecognizer(rightRecognizer)
        self.addGestureRecognizer(leftRecognizer)
        
        NotificationCenter.addObserver(self, selector: #selector(startRecording(notification:)), name: .startRecording, object: nil)
        NotificationCenter.addObserver(self, selector: #selector(stopRecording(notification:)), name: .stopRecording, object: nil)
        
    }
    
    @objc func switcMode(recognizer: UISwipeGestureRecognizer) {
        
        if recognizer.direction == .left && !self.maxLeft {
            UIView.animate(withDuration: 0.28,
                           delay: 0,
                           options: .curveEaseInOut,
                           animations: {
                            self.labelContainerView.frameX -= 62
                            UIView.animate(withDuration: 0.3,
                                           delay: 0.3,
                                           options: .curveLinear,
                                           animations: {
                                            CATransaction.disableActions()
                                            self.photoTextLayer.foregroundColor = self.foregroundColor.cgColor
                                            self.videoTextLayer.foregroundColor = UIColor.white.cgColor
                            },
                                           completion: { (commplete) in
                                            
                            })
            },
                           completion: { (complete) in
                            self.cameraMode = .photo
                            self.maxLeft = true
                            self.maxRight = false
            })
        }else if recognizer.direction == .right && !self.maxRight {
            UIView.animate(withDuration: 0.28,
                           delay: 0,
                           options: .curveEaseInOut,
                           animations: {
                            self.labelContainerView.frameX += 62
                            self.videoTextLayer.foregroundColor = self.foregroundColor.cgColor
                            self.photoTextLayer.foregroundColor = UIColor.white.cgColor
            },
                           completion: { (complete) in
                            self.cameraMode = .video
                            self.maxRight = true
                            self.maxLeft = false
            })
        }
    }
    
    
    func textLayer(withTitle title: String) -> CATextLayer {
        let layer = CATextLayer()
        layer.string = title
        layer.font = UIFont(name: "AvenirNextCondensed-DemiBold", size: 17)
        layer.fontSize = 17
        layer.contentsScale = UIScreen.main.scale
        return layer
    }
    
    func fontAttrributes() -> [NSAttributedStringKey : Any] {
        
        return [NSAttributedStringKey.font : UIFont(name: "AvenirNextCondensed-DemiBold", size: 17.0) as Any,
                NSAttributedStringKey.foregroundColor : UIColor.white as Any]
    }
    
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(self.foregroundColor.cgColor)
        let circleRect = CGRect(x: rect.midX - 4.0, y: 2.0, width: 6.0, height: 6.0)
        context?.fillEllipse(in: circleRect)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        var frame = self.labelContainerView.frame
        frame.origin.x = self.bounds.midX - CGFloat(self.videoStringWidth / 2.0)
        self.labelContainerView.frame = frame
        self.captureButton.center = CGPoint(x: self.frame.midX, y: self.frame.height - 8 - self.captureButton.frame.height / 2.0)
    }
    
    
    @objc func startRecording(notification: NSNotification){
        self.labelContainerView.isHidden = true;
    }
    
    @objc func stopRecording(notification: NSNotification){
        self.labelContainerView.isHidden = false;
    }
    
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
}
