//
//  MidiConnection.swift
//  MidiCenter
//
//  Created by Tristan Leblanc on 31/12/2020.
//

import Foundation


public final class MidiConnection: MidiWire, Codable, ObservableObject {
    
    public struct ChangeParams {
        var connection: MidiConnection
        var addedInputOutlets = [MidiOutlet]()
        var removedInputOutlets = [MidiOutlet]()
        var changedOutlets = [MidiOutlet]()
    }
    
    public private(set) var port: InputPort?
    
    public var inputOutletsDidChange: ((MidiWireChangeParams<MidiConnection>) -> Void)?
    public var outputOutletsDidChange: ((MidiWireChangeParams<MidiConnection>) -> Void)?
    
    public private(set) var uuid = UUID()

    @Published public var sources: [MidiOutlet]
    @Published public var destinations: [MidiOutlet]
    
    /// Is the connection enabled
    @Published public var enabled: Bool = true {
        didSet {
            print("enabled: \(enabled)")
        }
    }

    @Published public var midiThru: Bool = true

    public var name: String { return uuid.uuidString }
    
    
    enum CodingKeys: String, CodingKey {
        case uuid
        case sources
        case destinations
        case portIdentifier
    }
    
    // MARK: - Initialisation
    
    public init(port: InputPort? = nil, sources: [MidiOutlet] = [], destinations: [MidiOutlet] = []) {
        self.sources = sources
        self.destinations = destinations
        self.port = port
    }
    
    // MARK: - Coding/Decoding
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        uuid =  (try? values.decode(UUID.self, forKey: .sources)) ?? UUID()
        sources = (try? values.decode([MidiOutlet].self, forKey: .sources)) ?? []
        destinations = (try? values.decode([MidiOutlet].self, forKey: .destinations)) ?? []
        let portIdentifier = (try? values.decode(String.self, forKey: .portIdentifier)) ?? ""
        self.port = MidiCenter.shared.client.inputPorts.first(where: { $0.identifier == portIdentifier } )!
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(sources, forKey: .sources)
        try container.encode(destinations, forKey: .destinations)
        try container.encode((port?.identifier ?? ""), forKey: .portIdentifier)
    }

}


#if DEBUG

public extension MidiConnection {
    static let test = MidiConnection(port: InputPort.test, sources: [MidiOutlet(ref: 0, name: "in1"), MidiOutlet(ref: 0, name: "in2")],
                                     destinations: [MidiOutlet(ref: 0, name: "out1"), MidiOutlet(ref: 0, name: "out2")])
}

#endif
