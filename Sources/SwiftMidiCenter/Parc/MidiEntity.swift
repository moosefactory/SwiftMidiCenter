//  MidiEntity.swift
//  Created by Tristan Leblanc on 10/01/2021.

import Foundation
import CoreMIDI
import SwiftMIDI

public class MidiEntity: Codable, MidiObject {
    
    /// Unique Identifier in SwiftMidiCenter
    
    public private(set) var uuid = UUID()
    
    /// The device name
    
    public private(set) var name: String
    
    /// The associated CoreMidi enpoint object
    
    public var ref: MIDIEntityRef
        
    public var uniqueID: Int { return ref.uniqueID }
    
    /// Is the device available or not
        
    public var available: Bool {
        let firstDest = try? SwiftMIDI.destination(for: ref, at: 0)
        let firstSource = try? SwiftMIDI.source(for: ref, at: 0)
        
        let onlineDest = firstDest != nil
        ? SwiftMIDI.allDestinations.first { $0 == firstDest! }
        : nil
        
        let onlineSource = firstSource != nil
        ? SwiftMIDI.allSources.first { $0 == firstSource! }
        : nil
        
        return onlineDest != nil || onlineSource != nil
    }

    // MARK: - Initialize

    public init(ref: MIDIEntityRef) {
        self.ref = ref
        self.name = ref.properties.name
    }

    // MARK: - Access endpoints
    
    public var endpoints: [MIDIEndpointRef] { sources + destinations }
    
    public func endpoint(for connectionID: Int) -> MIDIEndpointRef? {
        endpoints.first(where: {$0.connectionId == connectionID})
    }
    
    /// return all connection ids found in sources and destinations
    var connectionIDs: [Int] {
        endpoints.reduce([Int]()) { result, endpoint in
            if endpoint.connectionId != 0 {
                return result + [endpoint.connectionId]
            }
            return result
        }
    }

    // MARK: - Access destinations endpoints
    
    public var numberOfDestinations: Int {
        (try? SwiftMIDI.numberOfDestinations(for: ref)) ?? 0
    }
    
    public var destinations: [MIDIEndpointRef] {
        return (try? SwiftMIDI.allDestinations(in: ref)) ?? []
    }
    
    public func forEachDestination(do closure: (MIDIEndpointRef)->Void) {
        destinations.forEach { closure($0) }
    }
    
    // MARK: - Access sources
    
    public var numberOfSources: Int {
        (try? SwiftMIDI.numberOfSources(for: ref)) ?? 0
    }
    
    public var sources: [MIDIEndpointRef] {
        return (try? SwiftMIDI.allSources(in: ref)) ?? []
    }
    
    public func forEachSource(do closure: (MIDIEndpointRef)->Void) {
        sources.forEach { closure($0) }
    }

}


extension MidiEntity: Hashable {
    
    public static func == (lhs: MidiEntity, rhs: MidiEntity) -> Bool {
        return lhs.uuid == rhs.uuid && lhs.ref == rhs.ref
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
        hasher.combine(ref)
    }
}

extension MidiEntity: CustomStringConvertible {

    public var description: String {
        let avail = available ? "Plugged" : "Unplugged"
        var out = "Entity '\(name)' - id:\(uniqueID) - ref:\(ref) - \(avail)"
        out += "\r            - Sources"
        sources.forEach { out += "\r              + '\($0.name)' - id:\($0.uniqueID) - ref:\($0) - cnx:\($0.connectionId)"
        }
        out += "\r            - Destinations"
        destinations.forEach { out += "\r              + '\($0.name)' - id:\($0.uniqueID) - ref:\($0) - cnx:\($0.connectionId)"
        }
        return out
    }
}
