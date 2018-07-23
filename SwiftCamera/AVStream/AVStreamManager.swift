//
//  AVStreamManager.swift
//  SwiftCamera
//
//  Created by JosephChen on 2018/6/28.
//  Copyright © 2018年 JosephChen. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import ReactiveCocoa
import ReactiveSwift
import Result


class AVStreamManager: NSObject {
    
    static let shared = AVStreamManager()
    
    var livestreamWorker: LiveStreamWorker!
    var videoCaptureSession: AVCaptureSession {
        get {
            return self.livestreamWorker.liveCaptureSession
        }
    }
    var isCapturing: MutableProperty<Bool> {
        get {
            return self.livestreamWorker.isCapturing
        }
    }
    var isRecording: MutableProperty<Bool> {
        get {
            return self.livestreamWorker.isRecording
        }
    }
    
    class var videoOrientation: AVCaptureVideoOrientation {
        get {
            
            switch UIApplication.shared.statusBarOrientation {
            case .landscapeLeft:
                return .landscapeLeft
            case .landscapeRight:
                return .landscapeRight
            default:
                return .landscapeLeft
            }
        }
    }
    
    override init() {
        super.init()
        self.livestreamWorker = LiveStreamWorker()
        
        NotificationCenter.default.reactive.notifications(forName: .UIApplicationDidEnterBackground).observe
            { (signal) in
            self.livestreamWorker.stopStreaming()
        }
        
        NotificationCenter.default.reactive.notifications(forName: .UIApplicationWillEnterForeground).observe
            { (signal) in
            self.livestreamWorker.startStreaming()
        }
    }
    
    func startRunning() {
        
        self.livestreamWorker.startCapture(orientation: AVStreamManager.videoOrientation)
    }
    
    func startRecording() {
        
        self.livestreamWorker.startRecording()
    }
    
    func stopRecording() {
        
        self.livestreamWorker.stopRecording()
    }
    
    func updateVideoOrientation(_ orientation: AVCaptureVideoOrientation) {
        
        self.livestreamWorker.updateVideoOrientation(orientation)
    }
    
}
