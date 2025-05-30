//
//  DataManager.swift
//  MakeCampaign
//
//  Created by Point Free on 5/13/25.
//

import Foundation
import Dependencies

struct DataManager {
    var load: @Sendable (URL) throws -> Data
    var save: @Sendable (Data, URL) throws -> Void
}

extension DataManager: DependencyKey {
    static let liveValue = Self(
        load: { url in try Data(contentsOf: url) },
        save: { data, url in try data.write(to: url) }
    )
    
    static let previewValue = Self.mock()
    
    static let testValue: Self = .mock(
        initialData: try? JSONEncoder().encode([Campaign.mock1])
    )
    
    static let failToWrite = Self(
        load: { _ in Data() },
        save: { _, _ in
            struct SomeError: Error {}
            throw SomeError()
        }
    )
    
    static let failToLoad: Self = .init(
        load: { _ in
            struct SomeError: Error {}
            throw SomeError()
        },
        save: { _, _ in }
    )
    
    static func mock(initialData: Data? = nil) -> Self {
        let data = LockIsolated(initialData)
        return Self(
            load: { _ in
                guard let data = data.value
                else {
                    struct FileNotFound: Error {}
                    throw FileNotFound()
                }
                return data
            },
            save: { newData, _ in data.setValue(newData) }
        )
    }
}

extension DependencyValues {
    var dataManager: DataManager {
        get { self[DataManager.self] }
        set { self[DataManager.self] = newValue }
    }
}
