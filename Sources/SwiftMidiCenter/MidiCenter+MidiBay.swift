/*--------------------------------------------------------------------------*/
/*   /\/\/\__/\/\/\        MooseFactory SwiftMidiCenter                     */
/*   \/\/\/..\/\/\/                                                         */
/*        |  |             (c)2021 Tristan Leblanc                          */
/*        (oo)             tristan@moosefactory.eu                          */
/* MooseFactory Software                                                    */
/*--------------------------------------------------------------------------*/
/*
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE. */
/*--------------------------------------------------------------------------*/

//  MidiCenter+MidiBay.swift
//  Created by Tristan Leblanc on 31/12/2020.

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

    public var devices: [MidiDevice] {
        return parc.internalDevices.devices
    }

    public var externalDevices: [MidiDevice] {
        return parc.externalDevices.devices
    }

    public var entities: [MidiEntity] {
        return parc.internalDevices.entities
    }
    
    public var externalEntities: [MidiEntity] {
        return parc.externalDevices.entities
    }
}
