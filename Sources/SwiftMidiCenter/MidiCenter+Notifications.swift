//
//  MidiCenter+Notifications.swift
//  MidiCenter
//
//  Created by Tristan Leblanc on 31/12/2020.
//

import Foundation
import SwiftMIDI

extension SwiftMidiCenter {
    
    /// Capture the midiBay to update when receiving change
    /// - source : Upate the input bay
    /// - destination : Update the output bay
    /// - other: do nothing
    
    private func withBay(for type: SwiftMIDI.ObjectType, _ block: (MidiBay)->Void) {
        switch type {
        case .source:
            block(changingMidiBay.input)
        case .destination:
            block(changingMidiBay.output)
        default:
            break
        }
    }
    
    /// A new midi input is  available
    func didAdd(_ object: SwiftMIDI.Notification.Object) {
        withBay(for: object.type.swifty) { bay in
            if let outlet = bay.outlet(with: object.ref) {
                outlet.available = true
            } else {
                let newOutlet = MidiOutlet(ref: object.ref)
                bay.outlets.append(newOutlet)
            }
        }
    }
    
    /// A midi input is not available anymore
    func didRemove(_ object: SwiftMIDI.Notification.Object) {
        withBay(for: object.type.swifty) { bay in
            bay.outlet(with: object.ref)?.available = false
        }
    }

    /// The setup changed notification is the last, we use it to commit our changes.
    func commitSetUp() {
        midiBay = changingMidiBay
    }
}
