//
//  UIControlPanelView.swift
//  SwiftCamera
//
//  Created by JosephChen on 2018/7/18.
//  Copyright © 2018年 JosephChen. All rights reserved.
//

import Foundation
import UIKit
import ReactiveCocoa
import Stevia

class UIControlPanelViewController: UIViewController {
    var streamManager: AVStreamManager!
    let btnRecord = UIButton()
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {        
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    convenience init(streamManager: AVStreamManager) {
        self.init(nibName: nil, bundle: nil)
        self.streamManager = streamManager
    }
    
    override func viewDidLoad() {
        
        self.render()
        self.action()
    }
    
    func render() {
        
        self.view.backgroundColor = UIColor.black
        
        self.view.sv(
            btnRecord
        )
        
        self.view.layout(
            8,
            btnRecord.width(150).centerHorizontally(),
            8
        )
        
        self.btnRecord.style { (btn) in
            
            btn.setTitle("Rec", for: .normal)
            btn.layer.borderColor = UIColor.gray.cgColor
            btn.layer.borderWidth = 2.0
        }
    }
    
    func action() {
        
        let clickSignal = self.btnRecord.reactive.controlEvents(.touchUpInside)
        clickSignal.observeValues { (btn) in
            self.streamManager.startRecording()
        }
        
        self.streamManager.isRecording.signal.observeValues { (val) in
            self.btnRecord.isEnabled = !val
            if val {
                self.btnRecord.backgroundColor = UIColor.red
            }
            else {
                self.btnRecord.backgroundColor = UIColor.clear
            }
        }
    }
    
}
