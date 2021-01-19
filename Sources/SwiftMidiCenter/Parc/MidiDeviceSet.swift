//  MidiDevicesParc.swift
//  Created by Tristan Leblanc on 10/01/2021.

import Foundation
import CoreMIDI
import SwiftMIDI

public struct MidiDeviceParc {
    
    static let shared = MidiDeviceParc()
    
    public let internalDevices = MidiDeviceSet(external: false)
    public let externalDevices = MidiDeviceSet(external: true)
    
    public func device(with uuid: UUID) -> MidiDevice? {
        return internalDevices.device(with: uuid) ?? externalDevices.device(with: uuid)
    }
    
    public func device(with name: String) -> MidiDevice? {
        return internalDevices.device(with: name) ?? externalDevices.device(with: name)
    }

    public func entity(for entityRef: MIDIEntityRef) -> MidiEntity? {
        return internalDevices.entity(for: entityRef) ?? externalDevices.entity(for: entityRef)
    }
}

/// MidiDeviceParc represents the physical devices actually known in the system
///
/// Devices can be added/removed/edited in the **Audio Midi Setup** application

public class MidiDeviceSet: ObservableObject {
        
    @Published var devices: [MidiDevice]
    
    public private(set) var external: Bool
    
    var entities: [MidiEntity] {
        return devices.flatMap { $0.entities }
    }
    
    public var all: [MidiDevice] {
        return devices
    }
    
    // MARK: - Initialisation
    
    public init(external: Bool) {
        self.external = external
        do {
            let deviceRefs = external ? try SwiftMIDI.allExternalDevices() : try SwiftMIDI.allDevices()
            self.devices = deviceRefs.map { MidiDevice(ref: $0) }
        } catch {
            self.devices = []
        }
    }
    
    // MARK: - Accessing devices
    
    public var allDevices: [MidiDevice] { devices }
    
    
    public func indexOfDevice(with uuid: UUID) -> Int? {
        return allDevices.firstIndex(where: { $0.uuid == uuid })
    }
    
    public func device(with uuid: UUID) -> MidiDevice? {
        return devices.first { $0.uuid == uuid }
    }
    
    public func device(with name: String) -> MidiDevice? {
        return devices.first { $0.name == name }
    }
    
    public func forEachDevice(do closure: (MidiDevice)->Void) {
        devices.forEach { closure($0) }
    }
    
    // MARK: - Accessing entities
    
    public var allEntities: [MidiEntity] { entities }
    
    public func indexOfEntity(with uuid: UUID) -> Int? {
        return allEntities.firstIndex(where: { $0.uuid == uuid })
    }
    
    public func entity(with uuid: UUID) -> MidiEntity? {
        return entities.first { $0.uuid == uuid }
    }
    
    public func entity(for entityRef: MIDIEntityRef) -> MidiEntity? {
        entities.first { $0.ref == entityRef }
    }
}
