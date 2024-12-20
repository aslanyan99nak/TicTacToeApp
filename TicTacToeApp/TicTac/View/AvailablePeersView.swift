//
//  AvailablePeersView.swift
//  TicTacToe
//
//  Created by Mekhak Ghapantsyan on 12/18/24.
//

import SwiftUI

struct AvailablePeersView: View {
  
  @StateObject var peerManager: MultipeerManager
  
  var body: some View {
    List(peerManager.availablePeers, id: \.self) { peer in
      Button(peer.displayName) {
        peerManager.browser.invitePeer(
          peer, to: peerManager.session, withContext: nil, timeout: 30
        )
      }
    }
    .alert(
      "Received an invite from \($peerManager.invitationSender.wrappedValue?.displayName ?? "Device")!",
      isPresented: $peerManager.didReciveInvite
    ) {
      Button("Accept invite") {
        if peerManager.invitationHandler != nil {
          peerManager.invitationHandler!(true, peerManager.session)
        }
      }
      .background(Color.blue)
      Button("Reject invite") {
        if peerManager.invitationHandler != nil {
          peerManager.invitationHandler!(false, nil)
        }
      }
      .background(Color.blue)
    }
  }
}

#Preview {
  AvailablePeersView(peerManager: MultipeerManager())
}
