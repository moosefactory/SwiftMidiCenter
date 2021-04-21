//
//  MidiDeviceParc.swift
//  SwiftMidiCenter
//
//  Created by Tristan Leblanc on 21/04/2021.
//


import Foundation
import CoreMIDI
import SwiftMIDI

public struct MidiDeviceParc {
    
    static let shared = MidiDeviceParc()
    
    public var allDevices: [MidiDevice] {
        return internalDevices.allDevices + externalDevices.allDevices
    }
    
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

    public func entity(for connectionId: Int) -> MidiEntity? {
        return internalDevices.entity(for: connectionId) ?? externalDevices.entity(for: connectionId)
    }
}

extension MidiDeviceParc: CustomDebugStringConvertible {
    public var debugDescription: String {
        var out = " - MidiDeviceParc"
        out += "\r   - Internal Devices"
        out += "\r\(internalDevices)"
        out += "\r   - External Devices"
        out += "\r\(externalDevices)"
        return out
    }
}
