//
//  MidiCenter+Network.swift
//  MidiCenter
//
//  Created by Tristan Leblanc on 31/12/2020.
//

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
