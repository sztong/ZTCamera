//
//  ZTPreviewView.swift
//  ZTKamera
//
//  Created by Tony.su on 2017/12/22.
//  Copyright © 2017年 Tony.su. All rights reserved.
//

import UIKit
import AVFoundation

protocol ZTPreviewViewDelegate{

    func tappedToFocusAt(point: CGPoint) //聚焦
    func tappedToExposeAt(point: CGPoint) //曝光
    func tappedToResetFocusAndExposure()  //重置聚焦&曝光
    
}


class ZTPreviewView: UIView {
    

    //session用来关联AVCaptureVideoPreviewLayer 和 激活AVCaptureSession
    var session: AVCaptureSession?{
        set (newSession) {
            (self.layer as! AVCaptureVideoPreviewLayer).session = newSession
        }
        get {
            return (self.layer as! AVCaptureVideoPreviewLayer).session
        }
    }
    var delegate: ZTPreviewViewDelegate?
    //是否聚焦
    var tapTopFocusEnabled:Bool = true{
        didSet {
            self.singleTapRecognize.isEnabled = tapTopFocusEnabled
        }
    }
    //是否曝光
    var tapToExposeEnable:Bool = true{
        didSet {
            self.doubleTapRecognize.isEnabled = tapToExposeEnable
        }
    }
    var focusBox:UIView={
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 150, height: 150))
        view.backgroundColor = UIColor.clear
        view.layer.borderColor = UIColor(red: 0.102, green: 0.636, blue: 1.000, alpha: 1.000).cgColor
        view.layer.borderWidth = 5
        view.isHidden = true
        return view
    }()
    var exposureBox:UIView={
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 150, height: 150))
        view.backgroundColor = UIColor.clear
        view.layer.borderColor = UIColor(red: 1.000, green: 0.421, blue: 0.054, alpha: 1.000).cgColor
        view.layer.borderWidth = 5
        view.isHidden = true
        return view
    }()
    var singleTapRecognize:UITapGestureRecognizer!
    var doubleTapRecognize:UITapGestureRecognizer!
    var doubleDoubleTapRecognize:UITapGestureRecognizer!
    
    override open class var layerClass: Swift.AnyClass {
        get{
            return AVCaptureVideoPreviewLayer.self
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    func setupView() {
        singleTapRecognize = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(recognizer:)))
        self.addGestureRecognizer(singleTapRecognize)
        
        doubleTapRecognize = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(recognizer:)))
        doubleTapRecognize.numberOfTapsRequired = 2
        self.addGestureRecognizer(doubleTapRecognize)
        
        doubleDoubleTapRecognize = UITapGestureRecognizer(target: self, action: #selector(handleDoubleDoubleTap(recognizer:)))
        doubleDoubleTapRecognize.numberOfTapsRequired = 2
        doubleDoubleTapRecognize.numberOfTouchesRequired = 2
        self.addGestureRecognizer(doubleDoubleTapRecognize)
        
        singleTapRecognize.require(toFail: doubleTapRecognize)
        self.isUserInteractionEnabled = true
        self.addSubview(focusBox)
        self.addSubview(exposureBox)
        
    }

    
    func captureDevicePointFor(point: CGPoint) -> CGPoint {
        
        let layer: AVCaptureVideoPreviewLayer = self.layer as! AVCaptureVideoPreviewLayer
        return layer.captureDevicePointConverted(fromLayerPoint:point)
    }
    
    
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}

extension ZTPreviewView {
    
    
    @objc func handleSingleTap(recognizer:UITapGestureRecognizer) -> Void {
        let point:CGPoint = recognizer.location(in: self)
        runBoxAnimationOn(view: focusBox, point: point)
        delegate?.tappedToFocusAt(point: self.captureDevicePointFor(point: point))
    }
    @objc func handleDoubleTap(recognizer:UITapGestureRecognizer) -> Void {
        let point:CGPoint = recognizer.location(in: self)
        runBoxAnimationOn(view: exposureBox, point: point)
        delegate?.tappedToExposeAt(point: captureDevicePointFor(point: point))
    }
    @objc func handleDoubleDoubleTap(recognizer:UITapGestureRecognizer) -> Void {
        runResetAnimation()
        delegate?.tappedToResetFocusAndExposure()
    }
    
    
    func runBoxAnimationOn(view:UIView,point:CGPoint) {
        view.center = point
        view.isHidden = false
        UIView.animate(withDuration: 0.15,
                       delay: 0.0,
                       options: .curveEaseInOut,
                       animations: {
                        view.layer.transform = CATransform3DMakeScale(0.5, 0.5, 1.0)
        }) { (complete:Bool) in
            let delayInSecondds:Double = 0.5
            
            let popTime: DispatchTime = DispatchTime(uptimeNanoseconds: (UInt64(delayInSecondds) * NSEC_PER_SEC))
            DispatchQueue.main.asyncAfter(deadline: popTime, execute: {
                view.isHidden = true
                view.transform = CGAffineTransform.identity
            })
        }
    }
    
    func runResetAnimation() {
        
        if !tapTopFocusEnabled && !tapToExposeEnable {
            return
        }
        
        let previewLayer:AVCaptureVideoPreviewLayer = self.layer as! AVCaptureVideoPreviewLayer
        let center:CGPoint = previewLayer.layerPointConverted(fromCaptureDevicePoint: CGPoint(x: 0.5, y: 0.5))
        focusBox.center = center
        exposureBox.center = center
        exposureBox.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        focusBox.isHidden = false
        exposureBox.isHidden = false
        UIView.animate(withDuration: 0.15,
                       delay: 0.0,
                       options: .curveEaseOut,
                       animations: {
                        self.focusBox.layer.transform = CATransform3DMakeScale(0.5, 0.5, 1.0)
                        self.exposureBox.layer.transform = CATransform3DMakeScale(07, 0.7, 1.0)
        }) { (complete) in
            let delayInSeconds = UInt64(0.5)
            let popTime = DispatchTime(uptimeNanoseconds: delayInSeconds + NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: popTime, execute: {
                self.focusBox.isHidden = true
                self.exposureBox.isHidden = true;
                self.focusBox.transform = CGAffineTransform.identity
                self.exposureBox.transform = CGAffineTransform.identity
            })
        }
        
    }
    
    
}
