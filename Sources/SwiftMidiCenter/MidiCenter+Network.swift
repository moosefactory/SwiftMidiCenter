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

//  MidiCenter+Network.swift
//  Created by Tristan Leblanc on 31/12/2020.

import Foundation
import CoreMIDI

class MIDIServicesBrowser: NSObject, NetServiceBrowserDelegate {
    private var browser: NetServiceBrowser
    
    override init() {
        browser = NetServiceBrowser()
        super.init()
        browser.delegate = self;
        browser.searchForServices(ofType: MIDINetworkBonjourServiceType, inDomain: "")
    }
    
    func netServiceBrowserWillSearch(_ browser: NetServiceBrowser) {
        print("[NetService] Will search")
    }
    
    func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        print("[NetService] Did stop search")
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        print("[NetService] Did not search")
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didFindDomain domainString: String, moreComing: Bool) {
        print("[NetService] Did find domain")
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        print("[NetService] Did find service")
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didRemoveDomain domainString: String, moreComing: Bool) {
        print("[NetService] Did remove domain")
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        print("[NetService] Did remove service")
    }
}

class MIDINetworkManager {

    let session = MIDINetworkSession.default()

    let servicesBrowser = MIDIServicesBrowser()

    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(contactsDidChange),
                                               name:Notification.Name.MIDINetworkContactsDidChange, object: nil)
        session.connectionPolicy = .anyone
        session.isEnabled = true
        print("MIDI Network session enabled \(session.isEnabled)")

    }

    @objc func contactsDidChange(notification: Notification) {
        let contacts = session.contacts()
        print(contacts)
    }
}

extension SwiftMidiCenter  {

}
