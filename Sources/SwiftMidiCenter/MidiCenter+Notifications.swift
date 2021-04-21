/*--------------------------------------------------------------------------*/
/*   /\/\/\__/\/\/\        MooseFactory SwiftMidiCenter                     */
/*   \/\/\/..\/\/\/                                                         */
/*        |  |             (c)2021 Tristan Leblanc                          */
/*        (oo)             tristan@moosefactory.eu                          */
/* MooseFactory Software                                                    */
/*--------------------------------------------------------------------------*/
/*
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE. */
/*--------------------------------------------------------------------------*/

//  MidiCenter+Notifications.swift
//  Created by Tristan Leblanc on 31/12/2020.

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
        let type = object.type.swifty
        withBay(for: type) { bay in
            if let outlet = bay.outlet(with: object.ref) {
                //outlet.available = true
            } else {
                let newOutlet = MidiOutlet(ref: object.ref, isInput: type.isSource)
                bay.outlets.append(newOutlet)
            }
        }
    }
    
    /// A midi input is not available anymore
    func didRemove(_ object: SwiftMIDI.Notification.Object) {
        withBay(for: object.type.swifty) { bay in
            //bay.outlet(with: object.ref)?.available = false
        }
    }

    /// The setup changed notification is the last, we use it to commit our changes.
    func commitSetUp() {
        midiBay = changingMidiBay
        deviceConnections.attach(to: midiBay)
        setupCommited?()
    }
}
