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

//  MidiCenter+Client.swift
//  Created by Tristan Leblanc on 30/12/2020.

import Foundation
import CoreMIDI
import SwiftMIDI

/// Pass packetList, events, and connection reference
public typealias MidiEventsReadBlock = (UnsafePointer<MIDIPacketList>, [MidiEvent], UnsafeMutableRawPointer?)->Void

public class MidiClient: ObservableObject {
    
    public var setupCommited: (()->Void)?
    
    /// The CoreMidi client refcon
    public private(set) var ref: MIDIClientRef = 0
    
    /// The client identifier, in reverse path style
    public private(set) var identifier: String
    
    /// The opened input ports
    public lazy var inputPort: InputPort = {
        do {
            return try openInputPortWithPacketsReader(name: "in", type: .packets, readBlock: receive)
        } catch {
            fatalError("\(error)")
        }
    }()
    
    public lazy var outputPort: OutputPort = {
        do {
            return try OutputPort(client: self, name: "mainOut")
        } catch {
            fatalError("\(error)")
        }
    }()
    
    /// The midi outlet to outlet connections
    public internal(set) var connections = [MidiConnection]()
    
    // MARK: Debug options
    
#if DEBUG
    
    /// Log Notifications
    var logNotifications: Bool = true
    
    /// Log MidiEvents
    var logEvents: Bool = true
    
#endif
    
    /// A weak reference to the MidiCenter, to update the midi patch bay when setup is changed,
    /// and to determine the reverse path identifier for newly created objects
    public private(set) weak var midiCenter: MidiCenter?
    
    // MARK: - Initialisation
    
    public init(midiCenter: MidiCenter, name: String, readBlock: @escaping MIDIReadBlock) throws {
        self.midiCenter = midiCenter
        self.identifier = "\(midiCenter.identifier).\(name)"
        
        self.ref = try SwiftMIDI.createClient(name: identifier, with: notifyBlock)
        
        inputPort = try openInputPortWithPacketsReader(name: "in", type: .packets, readBlock: readBlock)
        outputPort = try OutputPort(client: self, name: "out")
    }
    
    public func openDefaultPorts() throws {
        // Opens the output port
        try openOutputPort()
    }
    
    // MIDI Packets handling
    
    func receive(packets: UnsafePointer<MIDIPacketList>, refCon: UnsafeMutableRawPointer?) {
        
    }
    
    
    public var customReceiveBlock: MIDIReadBlock?
    
    // MARK: - Notifications handling
    
    private func notifyBlock(_ notificationPointer: UnsafePointer<MIDINotification>) {
        guard let notification = SwiftMIDI.Notification.make(with: notificationPointer) else { return }
#if DEBUG
        if logEvents {
            self.log(notification: notification)
        }
#endif
        
        switch notification {
            
        case is SwiftMIDI.Notification.ObjectAdded:
            let object = (notification as! SwiftMIDI.Notification.ObjectAdded).object
            midiCenter?.didAdd(object)
            
        case is SwiftMIDI.Notification.ObjectRemoved:
            let object = (notification as! SwiftMIDI.Notification.ObjectRemoved).object
            midiCenter?.didRemove(object)
            
        case is SwiftMIDI.Notification.PropertyChanged:
            let object = (notification as! SwiftMIDI.Notification.PropertyChanged).object
            midiCenter?.didChange(object)
            
            /// Last notification, we commit the setup
        case is SwiftMIDI.Notification.SetUpChanged:
            midiCenter?.commitSetUp()
            
        default:
            break
        }
    }
    
    // MARK: - Output Midi Port
    
    public func openOutputPort(name: String = "mainOut") throws {
        outputPort = try OutputPort(client: self, name: name)
    }
    
    // MARK: - Input Midi Ports
    
    @discardableResult
    public func newConnection(with info: NewConnectionInfo) throws -> MidiConnection {
        try createConnection(port: inputPort, type: info.connectionType, name: info.name)
    }
    
    public func openInputPortWithPacketsReader(name: String = "mainIn",
                                               type: ConnectionType,
                                               readBlock: @escaping MIDIReadBlock) throws -> InputPort {
        let inputPort = try InputPort(client: self, type: type , name: name) { packetList, refCon in
            
            if let receiveBlock = self.customReceiveBlock {
                receiveBlock(packetList, refCon)
            }
            
            guard let cnxRefCon = refCon?.assumingMemoryBound(to: RefCon.self).pointee else {
                return
            }
            
            self.connections.forEach { connection in
                // Only transfer if outlet is set in the connection
                if connection.destinations.count >= 0,
                   connection.sources.contains(cnxRefCon.outlet) {
                    connection.transfer(packetList: packetList)
                }
            }
            
            readBlock(packetList, refCon)
        }
        return inputPort
    }
    
    // MARK: - Connections
    
    public func createMidiInputConnection(type: ConnectionType, sourceOutlet: MidiOutlet) throws -> MidiConnection {
        try createConnection(port: inputPort, type: type, sourceOutlet: sourceOutlet)
    }
    
    public func createConnection(port: InputPort, type: ConnectionType, name: String? = nil, sourceOutlet: MidiOutlet? = nil) throws -> MidiConnection {
        
        let name = name ?? sourceOutlet?.name ?? "Unnamed Input"
        var ct = MidiEventTypeMask.all
        switch type {
        case .packets:
            ct = .all
        case .events:
            ct = .allExceptedClock
        case .clock:
            ct = .realTimeMessage
        case .transpose:
            ct = .note
        case .controls:
            ct = .control
        }
        
        let filter = MidiFilterSettings(channels: .all, eventTypes: ct)
        
        let sources = [sourceOutlet].compactMap {$0}
        let connection = MidiConnection(name: name, filter: filter,
                                        inputPort: port, outputPort: outputPort,
                                        sources: sources, destinations: [])
        connection.inputOutletsDidChange = { changes in
            self.usedInputsDidChange(changes: changes)
        }
        connection.outputOutletsDidChange = { connection in
        //self.client.connectionDidChange(connection: connection)
        }
        try addConnection(connection, in: port)
        return connection
    }
    
    /// Adds a connection from outlet to outlet in the given port
    
    public func addConnection(_ connection: MidiConnection, in port: InputPort) throws {
        try connection.sources.forEach {
            try port.connect(identifier: connection.uuid.uuidString, outlet: $0)
        }
        connections.append(connection)
        objectWillChange.send()
    }
    
    
    public func removeConnection(_ connection: MidiConnection, in port: InputPort) {
        connection.sources.forEach {
            try? port.disconnect(outlet: $0)
        }
        if let index = connections.firstIndex(of: connection) {
            connections.remove(at: index)
        }
        objectWillChange.send()
    }
    
    func usedInputsDidChange(changes: MidiWireChangeParams<MidiConnection>) {
        changes.addedInputOutlets.forEach {
            do {
                try inputPort.connect(identifier: changes.wire.uuid.uuidString, outlet: $0)
            } catch {
                print("Cant connect outlet $0")
            }
        }
        changes.removedInputOutlets.forEach {
            try? inputPort.disconnect(outlet: $0)
        }
    }
}


// MARK: - Utilities

extension MidiClient: CustomStringConvertible {
    
    public var description: String {
        var out = ["Midi Client '\(identifier)'"]
        out += [inputPort.description]
        return out.joined(separator: "\r")
    }
}


#if DEBUG

extension MidiClient {
    
    public static let test = try! MidiClient(midiCenter: MidiCenter.shared, name: "Test Client") { _,_ in}
    private func log(notification: SwiftMIDINotification) {
        print(notification.description.replacingOccurrences(of: ";", with: "\r    "))
        if notification is SwiftMIDI.Notification.SetUpChanged {
            print("---------- Setup Did Change ------------")
        }
    }
}

#endif
