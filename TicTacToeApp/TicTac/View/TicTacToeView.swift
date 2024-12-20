//
//  TicTacToeView.swift
//  TicTacToe
//
//  Created by Mekhak Ghapantsyan on 12/18/24.
//

import SwiftUI
import RealityKit

struct TicTacToeView: View {
  
  @StateObject var manager = MultipeerManager()
  
  @State var point: CGPoint? = nil
  @State var turn: Turn = .X
  @State var selectedCelles: [String] = []
  @State var selectedPositions: [Positions : Turn] = [:]
  @State var updatedState: GameState? = nil
  @State var isMyTurn: Bool = true
  @State var iswin: Winner? = nil
  @State var content: RealityViewCameraContent? = nil
  
  var body: some View {
    VStack {
      if let iswin {
        HStack {
          Spacer()
          Text(iswin.rawValue)
            .font(.title)
            .foregroundColor(iswin == .win ? .green : iswin == .draw ? .blue : .red)
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
      realityView
      AvailablePeersView(peerManager: manager)
        .frame(height: 200)
        .onChange(of: manager.receivedMessages) { oldValue, newValue in
          guard let state = try? JSONDecoder().decode(GameState.self, from: newValue)  else { return }
          updatedState = state
          self.turn = Turn(rawValue: state.turn) ?? .O
        }
      
    }
  }
}

extension TicTacToeView {
  
  private var realityView: some View {
    RealityView { content in
      self.content = content
      drawBoard(content: content)
      content.camera = .spatialTracking
    } update: { content in
      if iswin == nil {
        draw(content: content)
        DispatchQueue.main.async {
          checkForWinner()
        }
      }
    }
    .onTapGesture( perform: { point in
      if isMyTurn {
        self.point = point
      }
    })
    .edgesIgnoringSafeArea(.all)
  }
  
  private func draw(content: RealityViewCameraContent) {
    if  updatedState != nil {
      drawUpdates(content: content)
      return
    } else if isMyTurn {
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
        plane.position = [Float(j)*0.22, Float(i)*0.22 - 0.5, -1]
        
        
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
    let name = updatedState?.boardState.keys.first
    for entity in content.entities {
      guard let ent = entity.findEntity(named: name ?? "") as? ModelEntity else { continue }
      let meshEnt = MeshResource.generatePlane(width: 0.2, height: 0.2)
      let materialEnt = UnlitMaterial(color: .green)
      ent.components.set(ModelComponent(mesh: meshEnt, materials: [materialEnt]))
      drawXorO(entity: ent)
      DispatchQueue.main.async {
        updatedState = nil
        selectedCelles.append("\(ent.name) \(turn.rawValue)")
        selectedPositions[(Positions(rawValue: ent.name)!)] = turn
        turn = turn.other
        isMyTurn = true
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
      if !selectedCelles.contains(entity.name) {
        DispatchQueue.main.async {
          selectedCelles.append(entity.name)
          turn = turn.other
          selectedPositions[Positions(rawValue: entity.name)!] = turn.other
        }
        let meshEnt = MeshResource.generatePlane(width: 0.2, height: 0.2)
        let materialEnt = UnlitMaterial(color: .green)
        entity.components.set(ModelComponent(mesh: meshEnt, materials: [materialEnt]))
        drawXorO(entity: entity)
        DispatchQueue.main.async {
          let gameState = GameState(turnOwner: "", turn: turn.rawValue, boardState: [entity.name: turn.other.rawValue])
          guard let data = try? JSONEncoder().encode(gameState) else { return }
          try? manager.session.send(data, toPeers: manager.connectedPeers, with: .reliable)
          updatedState = nil
          isMyTurn = false
          self.point = nil
        }
      }
      break
    }
  }
  
  private func checkForWinner() {
    Positions.winingPosition.forEach { positions in
      if selectedPositions.keys.contains(positions[0]) && selectedPositions.keys.contains(positions[1]) && selectedPositions.keys.contains(positions[2]) {
        if selectedPositions[positions[0]] == selectedPositions[positions[1]] && selectedPositions[positions[1]] == selectedPositions[positions[2]] {
          if selectedPositions[positions[0]] == Turn.X {
            iswin = .win
          } else {
            iswin = .lose
          }
        }
      }
    }
    if selectedPositions.count == 9 && iswin == nil {
      iswin = .draw
    }
  }
  
  private func drawXorO(entity: ModelEntity) {
    let xOrO = ModelEntity()
    xOrO.name = "xOrO"
    let turnMesh = MeshResource.generateText(turn.rawValue,extrusionDepth: 0.01,font: .boldSystemFont(ofSize: 0.1),alignment: .center)
    let turnMaterial = UnlitMaterial(color: turn == .X ? .red : .orange)
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
    drawBoard(content: content)
    selectedCelles.removeAll()
    selectedPositions.removeAll()
    iswin = nil
    updatedState = nil
    point = nil
    let key = "restart"
    let data = key.data(using: .utf8)!
    try? manager.session.send(data, toPeers: manager.connectedPeers, with: .reliable)
  }
  
}

#Preview {
  TicTacToeView()
}
