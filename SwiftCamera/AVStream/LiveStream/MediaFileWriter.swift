//
//  MediaFileWriter.swift
//  SwiftCamera
//
//  Created by JosephChen on 2018/7/17.
//  Copyright © 2018年 JosephChen. All rights reserved.
//

import Foundation
import AVFoundation
import ReactiveSwift

class MediaFileWriter: NSObject {
    
    private var shouldStop: MutableProperty<Bool> = MutableProperty(true)
    public var isWritting: MutableProperty<Bool> = MutableProperty(false)
    var recordingQueue: DispatchQueue!
    var myAssestWriter: AVAssetWriter?
    var myVideoInputWriter: AVAssetWriterInput?
    var myPixelAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    var myAudioInputWriter: AVAssetWriterInput?
    
    override init() {
        super.init()
        self.shouldStop.signal.observeValues { (val) in
            self.isWritting.value = !val
        }
        
        self.recordingQueue = DispatchQueue(label: "MediaFileWriter")
        self.myAssestWriter = nil
        self.myVideoInputWriter = nil
        self.myAudioInputWriter = nil
        
//        self.startRecording()
    }
    
    func startRecording() {
        
        self.shouldStop.value = false
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false, block: { (timer) in
            self.stopRecording()
        })
    }
    
    func stopRecording() {
        
        self.shouldStop.value = true
        self.recordingQueue.async {
            guard let writter = self.myAssestWriter else { return }
            guard let pixelAdaptor = self.myPixelAdaptor else { return }
            guard let audioWritter = self.myAudioInputWriter else { return }
            pixelAdaptor.assetWriterInput.markAsFinished()
            audioWritter.markAsFinished()
            
            self.recordingQueue.suspend()
            writter.finishWriting {
                self.myAssestWriter = nil
                self.recordingQueue.resume()
            }
            
        }
    }
    
    func input(_ sampleBuffer: CMSampleBuffer, type: AVMediaType) {
        
        guard self.shouldStop.value == false else { return }
        
        switch type {
        case .video:
            if self.myAssestWriter == nil {
                self.myAssestWriter = self.initWritter(sampleBuffer)
                guard let myWritter = self.myAssestWriter else { return }
                myWritter.startWriting()
                myWritter.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
            }
            self.appendSampleBuffer(sampleBuffer, type: type)
        case .audio:
            self.appendSampleBuffer(sampleBuffer, type: type)
        default:
            return
        }
        
    }
    
    private func appendSampleBuffer(_ sampleBuffer: CMSampleBuffer, type: AVMediaType) {
        
        self.recordingQueue.async {
            guard let writter = self.myAssestWriter else { return }
            guard writter.status == .writing else { return }
            
            switch type {
            case .video:
                guard let pixelAdaptor = self.myPixelAdaptor else { return }
                
                if pixelAdaptor.assetWriterInput.isReadyForMoreMediaData {
                    guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
                    let status = pixelAdaptor.append(pixelBuffer, withPresentationTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
                    if status != true {
                        print("myPixelAdaptor: \(status) \(String(describing: self.myAssestWriter?.error))")
                    }
                }
                else {
                    print("myPixelAdaptor frame skipped")
                }
                
            case .audio:
                guard let audioWritter = self.myAudioInputWriter else { return }
                if audioWritter.isReadyForMoreMediaData {
                    let status = audioWritter.append(sampleBuffer)
                    if status != true {
                        print("audioWritter: \(status) \(String(describing: self.myAssestWriter?.error))")
                    }
                }
                else {
                    print("audioWritter frame skipped")
                }
            default:
                return
            }
        }
    }
    
    private func initWritter(_ sampleBuffer: CMSampleBuffer) -> AVAssetWriter? {
        
        guard let file = FileHandle.getDataFilePath(type: .MovieFile) else { return nil }
        try? FileManager.default.removeItem(atPath: file)
        
        do {
            let writter = try AVAssetWriter.init(url: URL.init(fileURLWithPath: file), fileType: .mov)
            
            // Video
            self.myVideoInputWriter = self.initVideoWritter(sampleBuffer)
            guard let myVideoWritter = self.myVideoInputWriter else { return nil }
            self.myPixelAdaptor = AVAssetWriterInputPixelBufferAdaptor.init(assetWriterInput: myVideoWritter, sourcePixelBufferAttributes: nil)
            if writter.canAdd(myVideoWritter) {
                writter.add(myVideoWritter)
            }
            
            // Audio
            self.myAudioInputWriter = self.initAudioWritter()
            guard let myAudioWritter = self.myAudioInputWriter else { return nil }
            if writter.canAdd(myAudioWritter) {
                writter.add(myAudioWritter)
            }
            
            return writter
        }
        catch {
            
        }
        
        return nil
    }
    
    private func initVideoWritter(_ sampleBuffer: CMSampleBuffer) -> AVAssetWriterInput? {
        
        guard let imageBuf = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let frameSize = CVImageBufferGetEncodedSize(imageBuf)
        let myVideoWritter = AVAssetWriterInput.init(mediaType: .video, outputSettings: [AVVideoCodecKey: AVVideoCodecType.h264,
                                                                                         AVVideoWidthKey: frameSize.width,
                                                                                         AVVideoHeightKey: frameSize.height])
        myVideoWritter.expectsMediaDataInRealTime = true
        
        return myVideoWritter
    }
    
    private func initAudioWritter() -> AVAssetWriterInput? {
        
        let myAudioWritter = AVAssetWriterInput.init(mediaType: .audio, outputSettings: [AVFormatIDKey: kAudioFormatMPEG4AAC,
                                                                                         AVSampleRateKey: 44100,
                                                                                         AVNumberOfChannelsKey: 1])
        myAudioWritter.expectsMediaDataInRealTime = true
        
        return myAudioWritter
    }
    
}
