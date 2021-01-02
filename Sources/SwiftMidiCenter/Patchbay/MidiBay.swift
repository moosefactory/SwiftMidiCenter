//
//  MidiBay.swift
//  MidiCenter
//
//  Created by Tristan Leblanc on 28/12/2020.
//

import Foundation
import CoreMIDI

public class MidiBay: ObservableObject {
    @Published public var outlets = [MidiOutlet]()
    
    public init(outlets: [MidiOutlet] = []) {
        self.outlets = outlets
    }
    
    public func outlet(for name: String) -> MidiOutlet? {
        return outlets.first { $0.name == name }
    }
    
    public func forEachOutlet(_ closure: (MidiOutlet)->Void) {
        outlets.forEach { closure($0) }
    }
    
    public func connectAllOutlets(to port: InputPort) {
        forEachOutlet { outlet in
            do {
                try port.connect(identifier: "cnx", outlet: outlet)
            } catch {
                print(error)
            }
        }
    }

    func outlet(with identifier: String) -> MidiOutlet? {
        outlets.first(where: {$0.uuid.uuidString == identifier})
    }

    func outlet(with ref: MIDIObjectRef) -> MidiOutlet? {
        outlets.first(where: {$0.ref == ref})
    }

    #if DEBUG
    public static let testIn =
        MidiBay(outlets: [
        MidiOutlet(ref: 1, name: "Midi Input Device 1"),
        MidiOutlet(ref: 2, name: "Midi Input Device 2")
        ])
    
    public static let testOut =
        MidiBay(outlets: [
        MidiOutlet(ref: 3, name: "Midi Output Device 1"),
        MidiOutlet(ref: 4, name: "Midi Output Device 2")
        ])
    #endif
}

