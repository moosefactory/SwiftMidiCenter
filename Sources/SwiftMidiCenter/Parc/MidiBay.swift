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

//  MidiBay.swift
//  Created by Tristan Leblanc on 28/12/2020.

import Foundation
import CoreMIDI

/// MidiBay
///
/// MidiBay is a patch abstraction to represent and store midi endpoints

final public class MidiBay: ObservableObject, Codable {
    
    @Published public var outlets = [MidiOutlet]()
    
    enum CodingKeys: String, CodingKey {
        case outlets
    }
    
    // MARK: - Initialisation
    
    public init(outlets: [MidiOutlet] = []) {
        self.outlets = outlets
    }
    
    /// Init step from JSON container
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        do {
            outlets = try values.decode([MidiOutlet].self, forKey: .outlets)
        }
        catch {
            print("Can't decode outlets - \(error)")
            throw error
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(outlets, forKey: .outlets)
    }
    
    // MARK: - Access Outlets
    
    public func outlet(for name: String) -> MidiOutlet? {
        return outlets.first { $0.name == name }
    }
    
    public func forEachOutlet(_ closure: (MidiOutlet)->Void) {
        outlets.forEach { closure($0) }
    }
    
    func outlet(with uuid: UUID) -> MidiOutlet? {
        outlets.first(where: {$0.uuid == uuid})
    }

    func outlet(with ref: MIDIObjectRef) -> MidiOutlet? {
        outlets.first(where: {$0.ref == ref})
    }

    public func index(of outlet: MidiOutlet) -> Int? {
        return outlets.firstIndex(of: outlet)
    }

    // MARK: Connect Outlets to Port
    
    public func connectAllOutlets(to port: InputPort) {
        forEachOutlet { outlet in
            do {
                try port.connect(identifier: "cnx", outlet: outlet)
            } catch {
                print(error)
            }
        }
    }
    
    // MARK: - Debug
    
    #if DEBUG
    public static let testIn =
        MidiBay(outlets: [
            MidiOutlet(ref: 1, name: "Midi Input Device 1", isInput: true),
        MidiOutlet(ref: 2, name: "Midi Input Device 2", isInput: true)
        ])
    
    public static let testOut =
        MidiBay(outlets: [
        MidiOutlet(ref: 3, name: "Midi Output Device 1", isInput: false),
        MidiOutlet(ref: 4, name: "Midi Output Device 2", isInput: false)
        ])
    #endif
}

