//
//  MultipeerManager.swift
//  TicTacToe
//
//  Created by Mekhak Ghapantsyan on 12/18/24.
//


import MultipeerConnectivity
import SwiftUI

class MultipeerManager: NSObject, ObservableObject {
  
  private let serviceType = "tictacapp11"
  private let myPeerID = MCPeerID(displayName: UIDevice.current.name)
  var session: MCSession
  var advertiser: MCNearbyServiceAdvertiser
  var browser: MCNearbyServiceBrowser
  
  @Published var connectedPeers: [MCPeerID] = []
  @Published var availablePeers: [MCPeerID] = []
  @Published var receivedMessages: Data = Data()
  
  @Published var didReciveInvite: Bool = false
  @Published var invitationHandler: ((Bool, MCSession?) -> Void)?
  @Published var invitationSender: MCPeerID?
  
  override init() {
    session = MCSession(peer: myPeerID)
    advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: serviceType)
    browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
    
    super.init()
    
    session.delegate = self
    advertiser.delegate = self
    browser.delegate = self
    
    advertiser.startAdvertisingPeer()
    browser.startBrowsingForPeers()
  }
  
  deinit {
    advertiser.stopAdvertisingPeer()
    browser.stopBrowsingForPeers()
  }
  
  
  func sendMessage(_ message: String) {
    guard !session.connectedPeers.isEmpty else { return }
    do {
      let data = Data(message.utf8)
      try session.send(data, toPeers: session.connectedPeers, with: .reliable)
    } catch {
      print("Error sending message: \(error)")
    }
  }
}

extension MultipeerManager: MCSessionDelegate {
  func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
    DispatchQueue.main.async {
      self.connectedPeers = session.connectedPeers
    }
  }
  
  func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
    if let message = String(data: data, encoding: .utf8) {
      DispatchQueue.main.async {
        self.receivedMessages = data
      }
    }
  }
  
  func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
  func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
  func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

extension MultipeerManager: MCNearbyServiceAdvertiserDelegate {
  func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
    DispatchQueue.main.async {
      self.didReciveInvite = true
      self.invitationSender = peerID
      self.invitationHandler = invitationHandler
    }
  }
}

extension MultipeerManager: MCNearbyServiceBrowserDelegate {
  func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
//    browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    DispatchQueue.main.async {
      self.availablePeers.append(peerID)
    }
  }
  
  func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}
}
