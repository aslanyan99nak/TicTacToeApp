//
//  UIImage+Ext.swift
//  TicTacToe
//
//  Created by Mekhak Ghapantsyan on 12/24/24.
//

import UIKit
import RealityFoundation

extension UIImage {
  
  func splitImage(into number: Int) -> [UIImage] {
    guard let normalizedImage = self.normalized(),
          let cgImage = normalizedImage.cgImage else {
      print("Failed to get CGImage.")
      return []
    }
    
    let width = CGFloat(cgImage.width)
    let height = CGFloat(cgImage.height)
    
    let tileWidth = width / CGFloat(number)
    let tileHeight = height / CGFloat(number)
    
    var images: [UIImage] = []
    
    for row in 0..<number {
      for column in 0..<number {
        let x = CGFloat(column) * tileWidth
        let y = CGFloat(number - row - 1) * tileHeight
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

extension UIImage {
  
  func normalized() -> UIImage? {
    if imageOrientation == .up {
      return self
    }
    UIGraphicsBeginImageContextWithOptions(size, false, scale)
    draw(in: CGRect(origin: .zero, size: size))
    let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return normalizedImage
  }
  
}
