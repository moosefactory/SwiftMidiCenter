//
//  Action+NewConnectionInfo.swift
//  SwiftMidiCenter
//
//  Created by Tristan Leblanc on 21/04/2021.
//

import Foundation

import Foundation
import CoreMIDI
import SwiftUI
import Combine
import SwiftMIDI

public class NewConnectionInfo: Identifiable, ObservableObject, Equatable {
    public static func == (lhs: NewConnectionInfo, rhs: NewConnectionInfo) -> Bool {
        return lhs.name == rhs.name
            && lhs.channels == rhs.channels
            && lhs.range == rhs.range
            && lhs.connectionType == rhs.connectionType
    }
    
    public var name: String = "main"
    public var connectionType: ConnectionType = .packets
    public var range: MidiRange = MidiRange()
    public var channels: MidiChannelMask = .all {
        didSet {
            objectWillChange.send()
        }
    }
    
    public var connectionTypeIndex: Int {
        get {
            return connectionType.rawValue
        }
        set {
            connectionType = ConnectionType(rawValue: newValue) ?? ConnectionType.packets
        }
    }
    
    public init(name: String, portType: ConnectionType = .packets, range: MidiRange = MidiRange()) {
        self.name = name
        self.connectionType = portType
        self.range = range
    }
}
