//
//  MiidiCenter+MidiBay.swift
//  MidiCenter
//
//  Created by Tristan Leblanc on 31/12/2020.
//

import Foundation
import SwiftMIDI

extension SwiftMidiCenter {
    
    /// Initialize midi inputs and outputs
    
    func initMidi() throws {
        changingMidiBay.input.outlets = SwiftMIDI.allSources.map { MidiOutlet(ref: $0) }

//        if let defaultInputPort = client?.inputPorts.first {
//            changingMidiBay.input.connectAllOutlets(to: defaultInputPort)
//        }
        
        changingMidiBay.output.outlets = SwiftMIDI.allDestinations.map { MidiOutlet(ref: $0) }
        
        // Commit the midi bay
        midiBay = changingMidiBay
    }

    /// Iterates trhough all input outlets
    
    public func forEachInput(_ closure: (MidiOutlet)->Void) {
        midiBay.input.forEachOutlet { closure($0) }
    }

    /// Iterates trhough all output outlets

    public func forEachOutput(_ closure: (MidiOutlet)->Void) {
        midiBay.output.forEachOutlet { closure($0) }
    }
    
    public var inputs: [MidiOutlet] {
        return midiBay.input.outlets
    }

    public var outputs: [MidiOutlet] {
        return midiBay.output.outlets
    }
}
