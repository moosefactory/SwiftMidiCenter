//  MidiDevicesParc.swift
//  Created by Tristan Leblanc on 10/01/2021.

import Foundation
import CoreMIDI
import SwiftMIDI

public class MidiDevicesParc: ObservableObject {
    
    public static let shared = MidiDevicesParc()
    
    @Published var devices: [MidiDevice]

    var entities: [MidiEntity] {
        return devices.flatMap { $0.entities }
    }

    public init() {
        let deviceRefs = (try? SwiftMIDI.allDevices()) ?? [MIDIDeviceRef]()
        self.devices = deviceRefs.map { MidiDevice(ref: $0) }
    }
    
    public init(devices: [MidiDevice] = []) {
        self.devices = devices
    }
    
    public func device(with name: String) -> MidiDevice? {
        return devices.first { $0.name == name }
    }
    
    public func forEachDevice(do closure: (MidiDevice)->Void) {
        devices.forEach { closure($0) }
    }
    
    public func entity(for entityRef: MIDIEntityRef) -> MidiEntity? {
        entities.first { $0.ref == entityRef }
    }
}
