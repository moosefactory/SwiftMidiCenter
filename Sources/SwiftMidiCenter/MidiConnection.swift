//
//  MidiConnection.swift
//  MidiCenter
//
//  Created by Tristan Leblanc on 31/12/2020.
//

import Foundation
import CoreMIDI
import SwiftMIDI


public final class MidiConnection: MidiWire, Codable, ObservableObject {
    
    public struct ChangeParams {
        var connection: MidiConnection
        var addedInputOutlets = [MidiOutlet]()
        var removedInputOutlets = [MidiOutlet]()
        var changedOutlets = [MidiOutlet]()
    }
    
    /// The unique identifier
    public private(set) var uuid = UUID()
    /// The midi input port that will provide the events
    public private(set) var inputPort: InputPort?
    /// The midi output port that will receive the events
    public private(set) var outputPort: OutputPort?
    
    /// The closure to call when input outlets are changed
    public var inputOutletsDidChange: ((MidiWireChangeParams<MidiConnection>) -> Void)?
    /// The closure to call when output outlets are changed
    public var outputOutletsDidChange: ((MidiWireChangeParams<MidiConnection>) -> Void)?
    
    /// The connected input outlet
    @Published public var sources: [MidiOutlet]
    /// The connected output outlet
    @Published public var destinations: [MidiOutlet]
    
    // MARK: - Input Transform
    
    @Published public var filter: MidiPacketsFilter?
        
    @Published public var channelsTranspose = MidiChannelsTranspose()
    
    /// The output channel mask. Input channel is forwarded to all channel in the output mask
    @Published public var channelMatrix: MidiChannelMatrix = MidiChannelMatrix()
    
    // MARK: - Multiplexing
    
    /// Transpose matrix
    @Published public var transposeMatrix = MidiChannelsTransposeMatrix()
    
    /// Is the connection enabled
    @Published public var enabled: Bool = true {
        didSet {
            print("enabled: \(enabled)")
        }
    }
    
    @Published public var midiThru: Bool = true
    
    public var name: String
    
    enum CodingKeys: String, CodingKey {
        case uuid
        case name
        case filter
        case sources
        case destinations
        case portIdentifier
    }
    
    // MARK: - Initialisation
    
    public init(name: String = "Connection", filter: MidiPacketsFilter? = nil,
                inputPort: InputPort? = nil, outputPort: OutputPort? = nil,
                sources: [MidiOutlet] = [], destinations: [MidiOutlet] = []) {
        self.filter = filter
        self.name = name
        self.sources = sources
        self.destinations = destinations
        self.inputPort = inputPort
        self.outputPort = outputPort
    }
    
    // MARK: - Coding/Decoding
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let uuid =  (try? values.decode(UUID.self, forKey: .sources)) ?? UUID()
        self.uuid = uuid
        name =  (try? values.decode(String.self, forKey: .name)) ?? uuid.uuidString
        filter =  (try? values.decode(MidiPacketsFilter.self, forKey: .filter))
        sources = (try? values.decode([MidiOutlet].self, forKey: .sources)) ?? []
        destinations = (try? values.decode([MidiOutlet].self, forKey: .destinations)) ?? []
        let portIdentifier = (try? values.decode(String.self, forKey: .portIdentifier)) ?? ""
        self.inputPort = MidiCenter.shared.client.inputPort
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(sources, forKey: .sources)
        try container.encode(destinations, forKey: .destinations)
        try container.encode((inputPort?.identifier ?? ""), forKey: .portIdentifier)
    }
    
    // Transfer packets to destinations, applying filter
    public func transfer(packetList: UnsafePointer<MIDIPacketList>) {
        destinations.forEach { destination in
            
            guard var packets: MIDIPacketList = (filter != nil
                    ? filter!.filter(packetList: packetList)
                                                    : packetList.pointee) else { return }
            
            do {
                try SwiftMIDI.send(port: outputPort!.ref, destination: destination.ref, packetListPointer: &packets)
            }
            catch {
                print("MidiConnection Error : \(error)")
            }
            
        }
    }
    
    // Send MidiEvents ( No filtering )
    public func send(events: [MidiEvent]) throws {
        guard var packets = events.asPacketList else { return }
        destinations.forEach { destination in
            do {
                try SwiftMIDI.send(port: outputPort!.ref, destination: destination.ref, packetListPointer: &packets)
            }
            catch {
                print("MidiConnection Error : \(error)")
            }
        }
    }
    
}


#if DEBUG

public extension MidiConnection {
    static let test = MidiConnection(name: "Test Connection", inputPort: InputPort.test,
                                     sources: [MidiOutlet(ref: 0, name: "in1"), MidiOutlet(ref: 0, name: "in2")],
                                     destinations: [MidiOutlet(ref: 0, name: "out1"), MidiOutlet(ref: 0, name: "out2")])
}

#endif
