//
//  ZTCaptureButton.swift
//  ZTKamera
//
//  Created by Tony.su on 2017/12/23.
//  Copyright © 2017年 Tony.su. All rights reserved.
//

import UIKit

enum ZTCaptureButtonMode {
    case photo
    case video
}

class ZTCaptureButton: UIButton {

    var captureButtonMode:ZTCaptureButtonMode = .photo{
        didSet{
            let color = captureButtonMode == .video ? UIColor.red : UIColor.white
            self.circleLayer.backgroundColor = color.cgColor
        }
    }
    var circleLayer:CALayer!
    
    init(withCaptureButtonMode captureButtonMode:ZTCaptureButtonMode) {
        self.captureButtonMode = captureButtonMode
        super.init(frame: CGRect(x: 0, y: 0, width: 68, height: 68))
        setupView()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        captureButtonMode = .photo
        self.setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    override var isHighlighted: Bool{
        didSet{
            let fadeAnimation = CABasicAnimation(keyPath: "opacity")
            fadeAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
            fadeAnimation.duration = 0.2
            if isHighlighted {
                fadeAnimation.toValue = 0.0
            }else{
                fadeAnimation.toValue = 1.0
            }
            self.circleLayer.opacity = Float(fadeAnimation.toValue as! CGFloat)
            self.circleLayer.add(fadeAnimation, forKey: "fadeAnimation")
        }
    }
    
    override var isSelected: Bool{
        didSet{
            if self.captureButtonMode == .video {
                CATransaction.disableActions()
                let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
                let radiusAnimation = CABasicAnimation(keyPath: "cornerRadius")
                if isSelected {
                    scaleAnimation.toValue = 0.6
                    radiusAnimation.toValue = self.circleLayer.bounds.size.width / 4.0
                }else{
                    scaleAnimation.toValue = 1.0
                    radiusAnimation.toValue = self.circleLayer.bounds.size.width / 2.0
                }
                scaleAnimation.fillMode = kCAFillModeForwards
                radiusAnimation.fillMode = kCAFillModeForwards
                
                let animationGroup = CAAnimationGroup()
                animationGroup.animations = [scaleAnimation,radiusAnimation]
                animationGroup.beginTime = CACurrentMediaTime() + 0.2
                animationGroup.duration = 0.35
                self.circleLayer.setValue(CGFloat(radiusAnimation.toValue as! CGFloat), forKey: "cornerRadius")
//                self.circleLayer.setValue(scaleAnimation.toValue as! NSNumber, forKey: "transform.scale") //无效
                self.circleLayer.transform = CATransform3DMakeScale(scaleAnimation.toValue as! CGFloat, scaleAnimation.toValue as! CGFloat, 1.0)
                self.circleLayer.add(animationGroup, forKey: "scaleAndRadiusAnimation")
            }
        }
    }
    
    func setupView() {
        
        self.backgroundColor = UIColor.clear
        self.tintColor = UIColor.clear
        let circleColor = self.captureButtonMode == .video ? UIColor.red : UIColor.white
        circleLayer = CALayer()
        circleLayer.backgroundColor = circleColor.cgColor
        circleLayer.bounds = self.bounds.insetBy(dx: 8.0, dy: 8.0)
        circleLayer.position = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        circleLayer.cornerRadius = circleLayer.bounds.size.width / 2.0
        self.layer.addSublayer(circleLayer)
    }
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        context?.setStrokeColor(UIColor.white.cgColor)
        context?.setFillColor(UIColor.white.cgColor)
        context?.setLineWidth(6.0)
        let insetRect = rect.insetBy(dx: 6.0 / 2.0, dy: 6.0 / 2.0)
        context?.strokeEllipse(in: insetRect)
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
