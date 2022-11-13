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
    
    /// The devices registered in system
    /// A registered device does not mean it is online
    
    @Published public var parc = MidiDeviceParc()

    public var deviceConnections: MidiDeviceConnectionSet {
        MidiDeviceConnectionSet(parc: parc, patchBay: midiBay)
    }
    
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
    
    public var inputPort: InputPort { client.inputPort }
    public var outputPort: OutputPort { client.outputPort }
    
    public var setupCommited: (()->Void)?
    
    public var studioFileURL: URL? {
        didSet {
            try? loadStudio()
        }
    }
    
    func loadStudio() throws {
        guard let studioFileURL = studioFileURL else { return }
        let data = try Data(contentsOf: studioFileURL)
        let studioFile = try JSONDecoder().decode(StudioFile.self, from: data)
        midiBay = studioFile.midiPatchbay
    }
    
    /// Creates StudioConfig from midi center ( system configuration )
    public func makeStudioData() -> StudioFile {
        return StudioFile(midiCenter: self)
    }
    
    // MARK: - Initialisation
    
    
    public init(identifier: String, studioFileURL: URL? = nil) {
        self.identifier = identifier
        
        networkManager = MIDINetworkManager()
        
        do {
            // Creates a midi client with a default input port
            client = try MidiClient(midiCenter: self, name: "defaultClient") { packetList, refCon in
                
                // We capture allevents
                MidiEventsDecoder().unpackEvents(packetList) {
                    print($0)
                }
            }
            try publishMidiBayChange()
            do {
                let connections = try SwiftMIDI.findMidiThruConnections(owner: "")
                for connection in connections.enumerated() {
                    let cnx = connection.element
                    print("Cnx \(connection.offset) : \(cnx) - \(cnx.name)")
                }
            }
            catch {
                print(error)
            }
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
    
    public func newConnection(inputOutlets: [MidiOutlet], outputOutlets: [MidiOutlet], filter: MidiFilterSettings) throws -> MidiConnection {
        let cnx = MidiConnection(name: "Connection",
                                 filter: filter,
                                 inputPort: inputPort,
                                 outputPort: outputPort,
                                 sources: inputOutlets,
                                 destinations: outputOutlets)
        try client.addConnection(cnx, in: inputPort)
        return cnx
    }
}

extension SwiftMidiCenter {
    
    func input(with uuid: UUID) -> MidiOutlet? {
        midiBay.input.outlet(with: uuid)
    }
    
    func input(withUniqueID id: Int) -> MidiOutlet? {
        midiBay.input.outlet(withUniqueID: id)
    }

    func output(with uuid: UUID) -> MidiOutlet? {
        midiBay.output.outlet(with: uuid)
    }

    func output(withUniqueID id: Int) -> MidiOutlet? {
        midiBay.output.outlet(withUniqueID: id)
    }
}

extension SwiftMidiCenter: CustomDebugStringConvertible {
    public var debugDescription: String {
        var out = "MidiCenter '\(identifier)'"
        out += "\r  - Client: \(client == nil ? "<none>" : client.description)"
        out += "\r  - Midi PatchBay: \(midiBay)"
        out += "\r  - Midi Parc: \(parc)"
        out += "\r  - Connections: \(deviceConnections)"
        return out
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
