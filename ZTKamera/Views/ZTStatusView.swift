//
//  ZTStatusView.swift
//  ZTKamera
//
//  Created by Tony.su on 2017/12/25.
//  Copyright © 2017年 Tony.su. All rights reserved.
//

import UIKit

class ZTStatusView: UIView {
    
    var flashControl: ZTFlashContrrol! = {
       let control = ZTFlashContrrol(frame: CGRect(x: 15, y: 0, width: 48, height: 48))
        return control
    }()
    var elapsedTimeLabel: UILabel! = {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 82, height: 26))
        label.textColor = UIColor.white
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 19)
        label.text = "00:00:00"
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.elapsedTimeLabel.center = CGPoint(x: self.frame.width / 2.0, y: self.frame.height / 2.0)
        self.flashControl.center.y = self.frame.height / 2.0
    }
    
    func setupView() {
        
        self.addSubview(self.flashControl)
        self.addSubview(self.elapsedTimeLabel)
        self.flashControl.delegate = self
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}

extension ZTStatusView: ZTFlashContrrolDelegate {
    
    func flashControlWillExpand() {
        print("WillExpand")
        UIView.animate(withDuration: 0.2) {
            self.elapsedTimeLabel.alpha = 0.0
        }
    }
    
    func flashControlDidExpand() {
        print("DidExpand")
    }
    
    func flashControlWillCollapse() {
        print("WillCollapse")
    }
    
    func flashControlDidCollapse() {
        print("DidCollapse")
        UIView.animate(withDuration: 0.1) {
            self.elapsedTimeLabel.alpha = 1.0
        }
    }
    
    
}
