//
//  MidiPatchBay.swift
//  SwiftMidiCenter
//
//  Created by Tristan Leblanc on 21/04/2021.
//

import Foundation

/// MidiPatchBay
///
/// A MidiPatchBay object simply groups an input and an output bay.
///
/// It might represents a midi interface with x midi input/output
public struct MidiPatchBay: Codable {
    public var input = MidiBay()
    public var output = MidiBay()
    
    public var allOutlets: [MidiOutlet] {
        return input.outlets + output.outlets
    }
}

// MARK: Debug String

extension MidiPatchBay: CustomDebugStringConvertible {
    public var debugDescription: String {
        var out = " - MidiPatchBay - Inputs"
        out += "\r \(input)"
        out += " - MidiPatchBay - Outputs"
        out += "\r \(output)"
        return out
    }
}
