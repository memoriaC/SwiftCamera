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
            
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            
            CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)
            
            let inWidth = CVPixelBufferGetWidth(imageBuffer)
            let inHeight = CVPixelBufferGetHeight(imageBuffer)
            print("width: \(inWidth), height: \(inHeight)")
            
            self.videoEncoder.input(sampleBuffer)
            
            CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly)
        }
        
        else if output == self.myAudioDataOutput {
            
            self.audioEncoder.input(sampleBuffer)
        }
    }
}
