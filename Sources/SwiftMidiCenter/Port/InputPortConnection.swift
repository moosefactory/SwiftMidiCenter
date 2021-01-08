//
//  InputConnection.swift
//  MidiCenter
//
//  Created by Tristan Leblanc on 02/01/2021.
//

import Foundation
import CoreMIDI
import SwiftMIDI

public struct RefCon {
    weak var port: InputPort?

    /// The connection identifier
    var connectionIdentifier: String
    /// The CoreMIDI Source that sends data
    var outlet: MidiOutlet
    
    var identifier: String {
        "\(connectionIdentifier) : \(outlet.name)"
    }
}

/// InputPortConnect
///
/// This object manage a unique connection between a midi source and an input port
public class InputPortConnection {
    /// The connection outlet
    private(set) var outlet: MidiOutlet
    /// The connection port
    private(set) var port: InputPort
    
    /// A refcon object, used to identifiy messages from this outlet in the input port
    public var refCon: RefCon
    
    // MARK: - Initialisation
    
    init(identifier: String, port: InputPort, source: MidiOutlet) throws {
        self.port = port
        self.outlet = source
        self.refCon = RefCon(port: port, connectionIdentifier: identifier, outlet: source)
        try open()
    }
    
    // MARK: - Open/Close connection
    
    func open() throws {
        guard outlet.ref != 0 else {
            throw SwiftMIDI.Errors.sourceRefNotSet
        }
        guard port.ref != 0 else {
            throw SwiftMIDI.Errors.inputPortRefNotSet
        }
        try SwiftMIDI.connect(source: outlet.ref, to: port.ref, refCon: &refCon)
    }
    
    func close() throws {
        guard outlet.ref != 0 else {
            throw SwiftMIDI.Errors.sourceRefNotSet
        }
        guard port.ref != 0 else {
            throw SwiftMIDI.Errors.inputPortRefNotSet
        }
        try SwiftMIDI.disconnect(source: outlet.ref, from: port.ref)
    }
}

extension InputPortConnection: Hashable {
    public static func == (lhs: InputPortConnection, rhs: InputPortConnection) -> Bool {
        lhs.refCon.identifier == rhs.refCon.identifier
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(refCon.identifier)
    }
}
