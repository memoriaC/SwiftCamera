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
        fileHandle.write(self)
    }
    
}
