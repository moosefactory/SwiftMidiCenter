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

//  InputConnection.swift
//  Created by Tristan Leblanc on 02/01/2021.

import Foundation
import CoreMIDI
import SwiftMIDI

/// RefCon is used to identify a connection when receiving packets
public struct RefCon: CustomStringConvertible {
    weak var port: InputPort?

    /// The connection identifier
    var connectionIdentifier: String
    /// The CoreMIDI Source that sends data
    var outlet: MidiOutlet
    
    var identifier: String {
        "\(connectionIdentifier) : \(outlet.name)"
    }
    
    public var description: String {
        return "RefCon \(connectionIdentifier) - port: \(port!.name) - outlet: \(outlet)"
    }
}

/// InputPortConnect
///
/// This object manage a unique connection between a midi source and an input port
public class InputPortConnection {
    /// The connection outlet
    private(set) var outlet: MidiOutlet
    /// The connection port
    private(set) var port: InputPort
    
    /// A refcon object, used to identifiy messages from this outlet in the input port
    public var refCon: RefCon
    
    // MARK: - Initialisation
    
    init(identifier: String, port: InputPort, source: MidiOutlet) throws {
        self.port = port
        self.outlet = source
        self.refCon = RefCon(port: port, connectionIdentifier: identifier, outlet: source)
        try open()
    }
    
    // MARK: - Open/Close connection
    
    func open() throws {
        guard outlet.ref != 0 else {
            throw SwiftMIDI.Errors.sourceRefNotSet
        }
        guard port.ref != 0 else {
            throw SwiftMIDI.Errors.inputPortRefNotSet
        }
        try SwiftMIDI.connect(source: outlet.ref, to: port.ref, refCon: &refCon)
    }
    
    func close() throws {
        guard outlet.ref != 0 else {
            throw SwiftMIDI.Errors.sourceRefNotSet
        }
        guard port.ref != 0 else {
            throw SwiftMIDI.Errors.inputPortRefNotSet
        }
        try SwiftMIDI.disconnect(source: outlet.ref, from: port.ref)
    }
}

extension InputPortConnection: Hashable {
    public static func == (lhs: InputPortConnection, rhs: InputPortConnection) -> Bool {
        lhs.refCon.identifier == rhs.refCon.identifier
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(refCon.identifier)
    }
}
