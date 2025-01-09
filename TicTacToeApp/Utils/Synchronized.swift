//
//  Synchronized.swift
//  TicTacToe
//
//  Created by Narek Aslanyan on 07.01.25.
//

import Foundation

@propertyWrapper
class Synchronized<T> {
  
  private var value: T
  private let queue = DispatchQueue(label: "synchronized", attributes: .concurrent)

  init(wrappedValue: T) {
    self.value = wrappedValue
  }

  var wrappedValue: T {
    get {
      queue.sync { value }
    }
    set {
      queue.async(flags: .barrier) { self.value = newValue }
    }
  }
  
}
