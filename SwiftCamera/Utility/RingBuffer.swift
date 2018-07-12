//
//  RingBuffer.swift
//  SwiftCamera
//
//  Created by JosephChen on 2018/7/9.
//  Copyright © 2018年 JosephChen. All rights reserved.
//

import Foundation

class RingBuffer: NSObject {

    private var coreMemory: UnsafeMutableRawPointer!
    private var totalSize = 0
    private var validSize = 0
    private(set) var writeIndex = 0
    private(set) var readIndex = 0
    
    convenience init(size: Int) {
        self.init()
        
        self.coreMemory = calloc(size, MemoryLayout<UInt8>.size)
        self.totalSize = size
        memset(self.coreMemory, 0, size)
        
    }
    
    deinit {
        free(self.coreMemory)
    }
    
    func write(data: UnsafeRawPointer, size: Int) {
        objc_sync_enter(self)
        defer {
            objc_sync_exit(self)
        }
        
        var ptr = self.moveWritePtr()
        
        if self.writeIndex + size < self.totalSize {
            memcpy(ptr, data, size)
            self.writeIndex = self.writeIndex + (size - 1)
        }
        else {
            let sizeWriteTail = self.totalSize - self.writeIndex
            let sizeWriteHead = size - sizeWriteTail
            
            memcpy(ptr, data, sizeWriteTail)
            self.writeIndex = self.totalSize - 1
            
            if sizeWriteHead > 0 {
                ptr = self.moveWritePtr()
                memcpy(ptr, data + sizeWriteTail, sizeWriteHead)
                self.writeIndex = sizeWriteHead - 1
            }
        }
        self.validSize = self.validSize + size
    }

    func read(size: Int) -> UnsafeMutableRawPointer? {
        objc_sync_enter(self)
        defer {
            objc_sync_exit(self)
        }
        
        guard size <= self.totalSize else { return nil }
        guard let memDest = calloc(size, MemoryLayout<UInt8>.size) else { return nil }
        memset(memDest, 0, size)
        
        var ptr = self.coreMemory + self.readIndex
        
        if self.readIndex + size < self.totalSize {
            memcpy(memDest, ptr, size)
            self.readIndex = self.readIndex + size
        }
        else {
            let tailReadSize = self.totalSize - self.readIndex
            memcpy(memDest, ptr, tailReadSize)
            self.readIndex = 0
            
            let headReadSize = size - tailReadSize
            if headReadSize > 0 {
                
                ptr = self.coreMemory
                memcpy(memDest + tailReadSize, ptr, headReadSize)
                
                self.readIndex = headReadSize - 1
            }
        }
        self.validSize = self.validSize - size
        
        return memDest
    }
    
    func isDataEnough(requestSize: Int) -> Bool {
        return self.validSize >= requestSize
    }
    
    func reset() {
        
        objc_sync_enter(self)
        defer {
            objc_sync_exit(self)
        }
        
        self.writeIndex = 0
        self.readIndex = 0
        self.validSize = 0
        memset(self.coreMemory, 0, self.totalSize)
    }
    
    private func moveWritePtr() -> UnsafeMutableRawPointer {
        
        if self.writeIndex == self.readIndex {
            return self.coreMemory
        }
        
        self.writeIndex = (self.writeIndex + 1) % self.totalSize
        return self.coreMemory + self.writeIndex
    }
    
}
