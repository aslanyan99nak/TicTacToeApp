//
//  UIImage+Ext.swift
//  TicTacToe
//
//  Created by Mekhak Ghapantsyan on 12/24/24.
//

import UIKit
import RealityFoundation

extension UIImage {
  
  func splitImageIntoNineParts() -> [UIImage] {
    guard let cgImage = self.cgImage else {
      print("Failed to get CGImage.")
      return []
    }
    
    let width = CGFloat(cgImage.width)
    let height = CGFloat(cgImage.height)
    
    let tileWidth = width / 3
    let tileHeight = height / 3
    
    var images: [UIImage] = []
    
    for row in 0..<3 {
      for column in 0..<3 {
        let x = CGFloat(column) * tileWidth
        let y = CGFloat(row) * tileHeight
        let cropRect = CGRect(x: x, y: y, width: tileWidth, height: tileHeight)
        
        if let croppedCgImage = cgImage.cropping(to: cropRect) {
          let croppedImage = UIImage(cgImage: croppedCgImage)
          images.append(croppedImage)
        } else {
          print("Failed to crop image for row \(row), column \(column).")
        }
      }
    }
    
    return images
  }
  
  func unlitMaterial() -> UnlitMaterial {
    guard let cgImage = self.cgImage,
          let textureResource = try? TextureResource(
            image: cgImage,
            options: .init(semantic: .normal)
          )
    else {
      return UnlitMaterial()
    }
    var material = UnlitMaterial()
    material.color = .init(
      tint: .white.withAlphaComponent(0.999),
      texture: .init(textureResource)
    )
    return material
  }
  
}
