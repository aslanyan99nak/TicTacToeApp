//
//  PuzzleView.swift
//  TicTacToe
//
//  Created by Mekhak Ghapantsyan on 12/24/24.
//

import SwiftUI
import RealityKit
import PhotosUI

struct PuzzleView: View {
  
  @State var point: CGPoint? = nil
  @State var selectedEntity: ModelEntity? = nil
  @State private var puzzleItem: PhotosPickerItem?
  @State private var puzzleImage: UIImage?
  @State private var puzzleParts: [UIImage] = []
  
  var body: some View {
    VStack {
      realityView
      puzzle
        .frame(maxHeight: 150)
    }
  }
  
}

extension  PuzzleView {
  
  @ViewBuilder
  private var puzzle: some View {
    if puzzleParts.isEmpty {
      PhotosPicker(selection: $puzzleItem, matching: .images) {
        Text("Select Puzzle")
      }
      .onChange(of: puzzleItem) {
        Task {
          if let data = try? await puzzleItem?.loadTransferable(type: Data.self),
             let uiImage = UIImage(data: data) {
            puzzleImage = uiImage
            puzzleParts = puzzleImage?.splitImageIntoNineParts() ?? []
          } else {
            print("Failed")
          }
        }
      }
    } else {
      puzzlePartView
    }
    
  }
  
  private var puzzlePartView: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 16) {
        ForEach(0..<puzzleParts.count, id: \.self) { index in
          Button {
            adjustImage(uiImage: puzzleParts[index])
          } label: {
            Image(uiImage: puzzleParts[index])
              .resizable()
              .scaledToFit()
              .frame(height: 100)
              .padding(8)
              .background(
                RoundedRectangle(cornerRadius: 12)
                  .fill(Color.white.opacity(0.9))
                  .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
              )
              .overlay(
                RoundedRectangle(cornerRadius: 12)
                  .stroke(Color.blue, lineWidth: 2)
              )
          }
          .buttonStyle(PlainButtonStyle())
        }
      }
      .padding(.horizontal)
      .padding(.vertical, 10)
    }
    .background(
      LinearGradient(
        gradient: Gradient(colors: [Color.cyan.opacity(0.4), Color.purple.opacity(0.6)]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .cornerRadius(16)
      .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
    )
    .padding(.horizontal, 10)
    
  }
  
  private var realityView: some View {
    RealityView { content in
      drawSkeleton(content: content)
      content.camera = .spatialTracking
    } update: { content in
      selectPieceOn(content: content)
    }
    .onTapGesture { point in
      self.point = point
    }
  }
  
  private func drawSkeleton(content: RealityViewCameraContent) {
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
  
  private func selectPieceOn(content: RealityViewCameraContent) {
    guard  let point  else {
      print("No Point")
      return
    }
    let entitiesAtPoint = content.entities(at: point, in: .local)
    for entity in entitiesAtPoint {
      guard let entity = entity as? ModelEntity else { continue }
      DispatchQueue.main.async {
        selectedEntity?.model?.materials[0] = UnlitMaterial(color: .white)
        selectedEntity = entity
        selectedEntity?.model?.materials[0] = UnlitMaterial(color: .red)
      }
    }
  }
  
  private func adjustImage(uiImage: UIImage) {
    selectedEntity?.model?.materials[0] = uiImage.unlitMaterial()
  }
  
}

#Preview {
  PuzzleView()
}
