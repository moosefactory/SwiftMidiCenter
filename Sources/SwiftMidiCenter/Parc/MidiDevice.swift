//  MidiDevice.swift
//  Created by Tristan Leblanc on 10/01/2021.

import Foundation
import CoreMIDI
import SwiftMIDI

public class MidiDeviceConnectionSet {
        
    var connections = [Int: MidiDeviceConnection]()
    
    init(parc: MidiDeviceParc, patchBay: MidiPatchBay) {
        var connections = [Int: MidiDeviceConnection]()
        parc.externalDevices.allDevices.forEach { device in
            device.connectionIDs.forEach {
                connections[$0] = MidiDeviceConnection(connectionID: $0, device: device)
            }
        }
        self.connections = connections
        
        self.attach(to: patchBay)
    }
    
    func attach(to patchbay: MidiPatchBay) {
        connections.values.forEach { $0.outlet = nil }
        patchbay.allOutlets.forEach { outlet in
            if connections[outlet.uniqueID] != nil {
                connections[outlet.uniqueID]!.outlet = outlet
                if let device = connections[outlet.uniqueID]!.device {
                    outlet.displayName = device.name
                }
            }
        }
    }
    
    func clear() {
        connections.removeAll()
    }
    
    func connection(for connectionID:Int) -> MidiDeviceConnection? {
        return connections[connectionID]
    }
    
    func newConnection(connectionID: Int, device: MidiDevice) {
        connections[connectionID] = MidiDeviceConnection(connectionID: connectionID, device: device)
    }
}

extension MidiDeviceConnectionSet: CustomDebugStringConvertible {
    public var debugDescription: String {
        connections.reduce(""){ result, connection in
            result + "\r   > \(connection)"
        }
    }
}

public class MidiDeviceConnection {
    /// The CoreMidi connection unique id
    var uniqueID: Int
    
    init(connectionID: Int, device: MidiDevice) {
        self.uniqueID = connectionID
        self.device = device
    }
    
    var deviceEndpointRef: MIDIEndpointRef = 0
    var device: MidiDevice? = nil
    
    var outletEndpointRef: MIDIEndpointRef = 0
    var outlet: MidiOutlet? = nil
}

extension MidiDeviceConnection: CustomDebugStringConvertible {
    public var debugDescription: String {
        let outletStr = outlet != nil ? "\(outlet!.name)" : "<not set>"
        let deviceStr = device != nil ? "\(device!.name)" : "<not set>"
        return "Connection \(uniqueID) - outlet: \(outletStr) - device: \(deviceStr)"
    }
}


public class MidiDevice: Codable, MidiObject {
    
    /// Unique Identifier in SwiftMidiCenter
    
    public private(set) var uuid = UUID()
    
    /// The device name
    
    public private(set) var name: String
    
    /// The associated CoreMidi enpoint object
    
    public var ref: MIDIDeviceRef
    
    public var uniqueID: Int { return ref.uniqueID }

    /// Is the device available or not
    
    public var entities: [MidiEntity]
    
    var available: Bool { !ref.offline }

    public init(ref: MIDIDeviceRef) {
        self.ref = ref
        self.name = ref.properties.name
        
        let entitiesRefs = (try? SwiftMIDI.allEntities(in: ref)) ?? [MIDIEntityRef]()
        self.entities = entitiesRefs.map { MidiEntity(ref: $0) }
    }
    
    var connectionIDs: [Int] {
        entities.reduce([Int]()) { result, entity in
            return result + entity.connectionIDs
        }
    }
    
    var endpointUniqueIDs: [Int] {
        entities.reduce([Int]()) { result, entity in
            return result + (entity.endpoints.map { $0.uniqueID })
        }
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
        let avail = available ? "Available" : "Unavailable"
        let out = "Device '\(name)' id: \(uniqueID) - ref:\(ref) - \(avail)"
        return entities.reduce(out) { result, entity in
            result + "\r     • \(entity)"
        }
    }
}
