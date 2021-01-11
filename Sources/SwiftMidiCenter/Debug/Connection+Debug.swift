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
//  Created by Tristan Leblanc on 09/01/2021.

import Foundation
import SwiftMIDI

#if DEBUG

public extension MidiConnection {
    
    func debugLog(filterOutput: MidiPacketsFilter.Output) {
        
        // Log realtime message
        
        if filterOutput.realTimeMessage != .none {
            print("Real Time : \(filterOutput.realTimeMessage) Sequencer Running: \(sequencerRunning)")
        }
        
        // Log Bank Select
        
        if filterOutput.bankSelect.hasAValue {
            var str = "Bank Select : "
            filterOutput.bankSelect.values.enumerated().forEach {
                if $0.element >= 0 {
                    str += "CH\($0.offset) [\($0.element)]"
                }
            }
            print(str)
        }

        // Log program change and real prgram number ( with bank set )
        
        if filterOutput.programChanges.hasAValue {
            var str = "Program Change : "
            filterOutput.programChanges.values.enumerated().forEach {
                if $0.element >= 0 {
                    let realProgram = filterOutput.programNumber(for:$0.offset)
                    var realProgStr = ""
                    if $0.element != realProgram {
                        realProgStr = " (\(realProgram))"
                    }
                    str += "CH\($0.offset) [\($0.element) \(realProgStr)]"
                }
            }
            print(str)
        }
        
        // Log pitch bend
        
        if filterOutput.pitchBend.hasAValue {
            var str = "Pitch Bend : "
            filterOutput.pitchBend.values.enumerated().forEach {
                if $0.element >= 0 {
                    str += "CH\($0.offset) [\(Int(filterOutput.pitchBend(for: $0.offset) * 100))%]"
                }
            }
            print(str)
        }
        
        // Log control values
        
        if filterOutput.controlValues.hasAValue {
            var str = "Controls : "
            filterOutput.controlValues.controlStates.enumerated().forEach {
                if $0.element.hasValue {
                    str += "CH \($0.offset)\r"
                    for control in $0.element.controlValues {
                        let ctrl = ControlNumbers(rawValue: control.0) ?? .invalid
                        str +=  "[\(control.0)] = \(control.1) - \(ctrl.description)\r"
                    }
                }
            }
            print(str)
        }

        // Log note tick
        
        if (ticks % 24 == 0) && sequencerRunning {
            print("Connection Ticks: \(self.ticks) note: \(self.counter) timeStamp: \(filterOutput.timeStamp)")
        }
        
        // log activated channels and time passed in filter ( less than 100µs if everything is ok )
        if filterOutput.activatedChannels > 0 {
            print("Filter Time: \(Int(filterOutput.filteringTime * 1000000))µs")

        var channelsString: String = ""
        var noteRanges = [MidiRange]()
        for i in 0..<16 {
            if filterOutput.activatedChannels & (0x0001 << i) > 0 {
                let nrange = filterOutput.higherAndLowerNotes[i]
                if nrange.isSet {
                    noteRanges += [nrange]
                }
                let chan = String("0\(i)".suffix(2))
                channelsString += "[\(chan)] "
            } else {
                channelsString += "[  ] "
            }
        }
            
        // Log activated note range
            
        let rangesString = (noteRanges.enumerated().map { "CH\($0.offset) : \($0.element)" }).joined(separator: " ")
        print("Channels: \(channelsString)")
            if !noteRanges.isEmpty { print("Notes: \(rangesString)") }
        
        }
    }
}

#endif
