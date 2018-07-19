//
//  EncoderProtocol.swift
//  SwiftCamera
//
//  Created by JosephChen on 2018/7/12.
//  Copyright © 2018年 JosephChen. All rights reserved.
//

import Foundation
import AVFoundation

protocol EncoderProtocol: class {
    
    func startRunning()
    func stopRunning()
    func input(_ sampleBuffer: CMSampleBuffer)
}

extension Data {
    
    func writeToFile(fileHandle: FileHandle?) {
        guard let fileHandle = fileHandle else {
            return
        }
        
        let _ = fileHandle.writeWithLengthAccumulate(self)
    }
    
}

enum FileType {
    case VideoStream
    case AudioStream
    case MovieFile
}

extension FileHandle {
    
    static func getDataFilePath(type: FileType) -> String? {
        guard let filestring = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last else { return nil }
        
        switch type {
        case FileType.VideoStream:
            return filestring.appending("/h264.data")
        case FileType.AudioStream:
            return filestring.appending("/ulaw.data")
        case FileType.MovieFile:
            return filestring.appending("/movie.mp4")
        }        
    }
    
    
    func writeWithLengthAccumulate(_ data: Data) -> Int {
        self.write(data)
        
        var total = objc_getAssociatedObject(self, unsafeBitCast(self, to: UnsafeRawPointer.self)) as? Int
        
        if total == nil {
            total = data.count
        }
        else {
            total = total! + data.count
        }
        objc_setAssociatedObject(self, unsafeBitCast(self, to: UnsafeRawPointer.self), total, .OBJC_ASSOCIATION_RETAIN)
        
        return total!
    }
}
 
