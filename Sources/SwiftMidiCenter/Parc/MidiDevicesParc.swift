//  MidiDevicesParc.swift
//  Created by Tristan Leblanc on 10/01/2021.

import Foundation
import CoreMIDI
import SwiftMIDI

/// MidiDeviceParc represents the physical devices actually known in the system
///
/// Devices can be added/removed/edited in the **Audio Midi Setup** application

public class MidiDevicesParc: ObservableObject {
    
    public static let shared = MidiDevicesParc()
    
    @Published var devices: [MidiDevice]

    var entities: [MidiEntity] {
        return devices.flatMap { $0.entities }
    }

    // MARK: - Initialisation
    
    public init() {
        let deviceRefs = (try? SwiftMIDI.allDevices()) ?? [MIDIDeviceRef]()
        self.devices = deviceRefs.map { MidiDevice(ref: $0) }
    }
    
    public init(devices: [MidiDevice] = []) {
        self.devices = devices
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
