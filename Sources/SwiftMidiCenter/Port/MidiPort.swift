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

//  MidiPort.swift
//  Created by Tristan Leblanc on 02/01/2021.

import Foundation
import CoreMIDI
import SwiftMIDI

public class MidiPort: MidiObject, ObservableObject, Identifiable {
    
    
    /// The CoreMidi port refCon
    public internal(set) var ref: MIDIPortRef = 0
    
    /// The port name - better to choose a lowercase spaceless name
    public private(set) var name: String // Last identifier component
    
    public var uniqueID: Int { return ref.uniqueID }
    
    /// The port identifier, in reverse path style
    public private(set) var identifier: String
    
    /// The owner client
    public private(set) weak var client: MidiClient?
    
    internal init(client: MidiClient, name: String = "input") throws {
        self.name = name
        self.client = client
        self.identifier = "\(client.identifier).\(name)"
        try open()
    }
    
    func open() throws {
        fatalError("One must create either an input or output port")
    }
    
    func close() throws {
        fatalError("One must create either an input or output port")
    }
}

extension MidiPort: Hashable {
    public static func == (lhs: MidiPort, rhs: MidiPort) -> Bool {
        lhs.identifier == rhs.identifier
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}

