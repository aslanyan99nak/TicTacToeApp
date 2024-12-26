//
//  SkeletonSize.swift
//  TicTacToe
//
//  Created by Mekhak Ghapantsyan on 12/26/24.
//

import Foundation

enum SkeletonSize: Int, CaseIterable, Identifiable {
  
  case x3 = 3
  case x4 = 4
  case x5 = 5
  
  var id: Self { self }
  
}
