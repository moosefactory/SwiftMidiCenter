//  MidiDevicesParc.swift
//  Created by Tristan Leblanc on 10/01/2021.

import Foundation
import CoreMIDI
import SwiftMIDI


/// MidiDeviceSet represents an ensemble of devices actually known in the system
///
/// Devices can be added/removed/edited in the **Audio Midi Setup** application

public class MidiDeviceSet: ObservableObject {
    
    @Published public var devices: [MidiDevice]
    
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
    
    /// insert(device:)
    ///
    /// Inserts a new device in the device set.
    /// This function is called when a midi configuration change notification of type 'device added' is received.
    public func insert(device: MidiDevice) {
        devices.append(device)
    }
    
    public func remove(ref: MIDIObjectRef) {
        devices = devices.filter { $0.ref == ref }
    }
    
    public func rename(ref: MIDIObjectRef, newName: String) {
        if var device = (devices.first { $0.ref == ref }) {
            device.name = newName
        }
    }

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
    
    public func entity(for connectionID: Int) -> MidiEntity? {
        entities.first { $0.endpoint(for: connectionID) != nil }
    }
}

extension MidiDeviceSet: CustomDebugStringConvertible {
    public var debugDescription: String {
        return devices.reduce(" - MidiDeviceParc - Externel : \(external)") { result, device in
            result + "\r   - \(device)"
        }
    }
}
