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

//  MidiWire.swift
//  Created by Tristan Leblanc on 31/12/2020.

import Foundation
import CoreMIDI

public struct MidiWireChangeParams<T: MidiWire> {
    var wire: T
    var addedInputOutlets = [MidiOutlet]()
    var removedInputOutlets = [MidiOutlet]()
}

/// MidiWire is a convenient protocol to pass objects of any type with a source and a destination ref
///
/// MidiConnection object conforms to MidiWire protocol

public protocol MidiWire: AnyObject, Hashable, Identifiable {
    var inputOutletsDidChange: ((MidiWireChangeParams<Self>)->Void)? { get set }
    var outputOutletsDidChange: ((MidiWireChangeParams<Self>)->Void)? { get set }
    
    var uuid: UUID { get }
    var sources: [MidiOutlet] { get set }
    var destinations: [MidiOutlet] { get set }
}

// MARK: - Hashable protocol

extension MidiWire {
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.uuid == rhs.uuid
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
}

// MARK: - Access with outlet identifiers

extension MidiWire {
//
//    public var sourceIdentifiers: Set<UUID> {
//        get { Set(sources.map { $0.uuid }) }
//        set {
//            var sources = [MidiOutlet]()
//            var addedSources = [MidiOutlet]()
//            var removedSources = [MidiOutlet]()
//            newValue.forEach { identifier in
//                if let outlet = MidiCenter.shared.input(with: identifier) {
//                    sources.append(outlet)
//                    if !self.sources.contains(outlet) {
//                        addedSources.append(outlet)
//                    }
//                }
//            }
//            self.sources.forEach {
//                if !sources.contains($0) {
//                    removedSources.append($0)
//                }
//            }
//            self.sources = sources
//            inputOutletsDidChange?(MidiWireChangeParams<Self>(wire: self,
//                                                              addedInputOutlets: addedSources,
//                                                              removedInputOutlets: removedSources))
//        }
//    }
//
//    public var destinationIdentifiers: Set<UUID> {
//        get { Set(destinations.map { $0.uuid }) }
//        set {
//            var destinations = [MidiOutlet]()
//            var addedDestinations = [MidiOutlet]()
//            var removedDestinations = [MidiOutlet]()
//
//            newValue.forEach { identifier in
//                if let outlet = MidiCenter.shared.output(with: identifier) {
//                    destinations.append(outlet)
//                    if !self.destinations.contains(outlet) {
//                        addedDestinations.append(outlet)
//                    }
//                }
//            }
//            self.destinations.forEach {
//                if !destinations.contains($0) {
//                    removedDestinations.append($0)
//                }
//            }
//
//            self.destinations = destinations
//            outputOutletsDidChange?(MidiWireChangeParams<Self>(wire: self,
//                                                               addedInputOutlets: addedDestinations,
//                                                               removedInputOutlets: removedDestinations))
//        }
//    }
//
//
    public var sourceUniqueIDs: Set<Int> {
        get { Set(sources.map { $0.uniqueID }) }
        set {
            var sources = [MidiOutlet]()
            var addedSources = [MidiOutlet]()
            var removedSources = [MidiOutlet]()
            newValue.forEach { uniqueID in
                if let outlet = MidiCenter.shared.input(withUniqueID: uniqueID) {
                    sources.append(outlet)
                    if !self.sources.contains(outlet) {
                        addedSources.append(outlet)
                    }
                }
            }
            self.sources.forEach {
                if !sources.contains($0) {
                    removedSources.append($0)
                }
            }
            self.sources = sources
            inputOutletsDidChange?(MidiWireChangeParams<Self>(wire: self,
                                                              addedInputOutlets: addedSources,
                                                              removedInputOutlets: removedSources))
        }
    }
    
    public var destinationUniqueIDs: Set<Int> {
        get { Set(destinations.map { $0.uniqueID }) }
        set {
            var destinations = [MidiOutlet]()
            var addedDestinations = [MidiOutlet]()
            var removedDestinations = [MidiOutlet]()

            newValue.forEach { id in
                if let outlet = MidiCenter.shared.output(withUniqueID: id) {
                    destinations.append(outlet)
                    if !self.destinations.contains(outlet) {
                        addedDestinations.append(outlet)
                    }
                }
            }
            self.destinations.forEach {
                if !destinations.contains($0) {
                    removedDestinations.append($0)
                }
            }

            self.destinations = destinations
            outputOutletsDidChange?(MidiWireChangeParams<Self>(wire: self,
                                                               addedInputOutlets: addedDestinations,
                                                               removedInputOutlets: removedDestinations))
        }
    }
}
