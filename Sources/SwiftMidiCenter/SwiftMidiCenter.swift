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
    @Published public var midiThruConnections = [MidiThru]()

    /// The midi thru input connections
    @Published public var thruConnections = [MidiConnection]()

    /// The midi connections
    @Published public var connections = [MidiConnection]()

    var cancellables = [String: AnyCancellable]()
    
    var networkManager: MIDINetworkManager
    
    var inputPorts: [InputPort] { client.inputPorts }
    
    // MARK: - Initialisation
    
    public init(identifier: String) {
        self.identifier = identifier

        networkManager = MIDINetworkManager()

        do {
            // Creates a midi client with a default input port
            client = try MidiClient(midiCenter: self, name: "defaultClient")
            
           // #if CREATE_MIDI_THRU_CLIENT
            // Opens the midi thru port
            
            try client?.openInputPortWithPacketsReader(type: .packets)  { packetList, refCon in
                guard let mainOut = self.client?.mainOut,
                      !self.thruConnections.isEmpty else { return }

                self.thruConnections.forEach { connection in
                    guard connection.enabled else { return }
                    connection.destinations.forEach { outlet in
                        try? SwiftMIDI.send(port: mainOut.ref, destination: outlet.ref, packetListPointer: packetList)
                    }
                }
            }
            
           // #endif
                        
            // Opens the midi events port

            try client?.openInputPortWithEventsReader { packetList, events, connectionRefCon in
                
                guard let mainInEvents = self.client?.mainInEventsPort,
                      !self.connections.isEmpty else { return }

                self.connections.forEach {connection in
                    //MIDISendEventList(eventsPort.ref, connection.destination.ref, <#T##evtlist: UnsafePointer<MIDIEventList>##UnsafePointer<MIDIEventList>#>)
                }
            }

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
        while let thru = midiThruConnections.popLast() {
            do {
                if let ref = thru.connectionRef {
                    try SwiftMIDI.removeMidiThruConnection(connectionRef: ref)
                }
            } catch {
                print(error)
            }
        }
    }
    
    func restoreConnections() throws {
        if let refs = try SwiftMIDI.findMidiThruConnections(owner: identifier) {
            midiThruConnections = refs.compactMap {
                MidiThru(with: $0)
            }
        }
    }

    public func createPersistentThruConnection() throws {
        let thru = MidiThru()
        if let err = thru.stickyError {
            throw err
        }
    }
    
    /// Create a new connection on the current client
    
    public func createConnection(in port: InputPort) throws {
        //try createPersistentThruConnection()
        //thruConnections.append(MidiConnection(sources: [], destinations: []))
        let connection = MidiConnection(port: port, sources: [], destinations: [])
        connections.append(connection)
        client.addConnection(connection, in: port)
        connection.inputOutletsDidChange = { changes in
            self.client.usedInputsDidChange(changes: changes)
        }
        connection.outputOutletsDidChange = { connection in
            //self.client.connectionDidChange(connection: connection)
        }
        objectWillChange.send()
    }
    
    public func createPort(type: InputPortType) throws {
        switch type {
        case .packets:
            try client.newThruInputPort() { packets, refCon in
                
            }
        case .events:
            try client.newEventsInputPort() { packets, events, refCon in
                
            }
        case .clock:
            try client.newClockInputPort() { timeStamp, channel, refCon in
                
            }
        case .transpose:
            try client.newTransposeInputPort() { note, channel , refCon in
                
            }
        case .controls:
            try client.newControlsInputPort() { packets, events, refCon in
                
            }
        }
        objectWillChange.send()
    }
    
    // DIRTY HACK
    public func updateConnection(coreThruUUID: UUID, sources: [MidiOutlet], destinations: [MidiOutlet]) {
        guard let index = connections.firstIndex(where: {$0.uuid == coreThruUUID}) else { return }
        connections[index].sources = sources
        connections[index].destinations = destinations
        thruConnections[index].sources = sources
        thruConnections[index].destinations = destinations
        // Faster
        //thruConnections[index].destinations = destinations
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
