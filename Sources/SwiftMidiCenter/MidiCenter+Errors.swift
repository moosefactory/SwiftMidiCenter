//
//  MidiCenter+Errors.swift
//  MidiCenter
//
//  Created by Tristan Leblanc on 01/01/2021.
//

import Foundation

public extension SwiftMidiCenter {

    enum Errors: String, Error {
        /// Client must have been deallocated
        case clientNotSet
        /// Client not found in CoreMidi
        case clientRefNotSet

        case inputPortWithSameIdentifierAlreadyExists
        case inputOutletWithSameIdentifierAlreadyExists
        case inputOutletAlreadyUnplugged
    }

}
