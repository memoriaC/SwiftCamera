//
//  AVCamPreviewView.swift
//  SwiftCamera
//
//  Created by JosephChen on 2018/6/27.
//  Copyright © 2018年 JosephChen. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

public class AVCamPreviewView: UIView {
    
    var session: AVCaptureSession? {
        get {
            return (self.layer as! AVCaptureVideoPreviewLayer).session
        }
        set(newSession) {
            (self.layer as! AVCaptureVideoPreviewLayer).session = newSession
        }
    }
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        get {
            return self.layer as! AVCaptureVideoPreviewLayer
        }
    }
    
    override public class var layerClass: AnyClass {
        get {
            return AVCaptureVideoPreviewLayer.self
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    convenience init(frame: CGRect, session: AVCaptureSession, orientation: AVCaptureVideoOrientation) {
        self.init(frame: frame)
        self.session = session
        self.videoPreviewLayer.videoGravity = .resizeAspectFill
        self.updateVideoOrientation(orientation)
    }
    
    public func updateVideoOrientation(_ orientation: AVCaptureVideoOrientation) {
    
        guard let connection = self.videoPreviewLayer.connection else { return }
        if connection.isVideoOrientationSupported {
            connection.videoOrientation = orientation
        }
    }
}
