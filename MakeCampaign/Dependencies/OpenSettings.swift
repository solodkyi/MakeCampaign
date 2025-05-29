//
//  OpenSettings.swift
//  MakeCampaign
//
//  Created by Andrii Solodkyi on 5/9/25.
//

import Dependencies
import UIKit

extension DependencyValues {
  var openSettings: @Sendable () async -> Void {
    get { self[OpenSettingsKey.self] }
    set { self[OpenSettingsKey.self] = newValue }
  }

  private enum OpenSettingsKey: DependencyKey {
    typealias Value = @Sendable () async -> Void

    static let liveValue: @Sendable () async -> Void = {
      await MainActor.run {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
          UIApplication.shared.open(settingsURL)
        }
      }
    }
  }
}
