//
//  MidiCenter.swift
//  MidiCenter
//
//  Created by Tristan Leblanc on 27/12/2020.
//

import Foundation
import CoreMIDI
import SwiftUI
import Combine
import SwiftMIDI

public class NewConnectionInfo: Identifiable, ObservableObject, Equatable {
    public static func == (lhs: NewConnectionInfo, rhs: NewConnectionInfo) -> Bool {
        return lhs.name == rhs.name
            && lhs.channels == rhs.channels
            && lhs.range == rhs.range
            && lhs.connectionType == rhs.connectionType
    }
    
    public var name: String = "main"
    public var connectionType: ConnectionType = .packets
    public var range: MidiRange = MidiRange()
    public var channels: MidiChannelMask = .all {
        didSet {
            objectWillChange.send()
        }
    }
    
    public var connectionTypeIndex: Int {
        get {
            return connectionType.rawValue
        }
        set {
            connectionType = ConnectionType(rawValue: newValue) ?? ConnectionType.packets
        }
    }
    
    public init(name: String, portType: ConnectionType = .packets, range: MidiRange = MidiRange()) {
        self.name = name
        self.connectionType = portType
        self.range = range
    }
    
    
}

public typealias MidiCenter = SwiftMidiCenter

/// MidiCenter
///
/// The MidiCenter object is responsible of:
/// - Keep a reference to the midi client ( MIDIClient )
/// - Keep track of the available midi inputs and midi outputs ( input and output MidiBays )
/// - Keep track of the MidiThru connections

public class SwiftMidiCenter: ObservableObject {
    
    public static var shared = MidiCenter(identifier: "com.moosefactory.midi")
    
    /// The unique identifier in reverse path style ( 'com.yourCompany.yourMidiThing' )
    public private(set) var identifier: String
    
    /// The default CoreMidi client ref
    @Published public var client: MidiClient!

    /// The midi patch bay
    @Published public var midiBay = MidiPatchBay()

    /// The changing midi patch bay
    ///
    /// When setup is changed, we first prepare the next patchBay.
    /// We commit when we receive a `setUpChanged` notification
    internal var changingMidiBay = MidiPatchBay()

    /// The direct midi thru connections
    ///
    /// IS THIS CORE MIDI API BUGGED ?
    /// NO WAY TO FORWARD FROM KEYBOARD TO DEVICE ON MACOS BIG SUR 11.1
    //@Published public var midiThruConnections = [MidiThru]()

    /// The midi thru input connections
    //@Published public var thruConnections = [MidiConnection]()

    /// The midi connections
    //@Published public var connections = [MidiConnection]()

    var cancellables = [String: AnyCancellable]()
    
    var networkManager: MIDINetworkManager
    
    var inputPort: InputPort { client.inputPort }
    
    // MARK: - Initialisation
    
    public init(identifier: String) {
        self.identifier = identifier

        networkManager = MIDINetworkManager()

        do {
            // Creates a midi client with a default input port
            client = try MidiClient(midiCenter: self, name: "defaultClient")
            
           // #if CREATE_MIDI_THRU_CLIENT
            // Opens the midi thru port
            
//            try client?.openInputPortWithPacketsReader(type: .packets)  { packetList, refCon in
//                guard let mainOut = self.client?.mainOut,
//                      !self.thruConnections.isEmpty else { return }
//
//                self.thruConnections.forEach { connection in
//                    guard connection.enabled else { return }
//                    connection.destinations.forEach { outlet in
//                        try? SwiftMIDI.send(port: mainOut.ref, destination: outlet.ref, packetListPointer: packetList)
//                    }
//                }
//            }
//
//           // #endif
//
//            // Opens the midi events port
//
//            try client?.openInputPortWithEventsReader { packetList, events, connectionRefCon in
//
//                guard let mainInEvents = self.client?.mainInEventsPort,
//                      !self.connections.isEmpty else { return }
//
//                self.connections.forEach {connection in
//                    //MIDISendEventList(eventsPort.ref, connection.destination.ref, <#T##evtlist: UnsafePointer<MIDIEventList>##UnsafePointer<MIDIEventList>#>)
//                }
//            }
//
            try initMidi()
        } catch {
            fatalError(error.localizedDescription)
        }

    }
            
    /// Restart the midi server
    public func reset() throws {
        try SwiftMIDI.restart()
    }
    
    /// Remove all midi thru connections
    public func removeAllMidiConnections() {
//        while let thru = midiThruConnections.popLast() {
//            do {
//                if let ref = thru.connectionRef {
//                    try SwiftMIDI.removeMidiThruConnection(connectionRef: ref)
//                }
//            } catch {
//                print(error)
//            }
//        }
    }

    public func createPersistentThruConnection() throws {
        let thru = MidiThru()
        if let err = thru.stickyError {
            throw err
        }
    }
}

extension SwiftMidiCenter {

    func input(with identifier: String) -> MidiOutlet? {
        midiBay.input.outlet(with: identifier)
    }

    func output(with identifier: String) -> MidiOutlet? {
        midiBay.output.outlet(with: identifier)
    }
}

#if DEBUG

extension SwiftMidiCenter {

    /// To use in tests and swiftui previews
    public static var test: MidiCenter = {
        let mc = MidiCenter(identifier: "com.moosefactory.midiDebug")
        mc.midiBay.input = MidiBay.testIn
        mc.midiBay.output = MidiBay.testOut
        return mc
    }()

}

#endif
