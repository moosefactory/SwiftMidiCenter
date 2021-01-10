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

//  MidiConnection.swift
//  Created by Tristan Leblanc on 31/12/2020.

import Foundation
import CoreMIDI
import SwiftMIDI

/// MidiConnection
///
/// An object to represent and store a connection between midi end points.
///
/// Connection has a midi filter that makes a lot of work to sort midi packets and extract usefull information

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
    
    @Published public var filter: MidiFilterSettings
    
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
    
    public var ticks: Int = 0
    public var counter: Int { return ticks / 24 }
    
    // Last realtime message, excluding clock
    public var lastRealTimeMessage: RealTimeMessageType = .none {
        didSet {
            switch lastRealTimeMessage {
            case .start:
                ticks = 0
                sequencerRunning = true
            case .continue:
                sequencerRunning = true
            case .stop:
                sequencerRunning = false
            case .systemReset:
                sequencerRunning = false
                ticks = 0
            default:
                break
            }
        }
    }
    
    public var sequencerRunning: Bool = false
    
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
    
    public init(name: String = "Connection", filter: MidiFilterSettings = MidiFilterSettings(),
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
        filter =  (try? values.decode(MidiFilterSettings.self, forKey: .filter)) ?? MidiFilterSettings()
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
        let f = MidiPacketsFilter(settings: filter)
        destinations.forEach { destination in
            
            var packets: MIDIPacketList?
            
            if f.settings.willPassThrough {
                packets = packetList.pointee
            } else {
                let filterOutput = f.filter(packetList: packetList)
                packets = filterOutput.packets
                
                // Add ticks to connection counter
                self.ticks += Int(filterOutput.ticks)
                
                // Save last real time message ( excepted clock - Start, Continue, Stop)
                lastRealTimeMessage = filterOutput.realTimeMessage
            
                // Debug
                #if DEBUG
                DispatchQueue.main.async {
                    self.debugLog(filterOutput: filterOutput)
                }
                #endif
            }
            
            guard var packets_ = packets else { return }
            
            do {
                try SwiftMIDI.send(port: outputPort!.ref, destination: destination.ref, packetListPointer: &packets_)
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
