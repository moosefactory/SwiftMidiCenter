//
//  File.swift
//  
//
//  Created by Tristan Leblanc on 01/02/2021.
//

import Foundation
import CoreMIDI
import SwiftMIDI

public final class StudioFile: Codable {
    
    public struct Notifications {
        // Use this notification when changing studio config in client application
        public static let changed = Notification.Name(rawValue: "com.moosefactory.midiCenter.studioConfigurationChanged")
    }
    
    // The keys used in the change notification dictionary
    public struct Keys {
        /// Sent when the user adds or removes clock destinations
        public static let clockDestinations = "clockDestinations"
        /// Sent when the user select the outputs he needs in his project
        public static let usedOutputs = "usedOutputs"
        /// Sent when the user select the inputs he needs in his project
        public static let usedInputs = "usedInputs"
        /// Sent when the user renames an outlet
        public static let renamedOutlet = "renamedOutlet"
        public static let patchbay = "patchbay"
    }
    
    public private(set) var midiPatchbay: MidiPatchBay
    
    public private(set) var entities: [MidiEntity]
    
    // User configuration
    
    public var clockDestinations: [MidiOutlet] {
        didSet {
            NotificationCenter.default.post(name: Notifications.changed, object: self, userInfo: [Keys.clockDestinations: clockDestinations])
        }
    }
    
    public var usedOutputUUIDs: [UUID] {
        didSet {
            NotificationCenter.default.post(name: Notifications.changed, object: self, userInfo: [Keys.usedOutputs: usedOutputs])
        }
    }

    public var usedInputUUIDs: [UUID] {
        didSet {
            NotificationCenter.default.post(name: Notifications.changed, object: self, userInfo: [Keys.usedInputs: usedInputs])
        }
    }
    
    public var usedInputs: [MidiOutlet] {
        return usedInputUUIDs.compactMap { midiPatchbay.input.outlet(with: $0) }
    }
    
    public var usedOutputs: [MidiOutlet] {
        return usedOutputUUIDs.compactMap { midiPatchbay.output.outlet(with: $0) }
    }
    
    // MARK: - JSON Keys
    
    enum CodingKeys: String, CodingKey {
        case midiPatchbay
        case entities
        case clockDestinations
        case usedOutputUUIDs = "usedOutputs"
        case usedInputUUIDs = "usedInputs"
    }
    
    // MARK: - Initialisation

    init(midiPatchBay: MidiPatchBay) {
        self.midiPatchbay = midiPatchBay
        self.entities = [MidiEntity]()
        self.clockDestinations = [MidiOutlet]()
        self.usedInputUUIDs = [UUID]()
        self.usedOutputUUIDs = [UUID]()
    }
    
    // MARK: - JSON Encoding/Decoding

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        midiPatchbay = (try? values.decode(MidiPatchBay.self, forKey: .midiPatchbay)) ?? MidiPatchBay()
        entities = (try? values.decode([MidiEntity].self, forKey: .entities)) ?? []
        clockDestinations = (try? values.decode([MidiOutlet].self, forKey: .clockDestinations)) ?? []
        usedInputUUIDs = (try? values.decode([UUID].self, forKey: .usedInputUUIDs)) ?? []
        usedOutputUUIDs = (try? values.decode([UUID].self, forKey: .usedOutputUUIDs)) ?? []
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(midiPatchbay, forKey: .midiPatchbay)
        try container.encode(entities, forKey: .entities)
        try container.encode(clockDestinations, forKey: .clockDestinations)
        try container.encode(usedInputUUIDs, forKey: .usedInputUUIDs)
        try container.encode(usedOutputUUIDs, forKey: .usedOutputUUIDs)
    }

    // MARK: - Notification
    
    public func outletNameChanged(_ outlet: MidiOutlet) {
        if let input = midiPatchbay.input.outlet(for: outlet.name) {
            NotificationCenter.default.post(name: Notifications.changed, object: self, userInfo: [Keys.renamedOutlet: input, Keys.patchbay: midiPatchbay.input])
        } else if let output = midiPatchbay.output.outlet(for: outlet.name) {
            NotificationCenter.default.post(name: Notifications.changed, object: self, userInfo: [Keys.renamedOutlet: output, Keys.patchbay: midiPatchbay.output])
        }
    }
}
