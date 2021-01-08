//
//  MidiCenter+Client.swift
//  MidiCenter
//
//  Created by Tristan Leblanc on 30/12/2020.
//

import Foundation
import CoreMIDI
import SwiftMIDI

/// Pass packetList, events, and connection reference
public typealias MidiEventsReadBlock = (UnsafePointer<MIDIPacketList>, [MidiEvent], UnsafeMutableRawPointer?)->Void

/// Pass note number, channel, and connection reference
public typealias TransposeReadBlock = (Int, Int, UnsafeMutableRawPointer?)->Void

/// Pass timestamp, channel, and connection reference
public typealias ClockReadBlock = (ClockSignal, UnsafeMutableRawPointer?)->Void

public class MidiClient: ObservableObject {
    
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
    weak var midiCenter: MidiCenter?
    
    // MARK: - Initialisation
    
    public init(midiCenter: MidiCenter, name: String) throws {
        self.midiCenter = midiCenter
        self.identifier = "\(midiCenter.identifier).\(name)"
        
        self.ref = try SwiftMIDI.createClient(name: identifier, with: notifyBlock)
        
        inputPort = try openInputPortWithPacketsReader(name: "in", type: .packets) { packets, refCon in
            
        }
        outputPort = try OutputPort(client: self, name: "out")
        
    }
    
    public func openDefaultPorts() throws {
        // Opens the output port
        try openOutputPort()
    }
    
    // MIDI Packets handling
    
    func receive(packets: UnsafePointer<MIDIPacketList>, refCon: UnsafeMutableRawPointer?) {
        
    }
    
    // MARK: - Notifications handling
    
    private func notifyBlock(_ notificationPointer: UnsafePointer<MIDINotification>) {
        guard let notification = SwiftMIDI.Notification.make(with: notificationPointer) else { return }
        if logEvents {
            self.log(notification: notification)
        }
        
        switch notification {
        
        case is SwiftMIDI.Notification.ObjectAdded:
            let object = (notification as! SwiftMIDI.Notification.ObjectAdded).object
            midiCenter?.didAdd(object)
            
        case is SwiftMIDI.Notification.ObjectRemoved:
            let object = (notification as! SwiftMIDI.Notification.ObjectRemoved).object
            midiCenter?.didRemove(object)
            
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
    
    public func newConnection(with info: NewConnectionInfo) throws {
        try createConnection(port: inputPort, type: info.connectionType, name: info.name)
    }
    
    public func openInputPortWithPacketsReader(name: String = "mainIn", type: ConnectionType, readBlock: @escaping MIDIReadBlock) throws -> InputPort {
        
        let inputPort = try InputPort(client: self, type: type , name: name) { packetList, refCon in
            guard let cnxRefCon = refCon?.assumingMemoryBound(to: RefCon.self).pointee else {
                return
            }
            guard let port = cnxRefCon.port else { return }
            
            self.connections.forEach { connection in
                // Only transfer if outlet is set in the connection
                if connection.sources.contains(cnxRefCon.outlet) {
                    connection.transfer(packetList: packetList)
                }
            }
            readBlock(packetList, refCon)
        }
        return inputPort
    }
    
    // MARK: - Connections
    
    func createConnection(port: InputPort, type: ConnectionType, name: String) throws {
        var ct = MidiEventTypeMask.all
        switch type {
        case .packets:
            ct = .all
        case .events:
            ct = .allExceptedClock
        case .clock:
            ct = .clock
        case .transpose:
            ct = .note
        case .controls:
            ct = .control
        }
        
        var filter = MidiPacketsFilter(channels: .all, eventTypes: ct)

        let connection = MidiConnection(name: name, filter: filter,
                                        inputPort: port, outputPort: outputPort,
                                        sources: [], destinations: [])
        connection.inputOutletsDidChange = { changes in
            self.usedInputsDidChange(changes: changes)
        }
        connection.outputOutletsDidChange = { connection in
            //self.client.connectionDidChange(connection: connection)
        }
        addConnection(connection, in: port)
    }
    
    /// Adds a connection from outlet to outlet in the given port
    
    func addConnection(_ connection: MidiConnection, in port: InputPort) {
        connection.sources.forEach {
            try? port.connect(identifier: connection.uuid.uuidString, outlet: $0)
        }
        connections.append(connection)
        objectWillChange.send()
    }
    
    func usedInputsDidChange(changes: MidiWireChangeParams<MidiConnection>) {
        
        changes.addedInputOutlets.forEach {
            try? inputPort.connect(identifier: changes.wire.uuid.uuidString, outlet: $0)
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
    
    public static let test = try! MidiClient(midiCenter: MidiCenter.shared, name: "Test Client")
    private func log(notification: SwiftMIDINotification) {
        print(notification.description.replacingOccurrences(of: ";", with: "\r    "))
        if notification is SwiftMIDI.Notification.SetUpChanged {
            print("---------- Setup Did Change ------------")
        }
    }
}

#endif
