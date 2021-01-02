//
//  OutputPort.swift
//  MidiCenter
//
//  Created by Tristan Leblanc on 02/01/2021.
//

import Foundation
import CoreMIDI
import SwiftMIDI

public class OutputPort: MidiPort {
    
    override func open() throws {
        guard let client = client else {
            throw MidiCenter.Errors.clientNotSet
        }
        guard client.ref != 0 else {
            throw MidiCenter.Errors.clientNotSet
        }
        try ref = SwiftMIDI.createOutputPort(clientRef: client.ref, portName: identifier)
    }
}
