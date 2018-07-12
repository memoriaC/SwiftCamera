//
//  LiveStreamWorker.swift
//  SwiftCamera
//
//  Created by JosephChen on 2018/6/27.
//  Copyright © 2018年 JosephChen. All rights reserved.
//

import Foundation
import AVFoundation

class LiveStreamWorker: NSObject {
    
    public var liveCaptureSession: AVCaptureSession!
    var liveCaptureQueue: DispatchQueue!
    var myVideoDataOutput: AVCaptureVideoDataOutput?
    var myAudioDataOutput: AVCaptureAudioDataOutput?
    var videoGrantedResult = false
    var videoEncoder: H264Encoder!
    var audioEncoder: ULawEncoder!
    
    class func getCaptureDevice(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        
        // TODO: Camera type
        let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
        return device
    }
    
    override init() {
        super.init()
        self.liveCaptureQueue = DispatchQueue(label: "liveCaptureQueue")
        self.liveCaptureSession = AVCaptureSession()
        self.videoEncoder = H264Encoder.init()
        self.audioEncoder = ULawEncoder.init()
        
        self.requireAuthorization()
        self.setupAVCaptureSession()        
    }
    
    public func startCapture(orientation: AVCaptureVideoOrientation) {
        
        self.liveCaptureQueue.async {
            
            if self.videoGrantedResult {
                self.updateVideoOrientation(orientation)
                self.startStreaming()
            }
            else {
                print("cannot start capture, camera is not granted.")
            }
        }
    }
    
    func requireAuthorization() {
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.videoGrantedResult = true
            break
        case .denied:
            break
        case .notDetermined:
            self.liveCaptureQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video) { (granted) in
                
                if (granted) {
                    self.videoGrantedResult = true
                    self.liveCaptureQueue.resume()
                }
            }
        case .restricted:
            break
        }
    }
    
    func setupAVCaptureSession() {
        
        guard self.videoGrantedResult == true else {
            return
        }
        
        self.liveCaptureSession.beginConfiguration()
        defer {
            self.liveCaptureSession.commitConfiguration()
        }
        
        // Video
        guard self.setupVideoInput() else { return }
        self.setupVideoOutput()
        
        // Audio
        guard self.setupAudioInput() else { return }
        self.setupAudioOutput()
        
        // Set misc
        self.liveCaptureSession.sessionPreset = .high
        
        // TODO: Frame fate
//        device.activeFormat videoSupportedFrameRateRanges
        
    }
    
    func setupVideoInput() -> Bool {
        
        guard let videoDevice = LiveStreamWorker.getCaptureDevice(position: .back) else {
            print("LiveStreamWorker.getCaptureDevice(position: .back) nil")
            return false
        }
        
        do {
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            
            if self.liveCaptureSession.canAddInput(videoDeviceInput) {
                self.liveCaptureSession.addInput(videoDeviceInput)
            }
            else {
                throw NSError(domain: "self.liveCaptureSession.canAddInput(videoDeviceInput) failed", code: 0, userInfo: nil)
            }
        }
        catch {
            print("AVCaptureDeviceInput (device: videoDevice) exception")
            return false
        }
        
        return true
    }
    
    func setupVideoOutput() {
        
        self.myVideoDataOutput = AVCaptureVideoDataOutput()
        guard let myVideoDataOutput = self.myVideoDataOutput else { return }
        
        myVideoDataOutput.setSampleBufferDelegate(self, queue: self.liveCaptureQueue)
        myVideoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as String) : NSNumber(value: kCVPixelFormatType_32BGRA)]
        
        guard self.liveCaptureSession.canAddOutput(myVideoDataOutput) else {
            return
        }
        self.liveCaptureSession.addOutput(myVideoDataOutput)
        
        
        guard let connection = myVideoDataOutput.connection(with: .video) else {
            return
        }
        
        if connection.isVideoStabilizationSupported {
            connection.preferredVideoStabilizationMode = .auto
        }
        if connection.isVideoOrientationSupported {
            connection.videoOrientation = .landscapeRight
        }
    }
    
    func setupAudioInput() -> Bool {
        
        guard let device = AVCaptureDevice.default(for: .audio) else { return false }
        
        do {
            let audioInput = try AVCaptureDeviceInput(device: device)
            if self.liveCaptureSession.canAddInput(audioInput) {
                self.liveCaptureSession.addInput(audioInput)
            }
            else {
                throw NSError(domain: "self.captureSession.canAddInput(audioInput) failed", code: 0, userInfo: nil)
            }
        }
        catch {
            print("AVCaptureDeviceInput (device: audioInput) exception")
            return false
        }
        return true
    }    
    
    func setupAudioOutput() {
        
        self.myAudioDataOutput = AVCaptureAudioDataOutput()
        guard let myAudioDataOutput = self.myAudioDataOutput else { return }
        myAudioDataOutput.setSampleBufferDelegate(self, queue: self.liveCaptureQueue)
        
        guard self.liveCaptureSession.canAddOutput(myAudioDataOutput) else { return }
        self.liveCaptureSession.addOutput(myAudioDataOutput)
    }
}
