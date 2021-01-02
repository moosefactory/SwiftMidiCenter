//
//  MidiWire.swift
//  MidiCenter
//
//  Created by Tristan Leblanc on 31/12/2020.
//

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
    
    public var sourceIdentifiers: Set<String> {
        get { Set(sources.map { $0.uuid.uuidString }) }
        set {
            var sources = [MidiOutlet]()
            var addedSources = [MidiOutlet]()
            var removedSources = [MidiOutlet]()
            newValue.forEach { identifier in
                if let outlet = MidiCenter.shared.input(with: identifier) {
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
    
    public var destinationIdentifiers: Set<String> {
        get { Set(destinations.map { $0.uuid.uuidString }) }
        set {
            var destinations = [MidiOutlet]()
            var addedDestinations = [MidiOutlet]()
            var removedDestinations = [MidiOutlet]()

            newValue.forEach { identifier in
                if let outlet = MidiCenter.shared.output(with: identifier) {
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
