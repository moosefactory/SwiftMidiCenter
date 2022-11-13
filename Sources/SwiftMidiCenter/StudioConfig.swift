//
//  File.swift
//  
//
//  Created by Tristan Leblanc on 01/02/2021.
//

import Foundation
import CoreMIDI
import SwiftMIDI

public let studioConfigurationChanged = Notification.Name(rawValue: "com.moosefactory.midiCenter.studioConfigurationChanged")

public final class StudioFile: Codable, ObservableObject {
    
    public struct Notifications {
        // Use this notification when changing studio config in client application
        public static let changed = Notification.Name(rawValue: "com.moosefactory.midiCenter.studioConfigurationChanged")
    }
    
    // The keys used in the change notification dictionary
    public struct Keys {
        /// Sent when the user changes the clock source
        public static let clockSource = "clockSource"
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
    
    /// An optional name
    public var name: String = "Studio Configuration"

    /// An optional name
    public var uuid: UUID = UUID()

    // User configuration
    
    @Published public var clockSource: MidiOutlet? {
        didSet {
            NotificationCenter.default.post(name: Notifications.changed,
                                            object: self,
                                            userInfo: clockSource == nil ? [:] : [Keys.clockSource: clockSource!])
        }
    }

    @Published public var clockDestinations: [MidiOutlet] {
        didSet {
            NotificationCenter.default.post(name: Notifications.changed, object: self, userInfo: [Keys.clockDestinations: clockDestinations])
        }
    }
    
    @Published public var usedOutputUUIDs: [UUID] {
        didSet {
            NotificationCenter.default.post(name: Notifications.changed, object: self, userInfo: [Keys.usedOutputs: usedOutputs])
        }
    }
    
    @Published public var usedInputUUIDs: [UUID] {
        didSet {
            NotificationCenter.default.post(name: Notifications.changed, object: self, userInfo: [Keys.usedOutputs: usedOutputs])
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
        case name
        case uuid
        case midiPatchbay
        case entities
        case clockSource
        case clockDestinations
        case usedOutputUUIDs = "usedOutputs"
        case usedInputUUIDs = "usedInputs"
    }
    
    // MARK: - Initialisation

    init(midiCenter: MidiCenter) {
        self.midiPatchbay = midiCenter.midiBay
        self.entities = midiCenter.entities
        self.clockDestinations = [MidiOutlet]()
        self.usedInputUUIDs = midiCenter.deviceConnections.connections.values.compactMap { $0.outlet?.uuid }
        self.usedOutputUUIDs = midiCenter.deviceConnections.connections.values.compactMap { $0.outlet?.uuid }
    }
    
    // MARK: - JSON Encoding/Decoding

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        name = (try? values.decode(String.self, forKey: .name)) ?? "Studio Configuration"
        uuid = (try? values.decode(UUID.self, forKey: .uuid)) ?? UUID()

        midiPatchbay = (try? values.decode(MidiPatchBay.self, forKey: .midiPatchbay)) ?? MidiPatchBay()
        entities = (try? values.decode([MidiEntity].self, forKey: .entities)) ?? []
        clockSource = (try? values.decode(MidiOutlet.self, forKey: .clockSource))
        clockDestinations = (try? values.decode([MidiOutlet].self, forKey: .clockDestinations)) ?? []
        usedInputUUIDs = (try? values.decode([UUID].self, forKey: .usedInputUUIDs)) ?? []
        usedOutputUUIDs = (try? values.decode([UUID].self, forKey: .usedOutputUUIDs)) ?? []
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        try container.encode(uuid, forKey: .uuid)

        try container.encode(midiPatchbay, forKey: .midiPatchbay)
        try container.encode(entities, forKey: .entities)
        try container.encode(clockSource, forKey: .clockSource)
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
