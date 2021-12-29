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

//  MidiOutlet.swift
//  Created by Tristan Leblanc on 27/12/2020.

import Foundation
import CoreMIDI
import SwiftMIDI
import MoofFoundation
import UniColor

/// Encapsulate a CoreMidi object and gives access to properties
public protocol MidiObject {
    var ref: MIDIObjectRef { get }
    //var uniqueID: Int { get }
    //var offline: Bool { get }
}

public extension MIDIObjectRef {
    var name: String { properties.name }
    var manufacturer: String { properties.manufacturer }
    var uid: Int { properties.uniqueID }
    var deviceId: Int { properties.deviceID }
    var uniqueID: Int { properties.uniqueID }
    var connectionId: Int { properties.connectionUniqueID }
    var nameConf: [String:Any] { properties.nameConfiguration }
    var offline: Bool { properties.offline != 0 }
}

public class MidiOutlet: Codable, MidiObject {
    
    /// Unique Identifier
    public private(set) var uuid = UUID()
    
    /// The associated CoreMidi enpoint object
    public var ref: MIDIEndpointRef

    /// The outlet name
    public private(set) var name: String

    /// The outlet name
    public var endPointName: String  { ref.name }

    /// The outlet endpoint uniqueID
    public var uniqueID: Int  { ref.uniqueID }

    /// The enpoint connection uniqueID, if any
    public var connectionID: Int { ref.connectionId }

    /// The outlet name
    public var displayName: String {
        get { return _displayName ?? name }
        set { _displayName = newValue }
    }
    
    private var _displayName: String?
    
        
    /// Is the outlet available or not
    ///
    /// This is used to determine if the device that provides the outlet is online
    public var available: Bool { !ref.offline }

    /// Is this outlet an input or an output. One must choose.
    public var isInput: Bool = true
    
    /// An optional color that can be set to identify outlets in UI
    public var color: UniColor?
    
    // MARK: - Coding Keys
    
    enum CodingKeys: String, CodingKey {
        case uuid
        case name
        case _displayName = "displayName"
        case ref
        case isInput
        case color
    }
    
    /// This empty outlet, plugged on nothing.
    /// It can be used to create unconfigured connections, and is useful in UI to display a 'None' option to the user
    /// when listing outlets
    public static let noInput = MidiOutlet(ref: 0, name: "No Input", isInput: true)
    public static let anyInput = MidiOutlet(ref: 0, name: "Any", isInput: true)
    public static let noOutput = MidiOutlet(ref: 0, name: "No Output", isInput: false)

    // MARK: - Computed Properties
    
    /// The midi entity providing this outlet, if any
    public var entity: MidiEntity? {
        guard let ref = entityRef else {
            return nil
        }
        return MidiDeviceParc.shared.entity(for: ref)
    }
    
    /// The midi entity ref providing this outlet, if any
    public var entityRef: MIDIEntityRef? {
        return try? SwiftMIDI.getEntity(for: ref)
    }
    
    public var isSet: Bool { ref != 0 }
    
    // MARK: - Initialisation
    
    public init(ref: MIDIEndpointRef = 0, name: String? = nil, isInput: Bool) {
        self.ref = ref
        if name == nil {
            let props = ref.properties
            if props.isSet {
                self.name =  "\(props.manufacturer) - \(props.name)"
            } else {
                self.name = isInput ? "Midi In" : "Midi Out"
            }
        } else {
            self.name = name!
        }
        self.isInput = isInput
    }

    // MARK: - Functions
    
    /// Connect the outlet to a port

    func connect(to port: InputPort, connectionIdentifier: String) throws  {
        try port.connect(identifier: connectionIdentifier, outlet: self)
    }
    
    func connections() {
        //err = MIDIObjectGetDataProperty(endpoint, kMIDIPropertyConnectionUniqueID, &connections);
    }
    
}

extension MidiOutlet: Hashable {
    
    public static func == (lhs: MidiOutlet, rhs: MidiOutlet) -> Bool {
        return lhs.uuid == rhs.uuid
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
}

extension MidiOutlet: CustomStringConvertible {

    public var ioString: String {
        isInput ? "Input" : "Output"
    }
    
    public var description: String {
        let avail = available ? "Available" : "Not Available"
        let shortUUID = String(uuid.uuidString.prefix(8))
        return "\r\(ioString) Outlet '\(name)'\r    \(shortUUID)… id: \(uniqueID) - ref:\(ref)\r    display:'\(_displayName ?? "")' - \(avail) - Connection: \(connectionID)"
    }
}
