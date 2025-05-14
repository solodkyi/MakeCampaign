//
//  APIClient.swift
//  MakeCampaign
//
//  Created by Andrii Solodkyi on 5/14/25.
//

import Foundation
import Dependencies

struct JarAPIClient {
    var loadProgress: @Sendable (URL) async throws -> JarDetails
}

// MARK: - DependencyKey

extension JarAPIClient: DependencyKey {
    static let liveValue = JarAPIClient { url in
        let (data, _) = try await URLSession(configuration: .default)
            .data(for: .jarRequest(url: url))
        return try JSONDecoder().decode(JarDetails.self, from: data)
    }
    
    static let previewValue = Self.mock
}

extension URLRequest {
    static func jarRequest(url: URL) throws -> URLRequest {
        guard
            let clientId = url.pathComponents.last,
            let monobankUrl = URL(string: "https://send.monobank.ua/api/handler") else { throw URLError(.badURL) }
        
        let dto = JarRequestBody(clientId: clientId, c: "hello", Pc: UUID().uuidString)
        var request = URLRequest(url: monobankUrl)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = try JSONEncoder().encode(dto)
        return request
    }
}

struct JarRequestBody: Encodable {
    let clientId: String
    let c: String
    let Pc: String
}

extension DependencyValues {
    var jarApiClient: JarAPIClient {
        get { self[JarAPIClient.self] }
        set { self[JarAPIClient.self] = newValue }
    }
}

extension JarAPIClient {
    static let mock = Self { _ in
        return JarDetails.mock
    }
}
