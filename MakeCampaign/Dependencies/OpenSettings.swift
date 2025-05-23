//
//  OpenSettings.swift
//  MakeCampaign
//
//  Created by Andrii Solodkyi on 5/9/25.
//

import Dependencies
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

extension DependencyValues {
  var openSettings: @Sendable () async -> Void {
    get { self[OpenSettingsKey.self] }
    set { self[OpenSettingsKey.self] = newValue }
  }

  private enum OpenSettingsKey: DependencyKey {
    typealias Value = @Sendable () async -> Void

    static let liveValue: @Sendable () async -> Void = {
      await MainActor.run {
        #if canImport(UIKit)
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
          UIApplication.shared.open(settingsURL)
        }
        #elseif canImport(AppKit)
        // On macOS, open System Preferences/Settings
        if let settingsURL = URL(string: "x-apple.systempreferences:") {
          NSWorkspace.shared.open(settingsURL)
        }
        #endif
      }
    }
  }
}
