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

//  InputPort.swift
//  Created by Tristan Leblanc on 30/12/2020.

import Foundation
import CoreMIDI
import SwiftMIDI

public enum ConnectionType: Int, Codable, CaseIterable {
    case packets
    case events
    case clock
    case transpose
    case controls
    
    public var string: String {
        switch self {
        case .packets:
            return "Packets"
        case .events:
            return "Events"
        case .clock:
            return "Clock"
        case .transpose:
            return "Transpose"
        case .controls:
            return "Controls"
        }
    }
    
    public static var allStrings: [String] { ConnectionType.allCases.map {$0.string }}
}

public class InputPort: MidiPort {
    
    /// The attached input Connections
    ///
    /// There can be as many connections as there is input sources
    public var inputConnections = [InputPortConnection]()

    public private(set) var type: ConnectionType
        
    /// The MIDIReadBlock closure ( Deprecated - need to switch to MidiEvent API )
    private var readBlock: MIDIReadBlock
    
    internal init(client: MidiClient, type: ConnectionType, name: String = "input", readBlock: @escaping MIDIReadBlock) throws {
        self.readBlock = readBlock
        self.type = type
        try super.init(client: client, name: name)
    }
    
    /// Open the input port
    override func open() throws {
        guard let client = client else {
            throw MidiCenter.Errors.clientNotSet
        }
        guard client.ref != 0 else {
            throw MidiCenter.Errors.clientNotSet
        }

        ref = try SwiftMIDI.createInputPort(clientRef: client.ref,
                                            portName: identifier,
                                            readBlock: readBlock)
    }

    /// Plug the port on an outlet
    ///
    /// An outlet can be connected once to an input port.
    
    @discardableResult
    public func connect(identifier: String, outlet: MidiOutlet) throws -> InputPortConnection {
        if let connection = connectionForOutlet(outlet) {
            return connection
        }
        guard !isOutletAlreadyConnected(outlet) else {
            throw MidiCenter.Errors.inputOutletWithSameIdentifierAlreadyExists
        }
        let inputConnection = try InputPortConnection(identifier: identifier, port: self, source: outlet)
        inputConnections.append(inputConnection)
        objectWillChange.send()
        return inputConnection
    }
    
    public func connectionForOutlet(_ outlet: MidiOutlet) -> InputPortConnection? {
        inputConnections.first(where: { $0.outlet == outlet })
    }
    
    public func isOutletAlreadyConnected(_ outlet: MidiOutlet) -> Bool {
        inputConnections.map({ $0.outlet }).contains(outlet)
    }
    
    /// Unplug the port from an outlet
    
    public func disconnect(outlet: MidiOutlet) throws {
        guard let connectionIndex = inputConnections.firstIndex(where: {$0.outlet == outlet}) else {
            throw MidiCenter.Errors.inputOutletAlreadyUnplugged
        }
        try inputConnections[connectionIndex].close()
        inputConnections.remove(at: connectionIndex)
        objectWillChange.send()
    }
}

extension InputPort: CustomStringConvertible {
    
    public var description: String {
        return "Input Port '\(identifier)' - ref = \(ref)"
    }
}

#if DEBUG

public extension InputPort {
    
    static let test: InputPort = {
        return MidiClient.test.inputPort
    }()
}
    
#endif
