//
//  LiveStreamWorkerExtOnCapture.swift
//  SwiftCamera
//
//  Created by JosephChen on 2018/6/27.
//  Copyright © 2018年 JosephChen. All rights reserved.
//

import Foundation
import AVFoundation

extension LiveStreamWorker: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        if output == self.myVideoDataOutput {
            
            self.videoEncoder.input(sampleBuffer)
            self.movieWritter?.input(sampleBuffer, type: .video)
        }
        
        else if output == self.myAudioDataOutput {
            self.audioEncoder.input(sampleBuffer)
            self.movieWritter?.input(sampleBuffer, type: .audio)
        }
    }
}
