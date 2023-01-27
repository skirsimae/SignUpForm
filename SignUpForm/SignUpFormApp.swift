//
//  SignUpFormApp.swift
//  SignUpForm
//
//  Created by Silva Kirsimae on 23/01/2023.
//

import SwiftUI

@main
struct SignUpFormApp: App {
  var body: some Scene {
    WindowGroup {
      NavigationStack {
        SignUpForm()
          .navigationTitle("Sign up")
      }
    }
  }
}
