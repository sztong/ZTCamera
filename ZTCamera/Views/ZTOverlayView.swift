//
//  ZTOverlayView.swift
//  ZTKamera
//
//  Created by Tony.su on 2017/12/25.
//  Copyright © 2017年 Tony.su. All rights reserved.
//

import UIKit

class ZTOverlayView: UIView {

    @IBOutlet weak var modeView:ZTCameraModeView!
    @IBOutlet weak var statusView:ZTStatusView!
    
    var flashControlHidden = false {
        didSet {
            self.statusView.flashControl.isHidden = flashControlHidden
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = UIColor.clear
        self.modeView.addTarget(self, action: #selector(modeChange(modeView:)), for: .valueChanged)
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if self.statusView.point(inside: self.convert(point, to: self.statusView), with: event)
            ||
            self.modeView.point(inside: self.convert(point, to: self.modeView), with: event) {
            return true
        }
        return false
    }
    
    @objc func modeChange(modeView: ZTCameraModeView) {
        
        let photoModeEnabled = modeView.cameraMode == .photo
        let toColor = photoModeEnabled ? UIColor.black : UIColor(white: 0.0, alpha: 0.5)
        let toOpacity:Float = photoModeEnabled ? 0.0 : 1.0
        self.statusView.layer.backgroundColor = toColor.cgColor
        self.statusView.elapsedTimeLabel.layer.opacity = toOpacity
        
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
