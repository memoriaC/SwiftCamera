//
//  ULawEncoder.swift
//  SwiftCamera
//
//  Created by JosephChen on 2018/7/10.
//  Copyright © 2018年 JosephChen. All rights reserved.
//

import Foundation
import AVFoundation
import AudioToolbox

class ULawEncoder: NSObject, EncoderProtocol {
    
    var encoderQueue: DispatchQueue!
    var audioConverter: AudioConverterRef?
    var myRingBuffer: RingBuffer!
    var audioDataInProcessing: UnsafeMutableRawPointer?
    var fileHandle: FileHandle?
    var sessionShouldStop = false
    
    override init() {
        super.init()
        self.encoderQueue = DispatchQueue.init(label: "uLawEncoder")
        self.audioConverter = nil
        self.myRingBuffer = RingBuffer.init(size: 65535)
        self.audioDataInProcessing = nil
    }
    
    public func startRunning() {
        
        self.sessionShouldStop = false
        self.fileHandle = self.initFileWritter()
    }
    
    public func stopRunning() {
        
        self.sessionShouldStop = true
        self.encoderQueue.async {
            
            if self.audioConverter != nil {
                AudioConverterDispose(self.audioConverter!)
                self.audioConverter = nil
                print("audioConverter Disposed")
            }
        }
    }
    
    func input(_ sampleBuffer: CMSampleBuffer) {
        
        self.encoderQueue.async {
            
            guard self.sessionShouldStop == false else { return }
            if self.audioConverter == nil {
                self.audioConverter = self.setupAudioConveter(samplerBuffer: sampleBuffer)
            }
            guard let audioConverter = self.audioConverter else { return }
            
            guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { return }
            
            var totalLength = Int(0)
            var dataPointer: UnsafeMutablePointer<Int8>?
            let status = CMBlockBufferGetDataPointer(blockBuffer, 0, nil, &totalLength, &dataPointer)
            guard status == kCMBlockBufferNoErr, totalLength > 0, dataPointer != nil else { return }
            print("audio captured length: \(totalLength)")
            
            self.myRingBuffer.write(data: dataPointer!, size: totalLength)
            defer {
                self.myRingBuffer.reset()
                if self.audioDataInProcessing != nil {
                    self.audioDataInProcessing?.deallocate()
                    self.audioDataInProcessing = nil
                }
            }
            
            var data = Data.init()
            repeat {
                
                var outAudioBufferList = AudioBufferList.init(mNumberBuffers: 1, mBuffers: AudioBuffer.init(mNumberChannels: 1, mDataByteSize: UInt32(MemoryLayout<UInt8>.size * totalLength / 2), mData: calloc(MemoryLayout<UInt8>.size, totalLength / 2)))
                var outDataPacketSize = UInt32(1)
                var outPacketDesc = AudioStreamPacketDescription.init()
                
                guard self.sessionShouldStop == false else { return }
                let status = AudioConverterFillComplexBuffer(audioConverter, self.inputDataProc, unsafeBitCast(self, to: UnsafeMutableRawPointer.self), &outDataPacketSize, &outAudioBufferList, &outPacketDesc)
                
                switch status {
                case noErr:
                    let ptrToUInt8 = outAudioBufferList.mBuffers.mData?.bindMemory(to: UInt8.self, capacity: Int(outAudioBufferList.mBuffers.mDataByteSize))
                    
                    if ptrToUInt8 != nil {
                        data.append(ptrToUInt8!, count: Int(outAudioBufferList.mBuffers.mDataByteSize))
                        ptrToUInt8!.deallocate()
                    }
                    
                case -1:
                    print("audio done length: \(data.count)")
                    data.writeToFile(fileHandle: self.fileHandle)
                    outAudioBufferList.mBuffers.mData?.deallocate()
                    return
                default:
                    print("err \(status)")
                    return
                }
                
            } while(true)
        }
    }
   
    private var inputDataProc: AudioConverterComplexInputDataProc = {(
        converter: AudioConverterRef,
        ioNumberDataPackets: UnsafeMutablePointer<UInt32>,
        ioData: UnsafeMutablePointer<AudioBufferList>,
        outDataPacketDescription: UnsafeMutablePointer<UnsafeMutablePointer<AudioStreamPacketDescription>?>?,
        inUserData: UnsafeMutableRawPointer?) in
        
        let myEncoder = unsafeBitCast(inUserData, to: ULawEncoder.self)
        let copiedDataLength = myEncoder.fillData(ioNumberDataPackets, ioData: ioData, requestSize: Int(ioNumberDataPackets.pointee * 2))
        if copiedDataLength > 0 {
            return noErr
        }
        return -1
    }
    
    private func fillData(_ ioNumberDataPackets: UnsafeMutablePointer<UInt32>, ioData: UnsafeMutablePointer<AudioBufferList>, requestSize: Int) -> UInt32 {
    
        guard self.myRingBuffer.isDataEnough(requestSize: requestSize) == true else { return 0 }
         
        ioData.pointee.mNumberBuffers = 1
        ioNumberDataPackets.pointee = 1
        
        let copiedData = self.myRingBuffer.read(size: requestSize)
        ioData.pointee.mBuffers.mData = copiedData
        ioData.pointee.mBuffers.mDataByteSize = UInt32(requestSize)
        
        if self.audioDataInProcessing != nil {
            self.audioDataInProcessing?.deallocate()
        }
        
        self.audioDataInProcessing = copiedData
        return UInt32(requestSize)
    }
    
    
    private func setupAudioConveter(samplerBuffer: CMSampleBuffer) -> AudioConverterRef? {
        
        guard let format = CMSampleBufferGetFormatDescription(samplerBuffer) else { return nil }
        guard let ptrDesc = CMAudioFormatDescriptionGetStreamBasicDescription(format)  else { return nil }
        
        var outDesc = ptrDesc.pointee
        outDesc.mFormatID = kAudioFormatULaw
        outDesc.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked
        
        var audioConverter: AudioConverterRef?
        let status = AudioConverterNew(ptrDesc, &outDesc, &audioConverter)
        guard audioConverter != nil, status == noErr else {
            print("AudioConverterNew failed: \(status)")
            return nil
        }
        
        return audioConverter
    }
    
    private func initFileWritter() -> FileHandle? {
        guard let file = FileHandle.getDataFilePath(type: .AudioStream) else { return nil }
        
        try? FileManager.default.removeItem(atPath: file)        
        FileManager.default.createFile(atPath: file, contents: nil, attributes: nil)
        return FileHandle.init(forWritingAtPath: file)
    }
}
