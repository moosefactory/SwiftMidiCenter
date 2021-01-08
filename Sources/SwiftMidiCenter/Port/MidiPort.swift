//
//  MidiPort.swift
//  MidiCenter
//
//  Created by Tristan Leblanc on 02/01/2021.
//

import Foundation
import CoreMIDI
import SwiftMIDI

public class MidiPort: MidiObject, ObservableObject, Identifiable {
    
    /// The CoreMidi port refCon
    public internal(set) var ref: MIDIPortRef = 0
    
    /// The port name - better to choose a lowercase spaceless name
    public private(set) var name: String // Last identifier component
    
    /// The port identifier, in reverse path style
    public private(set) var identifier: String
    
    /// The owner client
    public private(set) weak var client: MidiClient?
    
    internal init(client: MidiClient, name: String = "input") throws {
        self.name = name
        self.client = client
        self.identifier = "\(client.identifier).\(name)"
        try open()
    }
    
    func open() throws {
        fatalError("One must create either an input or output port")
    }
    
    func close() throws {
        fatalError("One must create either an input or output port")
    }
}

extension MidiPort: Hashable {
    public static func == (lhs: MidiPort, rhs: MidiPort) -> Bool {
        lhs.identifier == rhs.identifier
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}

