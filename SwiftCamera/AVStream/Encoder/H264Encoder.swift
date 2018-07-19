//
//  H264Encoder.swift
//  SwiftCamera
//
//  Created by JosephChen on 2018/6/28.
//  Copyright © 2018年 JosephChen. All rights reserved.
//

import Foundation
import AVFoundation
import VideoToolbox

class H264Encoder: NSObject, EncoderProtocol {
    
    var encodeQueue: DispatchQueue!
    var compressionSession: VTCompressionSession?
    var fileHandle: FileHandle?
    
    override init() {
        super.init()
        self.encodeQueue = DispatchQueue(label: "H264Encoder")
    }
    
    public func startRunning() {
        self.fileHandle = self.initFileWritter()
    }
    
    public func stopRunning() {
        guard let compressionSession = self.compressionSession else {
            return
        }
        
        VTCompressionSessionCompleteFrames(compressionSession, kCMTimeInvalid)
        VTCompressionSessionInvalidate(compressionSession)
        print("H264 Encoder Session Invalidated: \(unsafeBitCast(compressionSession, to: UnsafeRawPointer.self))")
        self.compressionSession = nil
    }
    
    func input(_ sampleBuffer: CMSampleBuffer) {
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        if self.compressionSession == nil {
            self.compressionSession = self.initVideoToolbox(imageBuffer: imageBuffer)
        }
        guard let compressionSession = self.compressionSession else { return }
        
        let presentationTimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        var flags = VTEncodeInfoFlags.asynchronous
        let statusCode = VTCompressionSessionEncodeFrame(compressionSession,
                                                         imageBuffer,
                                                         presentationTimeStamp,
                                                         kCMTimeInvalid,
                                                         nil,
                                                         nil,
                                                         &flags)
        
        print("VTCompressionSessionEncodeFrame: \(statusCode) flags: \(flags)")
    }
    
    private func initVideoToolbox(imageBuffer: CVImageBuffer) -> VTCompressionSession? {
        
        let inWidth = CVPixelBufferGetWidth(imageBuffer)
        let inHeight = CVPixelBufferGetHeight(imageBuffer)
        let size = CGSize.init(width: inWidth, height: inHeight)
        
        var compressionSession: VTCompressionSession?
        let status = VTCompressionSessionCreate(kCFAllocatorDefault,
                                                Int32(size.width),
                                                Int32(size.height),
                                                CMVideoCodecType(kCMVideoCodecType_H264),
                                                nil,
                                                nil,
                                                nil,
                                                vtCallback,
                                                unsafeBitCast(self, to: UnsafeMutableRawPointer.self),
                                                &compressionSession)
    
        guard compressionSession != nil, status == noErr else {
            print("VTCompressionSessionCreate failed: \(status)")
            return nil
        }
        
        VTSessionSetProperty(compressionSession!, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue)
        VTSessionSetProperty(compressionSession!, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_Baseline_AutoLevel)
        
        var frameInterval = 10
        let frameIntervalRef = CFNumberCreate(kCFAllocatorDefault, .intType, &frameInterval)
        VTSessionSetProperty(compressionSession!, kVTCompressionPropertyKey_MaxKeyFrameInterval, frameIntervalRef)
        
        var fps = 10
        let fpsRef = CFNumberCreate(kCFAllocatorDefault, .intType, &fps)
        VTSessionSetProperty(compressionSession!, kVTCompressionPropertyKey_ExpectedFrameRate, fpsRef)
       
        
        var bitRate = 512 * 1024    // 512 K bits/sec
        let bitRateRef = CFNumberCreate(kCFAllocatorDefault, .intType, &bitRate)
        let ret_val = VTSessionSetProperty(compressionSession!, kVTCompressionPropertyKey_AverageBitRate, bitRateRef)
        if ret_val != noErr {
            print("VTSessionSetProperty failed: \(status)")
        }
        
        // Tell the encoder to start encoding
        VTCompressionSessionPrepareToEncodeFrames(compressionSession!)
       
        return compressionSession!
    }
    
    private func initFileWritter() -> FileHandle? {
        guard let file = FileHandle.getDataFilePath(type: .VideoStream) else { return nil }
        
        try? FileManager.default.removeItem(atPath: file)
        FileManager.default.createFile(atPath: file, contents: nil, attributes: nil)
        return FileHandle.init(forWritingAtPath: file)
    }
    
    let vtCallback : @convention(c) (UnsafeMutableRawPointer?, UnsafeMutableRawPointer?, OSStatus, VTEncodeInfoFlags, CMSampleBuffer?) -> () = { (outputCallbackRefCon, sourceFrameRefCon, status, infoFlags, sampleBuffer) -> Swift.Void in
        
        guard let sampleBuffer = sampleBuffer else { return}
        
        guard let data = sampleBuffer.toH264StreamingData() else { return}
        
        let myEncoder = unsafeBitCast(outputCallbackRefCon, to: H264Encoder.self)
        data.writeToFile(fileHandle: myEncoder.fileHandle)
        
    }
}

extension CMSampleBuffer {
    
    func toH264StreamingData() -> Data? {
        
        var h264StreamingData = Data.init()
        let infoSPSPPS = self.getSPSPPSInfo()
        
        guard let dataBuffer = CMSampleBufferGetDataBuffer(self) else {
            return nil
        }
        var lengthAtOffset = Int(0)
        var totalLength = Int(0)
        var dataPointer: UnsafeMutablePointer<Int8>?
        let statusCodeRet = CMBlockBufferGetDataPointer(dataBuffer, 0, &lengthAtOffset, &totalLength, &dataPointer)
        guard statusCodeRet == noErr, dataPointer != nil else {
            return nil
        }
        
        if infoSPSPPS != nil {
            h264StreamingData.append(infoSPSPPS!)
        }
        
        //
        var bufferOffset = 0
        let AVCCHeaderLength = 4
        while bufferOffset < totalLength - AVCCHeaderLength {
            var NALUnitLength: UInt32 = 0;
            memcpy(&NALUnitLength, dataPointer! + bufferOffset, AVCCHeaderLength);
            NALUnitLength = CFSwapInt32BigToHost(NALUnitLength);
            
            let frameContent = Data.init(bytes: dataPointer! + bufferOffset + AVCCHeaderLength, count: Int(NALUnitLength))
            
            let byteHeader = Data.init(bytes: [0x00, 0x00, 0x00, 0x01] as [CChar], count: 4)
            var frame = Data.init()
            frame.append(byteHeader)
            frame.append(frameContent)
            h264StreamingData.append(frame)
            bufferOffset = bufferOffset + (AVCCHeaderLength + Int(NALUnitLength));
        }
        return h264StreamingData
    }
    
    func getSPSPPSInfo() -> Data? {
        
        let isKeyframe = !CFDictionaryContainsKey(unsafeBitCast(CFArrayGetValueAtIndex(CMSampleBufferGetSampleAttachmentsArray(self, true), 0), to: CFDictionary.self), unsafeBitCast(kCMSampleAttachmentKey_NotSync, to: UnsafeRawPointer.self))
        if !isKeyframe {
            return nil
        }
        guard let format = CMSampleBufferGetFormatDescription(self) else {
            return nil
        }
        
        // SPS
        var sparameterSet: UnsafePointer<UInt8>?
        var sparameterSetSize = Int(0)
        var sparameterSetCount = Int(0)
        var spsNalHeaderLength = Int32(0)
        var status = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 0, &sparameterSet, &sparameterSetSize, &sparameterSetCount, &spsNalHeaderLength)
        guard status == noErr, sparameterSetSize > 0 else {
            return nil
        }
        let SPS = Data.init(bytes: sparameterSet!, count: sparameterSetSize)
        
        // PPS
        var pparameterSet: UnsafePointer<UInt8>?
        var pparameterSetSize = Int(0)
        var pparameterSetCount = Int(0)
        var ppsNalHeaderLength = Int32(0)
        status = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 1, &pparameterSet, &pparameterSetSize, &pparameterSetCount, &ppsNalHeaderLength)
        guard status == noErr, pparameterSetSize > 0 else {
            return nil
        }
        let PPS = Data.init(bytes: pparameterSet!, count: pparameterSetSize)
        
        let byteHeader = Data.init(bytes: [0x00, 0x00, 0x00, 0x01] as [CChar], count: 4)
        var infoSPSPPS = Data.init()
        infoSPSPPS.append(byteHeader)
        infoSPSPPS.append(SPS)
        infoSPSPPS.append(byteHeader)
        infoSPSPPS.append(PPS)
        
        return infoSPSPPS
    }
}

