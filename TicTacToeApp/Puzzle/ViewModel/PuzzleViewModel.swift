//
//  PuzzleViewModel.swift
//  TicTacToe
//
//  Created by Mekhak Ghapantsyan on 12/26/24.
//

import Foundation
import SwiftUI
import PhotosUI
import RealityKit
import Combine

final class PuzzleViewModel: ObservableObject {
  
  @Published var point: CGPoint? = nil
  @Published var selectedEntity: ModelEntity? = nil
  @Published var puzzleItem: PhotosPickerItem?
  @Published var puzzleImage: UIImage?
  @Published var puzzleParts: [UIImage] = []
  @Published var content: RealityViewCameraContent? = nil
  @Published var selectedPieces: [String : String] = [:]
  @Published var skeletonSize: SkeletonSize = .x3
  @Published var puzzleState: String = "Place all pieces!"
  
  private var cancellables = Set<AnyCancellable>()
  
  init() {
    listenPuzzleState()
    listenSkeletonSize()
    listenPuzzleItem()
  }
  
  func adjustImage(uiImage: UIImage, index: Int) {
    guard let selectedEntity = selectedEntity else { return }
    selectedEntity.model?.materials[0] = UnlitMaterial(color: .white)
    selectedEntity.model?.materials[0] = uiImage.unlitMaterial()
    selectedPieces[selectedEntity.name] = String(index)
    print(selectedPieces)
  }
  
  func selectPieceOn(content: RealityViewCameraContent) {
    guard let point = point else {
      return
    }
    let entitiesAtPoint = content.entities(at: point, in: .local)
    for entity in entitiesAtPoint {
      guard let entity = entity as? ModelEntity else { continue }
      DispatchQueue.main.async { [weak self] in
        self?.selectedEntity?.model?.materials[0] = UnlitMaterial(color: .white)
        self?.selectedEntity = entity
        self?.selectedEntity?.model?.materials[0] = UnlitMaterial(color: .red)
      }
    }
    DispatchQueue.main.async { [weak self] in
      self?.point = nil
    }
  }
  
  func drawSkeleton(with skeletonSize: SkeletonSize) {
    var n = 0
    for i in 0..<skeletonSize.rawValue {
      for j in 0..<skeletonSize.rawValue {
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
        entity.name = String(n)
        n += 1
        entity.generateCollisionShapes(recursive: true)
        entity.components.set(InputTargetComponent(allowedInputTypes: .all))
        plane.addChild(entity)
        content?.add(plane)
      }
    }
  }
  
  private func puzzleItemChange() async {
    if let data = try? await puzzleItem?.loadTransferable(type: Data.self),
       let uiImage = UIImage(data: data) {
      DispatchQueue.main.async { [weak self] in
        guard let self else { return }
        puzzleImage = uiImage
        puzzleParts = puzzleImage?.splitImage(into: skeletonSize.rawValue) ?? []
      }
    }
  }
  
  private func listenPuzzleItem() {
    $puzzleItem
      .sink { [weak self] _ in
        Task { [weak self] in
          await self?.puzzleItemChange()
        }
      }
      .store(in: &cancellables)
  }
  
  private func listenSkeletonSize() {
    $skeletonSize
      .sink { [weak self] size in
        guard let self, let content else { return }
        content.entities.removeAll()
        drawSkeleton(with: size)
      }
      .store(in: &cancellables)
  }
  
  private func listenPuzzleState() {
    $selectedPieces
      .sink { [weak self] value in
        guard let self else { return }
        if value.count != skeletonSize.rawValue * skeletonSize.rawValue {
          puzzleState = "Place all pieces!"
        } else if value.contains(where: { $0.key != $0.value }) {
          puzzleState = "Not Correct!"
        } else {
          puzzleState = "Congrats!!!"
          content?.entities.forEach { ent in
            ent.addChild(self.animatedEntity())
          }
        }
      }
      .store(in: &cancellables)
  }
  
  private func animatedEntity() -> Entity {
    let particles = ParticleEmitterComponent.Presets.magic
    let model = Entity()
    model.components.set(particles)
    return model
  }
  
}
