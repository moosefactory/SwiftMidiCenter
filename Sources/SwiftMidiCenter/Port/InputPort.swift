//
//  InputPort.swift
//  MidiCenter
//
//  Created by Tristan Leblanc on 30/12/2020.
//

import Foundation
import CoreMIDI
import SwiftMIDI

public enum InputPortType {
    case packets
    case events
    case clock
    case transpose
    case controls
}

public class InputPort: MidiPort {
    
    /// The attached input Connections
    ///
    /// There can be as many connections as there is input sources
    public var inputConnections = [InputPortConnection]()

    public private(set) var type: InputPortType

    /// The MIDIReadBlock closure ( Deprecated - need to switch to MidiEvent API )
    private var readBlock: MIDIReadBlock
    
    internal init(client: MidiClient, type: InputPortType, name: String = "input", readBlock: @escaping MIDIReadBlock) throws {
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
    
    func connect(identifier: String, outlet: MidiOutlet) throws {
        guard !inputConnections.map({ $0.outlet }).contains(outlet) else {
            throw MidiCenter.Errors.inputOutletWithSameIdentifierAlreadyExists
        }
        let input = try InputPortConnection(identifier: identifier, port: self, source: outlet)
        inputConnections.append(input)
    }
    
    
    /// Unplug the port from an outlet
    
    func disconnect(outlet: MidiOutlet) throws {
        guard let connectionIndex = inputConnections.firstIndex(where: {$0.outlet == outlet}) else {
            throw MidiCenter.Errors.inputOutletAlreadyUnplugged
        }
        try inputConnections[connectionIndex].close()
        inputConnections.remove(at: connectionIndex)
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
        return try! (MidiClient.test.openInputPortWithEventsReader(name: "Test Input Port", midiEventsBlock: { packets, events, refCon in
            print("Test Input Port")
        }))
    }()
}
    
#endif
