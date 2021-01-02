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
public typealias ClockReadBlock = (Int, Int, UnsafeMutableRawPointer?)->Void

public class MidiClient: ObservableObject {
        
    /// The CoreMidi client refcon
    public private(set) var ref: MIDIClientRef = 0
    
    /// The client identifier, in reverse path style
    public private(set) var identifier: String
    
    /// The opened input ports
    @Published public private(set) var inputPorts = [InputPort]()
    
    /// The opened output ports
    public private(set) var outputPorts = [OutputPort]()

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
        try openOutputPort()
    }
    
    public func openDefaultPorts() throws {
        // Opens the output port
        try openOutputPort()
    }
    
    // MARK: - Notifications handling
    
    private func notifyBlock(_ notificationPointer: UnsafePointer<MIDINotification>) {
        let notification = SwiftMIDI.Notification.make(with: notificationPointer)
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
    
    // MARK: - Output Midi Ports
    
    var mainOut: OutputPort? {
        guard !outputPorts.isEmpty else { return nil }
        return outputPorts[0]
    }
    
    public func openOutputPort(name: String = "mainOut") throws {
        let outputPort = try OutputPort(client: self, name: name)
        outputPorts.append(outputPort)
    }
    
    // MARK: - Input Midi Ports
    
    /// The default midi packets port
    ///
    /// We use this port in case we don't want events conversion, to avoid overhead.
    /// It is used for fast midiThru connections.
    
    var mainIn: InputPort? {
        guard !inputPorts.isEmpty else { return nil }
        return inputPorts[0]
    }

    public func openInputPortWithPacketsReader(name: String = "mainIn", type: InputPortType, readBlock: @escaping MIDIReadBlock) throws -> InputPort {
        guard inputPorts.first(where: { $0.identifier == identifier }) == nil else {
            throw MidiCenter.Errors.inputPortWithSameIdentifierAlreadyExists
        }
        let inputPort = try InputPort(client: self, type: type , name: name, readBlock: readBlock)
        inputPorts = inputPorts + [inputPort]
        return inputPort
    }
    
    /// The default midi events port
    ///
    /// We use this port when we want to unpack midi events from packets list.
    var mainInEventsPort: InputPort? {
        guard inputPorts.count > 1 else { return nil }
        return inputPorts[1]
    }

    public func openInputPortWithEventsReader(name: String = "mainIn.unpack", midiEventsBlock: @escaping MidiEventsReadBlock) throws -> InputPort {
        return try openInputPortWithPacketsReader(name: name, type: .events) { packetList, connectionRefCon in
            
            guard let refCon = connectionRefCon?.assumingMemoryBound(to: RefCon.self).pointee else {
                return
            }

            // Only during dev, to avoid crash when interrupting the app
            guard (packetList.pointee.packet.data.0 & 0xF0) != 0xF0 else { return }
            
            MidiPacketInterceptor.unpackEvents(packetList) { events in
            
                // We are still in the MidiPacketInterceptor thread at this time
                midiEventsBlock(packetList, events, connectionRefCon)
                
                #if DEBUG
                // Log events of all types excepted clock
                if self.logEvents {
                    DispatchQueue.main.async {
                        let eventsToLog = events.filter({$0.type != .clock})
                        if !eventsToLog.isEmpty {
                            print("\(refCon.identifier) ---> ")
                            eventsToLog.forEach {
                                print($0)
                            }
                        }
                    }
                }
                #endif
            }
        }
    }
    
    // MARK: -
    
    /// Creates a new events input port
    ///
    /// Events input port as a little overhead since they unpack the midi packets to get the events.
    func newEventsInputPort(block: @escaping MidiEventsReadBlock) throws  -> InputPort{
        return try openInputPortWithEventsReader(midiEventsBlock: block)
        //midiClient.objectWillChange().send()
    }
    
    /// Creates a new midi thru input port
    ///
    /// Midi thru input port simply takes packets and forward them to a destination, without unpacking.
    /// That fits well to play live with a keyboard
    
    func newThruInputPort(block: @escaping MIDIReadBlock) throws  -> InputPort{
        return try openInputPortWithPacketsReader(type: .packets, readBlock: block)
    }
    
    // TODO: newTransposePort, newControlPort and newClockPort
    
    /// Creates a new midi transpose input port
    ///
    /// Midi transpose input port simply takes packets and only extract the note number and channels
    /// That fits well if the client app has a live Transpose feature
    
    func newTransposeInputPort(block: @escaping (TransposeReadBlock)) throws {
        //try openInputPortWithPacketsReader(type: .transpose, readBlock: block)
    }

    /// Creates a new midi clock input port
    ///
    /// Midi clock input port simply takes clock signal and forward it to a destination
    /// Use this to synchronize app with external clock
    
    func newClockInputPort(block: @escaping ClockReadBlock) throws {
       /// try openInputPortWithPacketsReader(type: .events, readBlock: block)
    }

    /// Creates a new midi events input port
    ///
    /// Midi controls input port filters all events that are not controls
    
    func newControlsInputPort(block: @escaping MidiEventsReadBlock) throws {
       /// try openInputPortWithPacketsReader(type: .events, readBlock: block)
    }


    // MARK: - Connections
    
    func addConnection(_ connection: MidiConnection, in port: InputPort) {
        // Whould work with other inputs
        guard let mainIn = mainIn else { return }
        connection.sources.forEach {
            try? port.connect(identifier: connection.uuid.uuidString, outlet: $0)
        }
    }
    
    func usedInputsDidChange(changes: MidiWireChangeParams<MidiConnection>) {
        

        if let mainIn = mainInEventsPort {
            changes.addedInputOutlets.forEach {
                try? mainIn.connect(identifier: changes.wire.uuid.uuidString, outlet: $0)
            }
            changes.removedInputOutlets.forEach {
                
                // TODO: Count connections using the disconnected outlets, if none unplug
                
                // For this, connections must be moved from center to client
                
        //        var count = 0
        //        connections.forEach { if ($0.outlet == outlet) { count += 1 } }
        //        // If there is no more connection using this outlet, we unplug it
        //        if count == 0 {
        //            try SwiftMIDI.disconnect(source: outlet.ref, from: ref)
        //        }

                try? mainIn.disconnect(outlet: $0)
            }
        }
//        if let mainOut = mainOut {
//            connection.destinations.forEach {
//                try? mainOut.connect(outlet: $0)
//            }
//        }
    }
}


// MARK: - Utilities

extension MidiClient: CustomStringConvertible {
    
    public var description: String {
        var out = ["Midi Client '\(identifier)'"]
        out += inputPorts.map { "    " + $0.description }
        return out.joined(separator: "\r")
    }
}


#if DEBUG

extension MidiClient {
    
    public static let test = try! MidiClient(midiCenter: MidiCenter.shared, name: "Test Client")
    private func log(notification: AnySwiftMIDINotification) {
        print(notification.description.replacingOccurrences(of: ";", with: "\r    "))
        if notification is SwiftMIDI.Notification.SetUpChanged {
            print("---------- Setup Did Change ------------")
        }
    }
}

#endif
