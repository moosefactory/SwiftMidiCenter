//  MidiDevice.swift
//  Created by Tristan Leblanc on 10/01/2021.

import Foundation
import CoreMIDI
import SwiftMIDI

public class MidiDevice: Codable, MidiObject {
    
    /// Unique Identifier in SwiftMidiCenter
    
    public private(set) var uuid = UUID()
    
    /// The device name
    
    public private(set) var name: String
    
    /// The associated CoreMidi enpoint object
    
    public var ref: MIDIDeviceRef
        
    /// Is the device available or not
    
    public var available: Bool {
        return entities.first?.available ?? false
    }

    public var entities: [MidiEntity]
    
    public init(ref: MIDIDeviceRef) {
        self.ref = ref
        self.name = ref.properties.name
        
        let entitiesRefs = (try? SwiftMIDI.allEntities(in: ref)) ?? [MIDIEntityRef]()
        self.entities = entitiesRefs.map { MidiEntity(ref: $0) }
    }
}


extension MidiDevice: Hashable {
    
    public static func == (lhs: MidiDevice, rhs: MidiDevice) -> Bool {
        return lhs.uuid == rhs.uuid && lhs.ref == rhs.ref
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
        hasher.combine(ref)
    }
}

extension MidiDevice: CustomStringConvertible {

    public var description: String {
        let avail = available ? "Plugged" : "Unplugged"
        return "Device \(ref) - \(name) - \(avail)"
    }
}
