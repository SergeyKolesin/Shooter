//
//  MultipeerConnectivityService.swift
//  Shooter
//
//  Created by Sergei Kolesin on 1/9/19.
//  Copyright © 2019 Sergei Kolesin. All rights reserved.
//

import Foundation
import MultipeerConnectivity

protocol MultipeerServiceDelegate: class
{
	func connectedDevicesChanged(manager : MultipeerService, connectedDevices: [String])
	func didReceaveData(manager: MultipeerService, data: Data)
}

class MultipeerService: NSObject
{
	weak var delegate : MultipeerServiceDelegate?
	
	// Service type must be a unique string, at most 15 characters long
	// and can contain only ASCII lowercase letters, numbers and hyphens.
	private let MultipeerServiceType = "example-ar"
	
	private let myPeerId = MCPeerID(displayName: UIDevice.current.name)
	private let serviceAdvertiser: MCNearbyServiceAdvertiser
	private let serviceBrowser: MCNearbyServiceBrowser
	
	lazy var session: MCSession = {
		let session = MCSession(peer: self.myPeerId, securityIdentity: nil, encryptionPreference: .required)
		session.delegate = self
		return session
	}()
	
	override init() {
		self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: MultipeerServiceType)
		self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: MultipeerServiceType)
		super.init()
		
		self.serviceAdvertiser.delegate = self
		self.serviceBrowser.delegate = self
	}
	
	deinit {
		self.serviceAdvertiser.stopAdvertisingPeer()
		self.serviceBrowser.stopBrowsingForPeers()
	}
	
	public func startAdvertisingPeer() {
		self.serviceAdvertiser.startAdvertisingPeer()
	}
	
	public func startBrowsingForPeers() {
		self.serviceBrowser.startBrowsingForPeers()
	}
	
	func send(archivedMapData: Data)
	{
		print("Sending ArchivedMapData to \(session.connectedPeers.count) peers")
		
		if session.connectedPeers.count > 0
		{
			do {
				try self.session.send(archivedMapData, toPeers: session.connectedPeers, with: .reliable)
			}
			catch let error {
				print("Error for sending: \(error)")
			}
		}
	}
	
	func send(colorName: String)
	{
		print("sendColor: \(colorName) to \(session.connectedPeers.count) peers")
		
		if session.connectedPeers.count > 0
		{
			do {
				try self.session.send(colorName.data(using: .utf8)!, toPeers: session.connectedPeers, with: .reliable)
			}
			catch let error {
				print("Error for sending: \(error)")
			}
		}
	}
}

extension MultipeerService: MCNearbyServiceAdvertiserDelegate
{
	func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error)
	{
		print("didNotStartAdvertisingPeer: \(error)")
	}
	
	func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void)
	{
		print("didReceiveInvitationFromPeer \(peerID)")
		invitationHandler(true, self.session)
	}
}

extension MultipeerService: MCNearbyServiceBrowserDelegate
{
	func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
		print("didNotStartBrowsingForPeers: \(error)")
	}
	
	func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?)
	{
		print("foundPeer: \(peerID)")
		print("invitePeer: \(peerID)")
		browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10)
	}
	
	func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
		print("lostPeer: \(peerID)")
	}
}

extension MultipeerService: MCSessionDelegate
{
	func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState)
	{
		print("peer \(peerID) didChangeState: \(state.rawValue)")
		
		self.delegate?.connectedDevicesChanged(manager: self, connectedDevices: session.connectedPeers.map{$0.displayName})
	}
	
	func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID)
	{
		print("didReceiveData: \(data)")
		
		self.delegate?.didReceaveData(manager: self, data: data)
	}
	
	func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
		print("didReceiveStream")
	}
	
	func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
		print("didStartReceivingResourceWithName")
	}
	
	func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
		print("didFinishReceivingResourceWithName")
	}
}
