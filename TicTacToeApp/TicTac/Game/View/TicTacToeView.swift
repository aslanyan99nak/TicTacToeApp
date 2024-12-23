//
//  TicTacToeView.swift
//  TicTacToe
//
//  Created by Mekhak Ghapantsyan on 12/18/24.
//

import SwiftUI
import RealityKit

struct TicTacToeView: View {
  
  @StateObject var manager: MultipeerManager
  @StateObject var viewModel = TictacToeViewModel()
  
  @State var point: CGPoint? = nil
  @State var content: RealityViewCameraContent? = nil
  
  var body: some View {
    VStack {
      winnerInfo
      realityView
      peers
        .onChange(of: manager.receivedMessages) { _, newValue in
          viewModel.handleUpdate(newValue: newValue)
        }
    }
  }
  
}

extension TicTacToeView {
  
  @ViewBuilder
  private var winnerInfo: some View {
    if let iswin = viewModel.iswin {
      HStack {
        Spacer()
        Text(iswin.rawValue)
          .font(.title)
          .foregroundColor(iswin == .win ? .green : viewModel.iswin == .draw ? .blue : .red)
          .padding()
        Spacer()
        Button("Restart") {
          restart()
        }
        .padding(4)
        .background(Color.yellow)
        .padding(6)
      }
    }
  }
  
  private var peers: some View {
    AvailablePeersView(peerManager: manager)
      .frame(height: 200)
  }
  
  private var realityView: some View {
    RealityView { content in
      self.content = content
      drawBoard(content: content)
      content.camera = .spatialTracking
    } update: { content in
      if viewModel.iswin == nil {
        draw(content: content)
        DispatchQueue.main.async {
          viewModel.checkForWinner()
        }
      }
    }
    .onTapGesture( perform: { point in
      if viewModel.isMyTurn && manager.connectedPeers.count > 0 {
        self.point = point
      }
    })
    .edgesIgnoringSafeArea(.all)
  }
  
  private func draw(content: RealityViewCameraContent) {
    if  viewModel.updatedState != nil {
      drawUpdates(content: content)
      return
    } else if viewModel.isMyTurn {
      drawGestures(content: content)
      return
    }
  }
  
  private func drawBoard(content: RealityViewCameraContent) {
    for i in 0..<3 {
      for j in 0..<3 {
        let plane = ModelEntity()
        let mesh = MeshResource.generatePlane(width: 0.21, height: 0.21)
        let material = UnlitMaterial(color: .blue)
        plane.components.set(ModelComponent(mesh: mesh, materials: [material]))
        plane.position = [Float(j)*0.22 - 0.25, Float(i)*0.22, -1]
        
        
        let entity = ModelEntity()
        let meshEnt = MeshResource.generatePlane(width: 0.2, height: 0.2)
        let materialEnt = UnlitMaterial(color: .white)
        
        entity.components.set(ModelComponent(mesh: meshEnt, materials: [materialEnt]))
        entity.position = [0,0,0.01]
        entity.name = "\(i)\(j)"
        entity.generateCollisionShapes(recursive: true)
        entity.components.set(InputTargetComponent(allowedInputTypes: .all))
        plane.addChild(entity)
        content.add(plane)
      }
    }
  }
  
  private func drawUpdates(content: RealityViewCameraContent) {
    let name = viewModel.updatedState?.boardState.keys.first
    for entity in content.entities {
      guard let ent = entity.findEntity(named: name ?? "") as? ModelEntity else { continue }
      let meshEnt = MeshResource.generatePlane(width: 0.2, height: 0.2)
      let materialEnt = UnlitMaterial(color: .green)
      ent.components.set(ModelComponent(mesh: meshEnt, materials: [materialEnt]))
      drawXorO(entity: ent)
      DispatchQueue.main.async {
        viewModel.update(ent: ent)
      }
      break
    }
  }
  
  private func drawGestures(content: RealityViewCameraContent) {
    guard let point else { return }
    let entities = content.entities(at: point, in: .local)
    for entity in entities {
      guard let entity = entity as? ModelEntity else {
        continue
      }
      if !viewModel.selectedCelles.contains(entity.name) {
        DispatchQueue.main.async {
          viewModel.selectedCelles.append(entity.name)
          viewModel.turn = viewModel.turn.other
          viewModel.selectedPositions[Positions(rawValue: entity.name)!] = viewModel.turn.other
        }
        let meshEnt = MeshResource.generatePlane(width: 0.2, height: 0.2)
        let materialEnt = UnlitMaterial(color: .green)
        entity.components.set(ModelComponent(mesh: meshEnt, materials: [materialEnt]))
        drawXorO(entity: entity)
        DispatchQueue.main.async {
          guard let data =  viewModel.prepareUpdateData(entity: entity) else { return }
          try? manager.session.send(data, toPeers: manager.connectedPeers, with: .reliable)
          self.point = nil
        }
      }
      break
    }
  }
  
  private func drawXorO(entity: ModelEntity) {
    let xOrO = ModelEntity()
    xOrO.name = "xOrO"
    let turnMesh = MeshResource.generateText(viewModel.turn.rawValue,extrusionDepth: 0.01,font: .boldSystemFont(ofSize: 0.1),alignment: .center)
    let turnMaterial = UnlitMaterial(color: viewModel.turn == .X ? .red : .orange)
    xOrO.components.set(ModelComponent(mesh: turnMesh, materials: [turnMaterial]))
    xOrO.setScale([0.5,0.5,0.5], relativeTo: entity)
    xOrO.position = [0,0,0.05]
    if entity.findEntity(named: "xOrO") == nil {
      entity.addChild(xOrO)
    }
  }
  
  private func restart() {
    guard let content = self.content else { return }
    content.entities.removeAll()
    point = nil
    viewModel.reset()
    drawBoard(content: content)
  }
  
}

#Preview {
  TicTacToeView(manager: MultipeerManager(userName: "Test"))
}
