//
//  LiveStreamWorker.swift
//  SwiftCamera
//
//  Created by JosephChen on 2018/6/27.
//  Copyright © 2018年 JosephChen. All rights reserved.
//

import Foundation
import AVFoundation
import ReactiveSwift

class LiveStreamWorker: NSObject {
    
    public var liveCaptureSession: AVCaptureSession!
    public var isCapturing: MutableProperty<Bool>!
    public var isRecording: MutableProperty<Bool> {
        get {
            guard let writter = self.movieWritter else { return MutableProperty(false) }
            return writter.isWritting
        }
    }
    var liveCaptureQueue: DispatchQueue!
    var myVideoDataOutput: AVCaptureVideoDataOutput?
    var myAudioDataOutput: AVCaptureAudioDataOutput?
    var videoGrantedResult: MutableProperty<Bool>!
    var videoSetupResult: MutableProperty<Bool>!
    var orientation: AVCaptureVideoOrientation!
    var videoEncoder: H264Encoder!
    var audioEncoder: ULawEncoder!
    var movieWritter: MediaFileWriter?
    
    class func getCaptureDevice(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        
        // TODO: Camera type
        let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
        return device
    }
    
    override init() {
        super.init()
        
        self.videoGrantedResult = MutableProperty(false)
        self.videoSetupResult = MutableProperty(false)
        self.isCapturing = MutableProperty(false)
        
        self.liveCaptureQueue = DispatchQueue(label: "liveCaptureQueue")
        self.liveCaptureSession = AVCaptureSession()
        self.orientation = .landscapeRight
        self.videoEncoder = H264Encoder.init()
        self.audioEncoder = ULawEncoder.init()
        self.movieWritter = MediaFileWriter.init()
        
        self.videoGrantedResult.signal.observeValues { (val) in
            if val == true {
                DispatchQueue.main.async {
                    self.setupAVCaptureSession()
                }
            }
        }
        
        self.videoSetupResult.signal.observeValues { (val) in
            if val == true {
                self.liveCaptureQueue.async {
                    self.startStreaming()
                }
            }
        }
    }
    
    public func startCapture(orientation: AVCaptureVideoOrientation) {
        self.orientation = orientation
        self.requireAuthorization()
    }
    
    func requireAuthorization() {
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.videoGrantedResult.value = true
            break
        case .denied:
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { (granted) in
                if (granted) {
                    self.videoGrantedResult.value = true
                }
            }
        case .restricted:
            break
        }
        
    }
    
    func setupAVCaptureSession() {
        
        guard self.videoGrantedResult.value == true else { return }
        
        self.liveCaptureSession.beginConfiguration()
        defer {
            self.liveCaptureSession.commitConfiguration()
            self.videoSetupResult.value = true
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
            connection.videoOrientation = self.orientation
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
