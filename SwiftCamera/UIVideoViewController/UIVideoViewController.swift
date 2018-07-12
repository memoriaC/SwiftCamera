//
//  UIVideoViewController.swift
//  SwiftCamera
//
//  Created by JosephChen on 2018/6/27.
//  Copyright © 2018年 JosephChen. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class UIVideoViewController: UIViewController {
    
    var previewView: AVCamPreviewView!
    var myAVStreamManager = AVStreamManager.shared
    
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.previewView = AVCamPreviewView(frame:self.view.bounds, session:self.myAVStreamManager.videoCaptureSession, orientation:AVStreamManager.videoOrientation)
        self.view.layer.addSublayer(self.previewView.videoPreviewLayer)
        self.view.addSubview(self.previewView)
        
        let tmpView = UIView()
        tmpView.backgroundColor = UIColor.black
        tmpView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(tmpView)
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[tmpView]|", options: .directionLeadingToTrailing, metrics: nil, views: ["tmpView" : tmpView]))
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[tmpView(32)]-|", options: .directionLeadingToTrailing, metrics: nil, views: ["tmpView" : tmpView]))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.myAVStreamManager.startRunning()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        var orientation: AVCaptureVideoOrientation
        switch UIDevice.current.orientation {
        case .landscapeLeft:
            orientation = .landscapeRight
        case .landscapeRight:
            orientation = .landscapeLeft
        default:
            orientation = .landscapeRight
            break
        }
        
        self.previewView.updateVideoOrientation(orientation)
        self.myAVStreamManager.updateVideoOrientation(orientation)
    }
    
}
