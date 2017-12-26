//
//  ZTFlashContrrol.swift
//  ZTKamera
//
//  Created by Tony.su on 2017/12/23.
//  Copyright © 2017年 Tony.su. All rights reserved.
//

import UIKit

protocol ZTFlashContrrolDelegate {
    func flashControlWillExpand()
    func flashControlDidExpand()
    func flashControlWillCollapse()
    func flashControlDidCollapse()
}

private let BUTTON_WIDTH:CGFloat = 48.0
private let BUTTON_HEIGHT:CGFloat = 38.0
private let ICON_WIDTH:CGFloat = 18.0
private let FONT_SIZE:CGFloat = 17.0

private let BOLD_FONT:UIFont = UIFont(name: "AvenirNextCondensed-DemiBold", size: FONT_SIZE)!
private let NORMAL_FONT:UIFont = UIFont(name: "AvenirNextCondensed-Medium", size: FONT_SIZE)!

class ZTFlashContrrol: UIControl {

    var selectedMode: NSInteger = 0{
        didSet {
            self.sendActions(for: .valueChanged)
        }
    }
    var delegate: ZTFlashContrrolDelegate?
    
    private var expanded = false
    private var defaultWidth:CGFloat = 0.0
    private var expandedWidth:CGFloat = 0.0
    private var selectedIndex:NSInteger = 0{
        didSet {
            var mode = selectedIndex
            if selectedIndex == 0 {
                mode = 2
            }else if selectedIndex == 2{
                mode = 0
            }
            self.selectedMode = mode
        }
    }
    private var midY:CGFloat = 0.0
    private var labels:[UILabel] = [UILabel]()
    
    override init(frame: CGRect) {
        super.init(frame: CGRect(x: frame.minX, y: frame.minY, width: BUTTON_WIDTH, height: BUTTON_HEIGHT))
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    
    private func setupView() {
        self.backgroundColor = UIColor.clear
        let iconImage = UIImage(named: "flash_icon")
        let imageView = UIImageView(image: iconImage)
        imageView.frameY = (self.frameHeight - imageView.frameHeight) / 2
        self.addSubview(imageView)
        midY = CGFloat(floorf(Float(self.frameWidth - BUTTON_WIDTH)) / 2.0)
        self.labels = buildLabels(strings: ["Auto","On","Off"])
        
        defaultWidth = self.frameWidth
        expandedWidth = ICON_WIDTH + BUTTON_WIDTH * CGFloat(self.labels.count)
        self.clipsToBounds = true
        self.addTarget(self, action: #selector(selectMode(sender:event:)), for: .touchUpInside)
    }
    
    private func buildLabels(strings: [String]) -> [UILabel] {
        var x = ICON_WIDTH
        var first = true
        var labels = [UILabel]()
        for str in strings {
            let rect = CGRect(x: x, y: self.midY, width: BUTTON_WIDTH, height: BUTTON_HEIGHT)
            let label = UILabel(frame: rect)
            label.text = str
            label.font = NORMAL_FONT
            label.textColor = UIColor.white
            label.backgroundColor = UIColor.clear
            label.textAlignment = first ? .left : .center
            first = false
            self.addSubview(label)
            labels.append(label)
            x+=BUTTON_HEIGHT
        }
        return labels
    }
    
    @objc private func selectMode(sender : AnyObject,event: UIEvent) {
        
        if !self.expanded {
            
            delegate?.flashControlWillExpand()
            UIView.animate(withDuration: 0.3,
                           animations: {
                            self.frameWidth = self.expandedWidth
                            for i in 0..<self.labels.count {
                                let label = self.labels[i]
                                label.font = i == self.selectedIndex ? BOLD_FONT : NORMAL_FONT
                                label.frame = CGRect(x: ICON_WIDTH + (CGFloat(i) * BUTTON_WIDTH), y: self.midY, width: BUTTON_WIDTH, height: BUTTON_HEIGHT)
                                if i > 0 {
                                    label.textAlignment = .center
                                }
                            }
            },
                           completion: { (complete) in
                            self.delegate?.flashControlDidExpand()
            })
        }else {
            delegate?.flashControlWillCollapse()
            let touch = event.allTouches?.first
            for i in 0..<self.labels.count {
                let label = self.labels[i]
                if let touchPoint = touch?.location(in: label) {
                    if label.point(inside: touchPoint, with: event) {
                        self.selectedIndex = i
                        label.textAlignment = .left
                        UIView.animate(withDuration: 0.2,
                                       animations: {
                                        for i in 0..<self.labels.count {
                                            let lab = self.labels[i]
                                            if i < self.selectedIndex {
                                                lab.frame = CGRect(x: ICON_WIDTH, y: self.midY, width: 0, height: BUTTON_HEIGHT)
                                            }else if i > self.selectedIndex {
                                                lab.frame = CGRect(x: ICON_WIDTH + BUTTON_WIDTH, y: 0, width: 0, height: BUTTON_HEIGHT)
                                            }else if i == self.selectedIndex {
                                                lab.frame = CGRect(x: ICON_WIDTH, y: self.midY, width: BUTTON_WIDTH, height: BUTTON_HEIGHT)
                                            }
                                        }
                                        self.frameWidth = self.defaultWidth
                        },
                                       completion: { (complete) in
                                        self.delegate?.flashControlDidCollapse()
                        })
                        break
                    }
                }
                
            }
            
        }
        self.expanded = !self.expanded
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
