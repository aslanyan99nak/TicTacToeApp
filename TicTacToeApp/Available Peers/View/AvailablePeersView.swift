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
    ZStack {
      if peerManager.availablePeers.isEmpty {
        emptyState
      } else {
        if peerManager.connectedPeers.isEmpty {
          peersList
        } else {
          connectedState
        }
      }
    }
    .gradientBackground()
    .alert(
      "Received an invite from \($peerManager.invitationSender.wrappedValue?.displayName ?? "Device")!",
      isPresented: $peerManager.didReciveInvite
    ) {
      Button("Accept") {
        peerManager.invitationHandler?(true, peerManager.session)
      }
      .foregroundColor(.white)
      .padding()
      .background(Color.green)
      .cornerRadius(10)
      
      Button("Reject") {
        peerManager.invitationHandler?(false, nil)
      }
      .foregroundColor(.white)
      .padding()
      .background(Color.red)
      .cornerRadius(10)
    }
  }
  
}

extension AvailablePeersView {
  
  private var peersList: some View {
    List(peerManager.availablePeers, id: \.self) { peer in
      HStack {
        Image(systemName: "person.fill")
          .foregroundColor(.blue)
          .padding(.trailing, 8)
        Text(peer.displayName)
          .font(.headline)
          .foregroundColor(.primary)
        Spacer()
        Button(action: {
          peerManager.browser.invitePeer(
            peer, to: peerManager.session, withContext: nil, timeout: 30
          )
        }) {
          Image(systemName: "paperplane.fill")
            .foregroundColor(.green)
            .padding()
        }
        .buttonStyle(PlainButtonStyle())
      }
      .padding(.vertical, 5)
    }
  }
  
  private var emptyState: some View {
    VStack {
      Image(systemName: "wave.3.left.circle.fill")
        .resizable()
        .scaledToFit()
        .frame(width: 100, height: 100)
        .foregroundColor(.blue.opacity(0.7))
        .padding()
      
      Text("No peers available")
        .font(.title2)
        .fontWeight(.semibold)
        .foregroundColor(.secondary)
    }
  }
  
  private var connectedState: some View {
    VStack {
      Image(systemName: "checkmark.circle.fill")
        .resizable()
        .scaledToFit()
        .frame(width: 100, height: 100)
        .foregroundColor(.green)
        .padding()
      
      Text("Successfully connected to \(peerManager.connectedPeers.first?.displayName ?? "a device")")
        .font(.title2)
        .fontWeight(.semibold)
        .foregroundColor(.primary)
        .multilineTextAlignment(.center)
        .padding()
    }
  }
  
}

#Preview {
  AvailablePeersView(peerManager: MultipeerManager(userName: "Test"))
}
