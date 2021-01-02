//
//  MidiThru.swift
//  MidiCenter
//
//  Created by Tristan Leblanc on 28/12/2020.
//

import Foundation
import CoreMIDI
import SwiftMIDI

// TODO: Change to MidiConnection subclass and understand why it does not work on MacOS 11.1 Big Sur

/// MidiThru objects establish a connection between a source and a destination
public final class MidiThru: Codable, ObservableObject, MidiWire, Identifiable {
    
    public var inputOutletsDidChange: ((MidiWireChangeParams<MidiThru>) -> Void)?
    
    public var outputOutletsDidChange: ((MidiWireChangeParams<MidiThru>) -> Void)?

    /// Unique identifier
    public private(set) var uuid: UUID = UUID()
    
    public var name: String { "com.moosefactory.midiCenter.thru.\(uuid.uuidString)"}
        
    public var connectionRef: MIDIThruConnectionRef?

    @Published public var sources = [MidiOutlet]()
    @Published public var destinations = [MidiOutlet]()

    var stickyError: SwiftMIDI.MidiError?
    
    
    /// The CoreMidi Input port reference - set when connected
    var inputPortRef = MIDIPortRef()
    
    /// The CoreMidi Output port reference - set when connected
    var outputPortRef = MIDIPortRef()

    var monitoring: Bool = true
    
    /// MidiThru Coding Keys
    ///
    /// A MidiThru object can be saved in defaults or application data
    enum CodingKeys: String, CodingKey {
        case uuid
        case sources
        case destinations
    }
    
    // MARK: - Initialisation
    
    public init() {
        do {
            try update()
        }
        catch {
            stickyError = error as? SwiftMIDI.MidiError
        }
    }

    /// Init from an existing CoreMidi midi thru connection
    public init(with connectionRef: MIDIThruConnectionRef) {
        self.connectionRef = connectionRef
        do {
            try update()
        } catch {
            stickyError = error as? SwiftMIDI.MidiError
        }
    }

    // MARK: - Coding/Decoding
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        uuid =  (try? values.decode(UUID.self, forKey: .sources)) ?? UUID()
        sources = (try? values.decode([MidiOutlet].self, forKey: .sources)) ?? []
        destinations = (try? values.decode([MidiOutlet].self, forKey: .destinations)) ?? []
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(sources, forKey: .sources)
        try container.encode(destinations, forKey: .destinations)
    }
    
    // MARK: - Parameters Update

    public func update() throws {
        var params: MIDIThruConnectionParams!
        
        if let cnxRef = connectionRef {
            params = try SwiftMIDI.getMidiThruConnectionParams(connectionRef: cnxRef)
        }

        if params == nil {
            (connectionRef, params) = try SwiftMIDI.createMidiThruConnection(name: name)
        }
        
        let sources: [MidiOutlet] = Array(self.sources.filter({ $0.ref != 0 }).prefix(8))
        params.numSources = UInt32(sources.count)

        withUnsafeMutablePointer(to: &params.sources) { pointer in
            pointer.withMemoryRebound(to: MIDIThruConnectionEndpoint.self, capacity: 8) { buffer in
                for source in sources.prefix(8).enumerated() {
                    buffer[source.offset] = MIDIThruConnectionEndpoint(endpointRef: source.element.ref, uniqueID: 0)
                }
            }
        }

        let destinations: [MidiOutlet] = Array(self.destinations.filter({ $0.ref != 0 }).prefix(8))
        params.numDestinations = UInt32(destinations.count)

        withUnsafeMutablePointer(to: &params.destinations) { pointer in
            pointer.withMemoryRebound(to: MIDIThruConnectionEndpoint.self, capacity: 8) { buffer in
                for destination in destinations.enumerated() {
                    buffer[destination.offset] = MIDIThruConnectionEndpoint(endpointRef: destination.element.ref, uniqueID: 0)
                }
            }
        }

        try SwiftMIDI.setMidiThruConnectionParams(connectionRef: connectionRef!, params: params)
        
        // DIRTY HACK-To Move in MidiConnectionedition
        //
        
        MidiCenter.shared.updateConnection(coreThruUUID: self.uuid, sources: sources, destinations: destinations)
    }
}

extension MidiThru: Hashable {
    
    public static func == (lhs: MidiThru, rhs: MidiThru) -> Bool {
        lhs.uuid == rhs.uuid
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
}

#if DEBUG

public extension MidiThru {
    static let test = MidiThru()
}

#endif
