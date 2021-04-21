//
//  SwiftMidiCenterTests.swift
//  SwiftMidiCenterTests
//
//  Created by Tristan Leblanc on 13/04/2021.
//

import XCTest
@testable import SwiftMidiCenter

class SwiftMidiCenterTests: XCTestCase {

    lazy var midiCenter: MidiCenter = {
        return MidiCenter.shared
    }()
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    func testMidiCenter() throws {
        print(midiCenter)
        
        print("Set setupComit completion")
        midiCenter.setupCommited = {
            print(self.midiCenter)
        }
        print("Test midicenter.reset()")
        try midiCenter.reset()
     }
}
