//
//  SwiftCameraTests.swift
//  SwiftCameraTests
//
//  Created by JosephChen on 2018/6/27.
//  Copyright © 2018年 JosephChen. All rights reserved.
//

import XCTest
@testable import SwiftCamera

class SwiftCameraTests: XCTestCase {
    
    let ringBuf_100 = RingBuffer.init(size: 100)
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testReadWrite() {
        
        // in first circle round
        let sizeA = 99
        let bufA = calloc(sizeA, MemoryLayout<UInt8>.size)
        memset(bufA, 0xFF, sizeA)
        self.ringBuf_100.write(data: bufA!, size: sizeA)    // Write 99
        bufA?.deallocate()
        XCTAssert(self.ringBuf_100.readIndex == 0)
        XCTAssert(self.ringBuf_100.writeIndex == 98)
        
        let ptr = self.ringBuf_100.read(size: 50)           // Read 50
        for i in 0...49 {
            let val = ptr?.load(fromByteOffset: i, as: UInt8.self)
            XCTAssert(val == 0xFF)
        }
        ptr?.deallocate()
        XCTAssert(self.ringBuf_100.readIndex == 50)
        XCTAssert(self.ringBuf_100.writeIndex == 98)
        
        // Second circle round
        let sizeB = 15;
        let bufB = calloc(sizeB, MemoryLayout<UInt8>.size)
        memset(bufB, 0xEE, sizeB)
        self.ringBuf_100.write(data: bufB!, size: sizeB)    // Write 15
        XCTAssert(self.ringBuf_100.readIndex == 50)
        XCTAssert(self.ringBuf_100.writeIndex == 13)
        
        let ptr2 = self.ringBuf_100.read(size: 37)          // Read 37
        for i in 0...36 {
            let val = ptr2?.load(fromByteOffset: i, as: UInt8.self)
            XCTAssert(val == 0xFF)
        }
        ptr2?.deallocate()
        XCTAssert(self.ringBuf_100.readIndex == 87)
        XCTAssert(self.ringBuf_100.writeIndex == 13)
        
        //
        let ptr3 = self.ringBuf_100.read(size: 20)          // Read 20
        for i in 0...11 {
            let val = ptr3?.load(fromByteOffset: i, as: UInt8.self)
            XCTAssert(val == 0xFF)
        }
        for i in 12...19 {
            let val = ptr3?.load(fromByteOffset: i, as: UInt8.self)
            XCTAssert(val == 0xEE)
        }
        ptr3?.deallocate()
        XCTAssert(self.ringBuf_100.readIndex == 6)
        XCTAssert(self.ringBuf_100.writeIndex == 13)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
