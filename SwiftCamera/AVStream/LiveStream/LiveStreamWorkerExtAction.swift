//
//  LiveStreamWorkerExtAction.swift
//  SwiftCamera
//
//  Created by JosephChen on 2018/6/27.
//  Copyright © 2018年 JosephChen. All rights reserved.
//

import Foundation
import AVFoundation

extension LiveStreamWorker {
    
    func startStreaming() {        
        
        self.videoEncoder.startRunning()
        self.audioEncoder.startRunning()
        
        self.liveCaptureQueue.async {
            /*
             Setup the capture session.
             In general it is not safe to mutate an AVCaptureSession or any of its
             inputs, outputs, or connections from multiple threads at the same time.
             
             Why not do all of this on the main queue?
             Because -[AVCaptureSession startRunning] is a blocking call which can
             take a long time. We dispatch session setup to the sessionQueue so
             that the main queue isn't blocked, which keeps the UI responsive.
             */
            self.liveCaptureSession.startRunning()
        }
    }
    
    func stopStreaming() {
        
        self.videoEncoder.stopRunning()
        self.audioEncoder.stopRunning()
        
        self.liveCaptureQueue.async {
            self.liveCaptureSession.stopRunning()
        }
    }
    
    func updateVideoOrientation(_ orientation: AVCaptureVideoOrientation) {
        
        guard let myVideoDataOutput = self.myVideoDataOutput,
            let connection = myVideoDataOutput.connection(with: .video) else {
            return
        }
        if connection.isVideoOrientationSupported {
            connection.videoOrientation = orientation
        }
    } 
}