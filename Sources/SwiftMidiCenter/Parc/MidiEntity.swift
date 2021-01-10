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
        
    /// Is the device available or not
        
    public var numberOfDestinations: Int {
        (try? SwiftMIDI.numberOfDestinations(for: ref)) ?? 0
    }
    
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
    
    public var numberOfSources: Int {
        (try? SwiftMIDI.numberOfSources(for: ref)) ?? 0
    }
    
    public init(ref: MIDIEntityRef) {
        self.ref = ref
        self.name = ref.properties.name
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
        return "Entity \(ref) - \(name) - \(avail)"
    }
}
