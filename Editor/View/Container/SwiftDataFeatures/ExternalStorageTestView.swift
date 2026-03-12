//
//  ExternalStorageTestView.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import SwiftData
import SwiftUI

struct ExternalStorageTestView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.schema) private var schema
    @State private var testModelID: String = "attribute-options-test"
    @State private var date: Date = .now
    @State private var creationTest: Test = .init()
    @State private var encodingTest: Test = .init()
    @State private var decodingTest: Test = .init()
    @State private var expectedPayload: SamplePayload?
    @State private var record: DatabaseRecord?
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 8) {
                    Group {
                        TestChecklistRow(
                            title: "Create or Fetch `attribute`",
                            description: creationTest.description,
                            status: creationTest.status
                        )
                        TestChecklistRow(
                            title: "Encode to `externalData`",
                            description: encodingTest.description,
                            status: encodingTest.status
                        )
                        TestChecklistRow(
                            title: "Decode from `externalData`",
                            description: decodingTest.description,
                            status: decodingTest.status
                        )
                    }
                }
                GroupBox {
                    switch record {
                    case let record?:
                        DatabaseRecordView(snapshot: record.snapshot)
                    case nil:
                        ContentUnavailableView("None", systemImage: "questionmark.circle")
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                HStack {
                    Button {
                        runAllTests()
                    } label: {
                        Label("Run Tests", systemImage: "play.circle.fill")
                            .font(.headline)
                    }
                    Button("Reset") {
                        self.creationTest = .init()
                        self.encodingTest = .init()
                        self.decodingTest = .init()
                        self.record = nil
                    }
                    .disabled(record == nil)
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)
                .padding(.vertical)
            }
            .safeAreaPadding()
            .navigationTitle("External Storage Test")
            .task(id: date) {
                var descriptor = FetchDescriptor<SchemaAttributeOptionModel>(predicate: #Predicate {
                    $0.id == testModelID
                })
                descriptor.fetchLimit = 1
                if let model = try? modelContext.fetch(descriptor).first,
                   let entity = self.schema.entity(for: SchemaAttributeOptionModel.self) {
                    self.record = .init(model: model, entity: entity)
                }
            }
        }
    }
    
    private func runAllTests() {
        defer { self.date = .now }
        self.creationTest.status = .running
        self.encodingTest.status = .idle
        self.decodingTest.status = .idle
        self.creationTest.description = "Locating or creating model with `id`: `attribute`"
        self.encodingTest.description = "Waiting for creation step."
        self.decodingTest.description = "Waiting for encoding step."
        do {
            let (model, result) = try fetchOrCreateAttribute()
            switch result {
            case .created:
                self.creationTest.description = "Created new model with `id`: `\(model.id)`"
            case .existing:
                self.creationTest.description = "Found existing model with `id`: `\(model.id)`"
            }
            self.creationTest.status = .success
            self.encodingTest.status = .running
            self.encodingTest.description = "Encoding sample payload into `externalData`."
            let payload = SamplePayload(
                text: "Hello external storage",
                timestamp: Date()
            )
            try encodePayload(payload, into: model)
            self.expectedPayload = payload
            self.encodingTest.status = .success
            self.encodingTest.description = "Stored encoded payload in `externalData`."
            self.decodingTest.status = .running
            self.decodingTest.description = "Fetching model and decoding payload from `externalData`."
            let decoded = try decodePayload(for: model.id)
            if let expectedPayload, decoded == expectedPayload {
                self.decodingTest.status = .success
                self.decodingTest.description = "Decoded payload matches encoded payload."
            } else {
                self.decodingTest.status = .success
                self.decodingTest.description = "Decoded payload successfully."
            }
        } catch {
            handleError(error)
        }
    }
    
    private func handleError(_ error: any Swift.Error) {
        if creationTest.status == .running {
            self.creationTest.status = .failure
            self.creationTest.description = "Error: \(error.localizedDescription)"
            self.encodingTest.status = .failure
            self.decodingTest.status = .failure
            self.encodingTest.description = "Skipped because creation failed."
            self.decodingTest.description = "Skipped because creation failed."
        } else if encodingTest.status == .running {
            self.encodingTest.status = .failure
            self.encodingTest.description = "Error: \(error.localizedDescription)"
            self.decodingTest.status = .failure
            self.decodingTest.description = "Skipped because encoding failed."
        } else if decodingTest.status == .running {
            self.decodingTest.status = .failure
            self.decodingTest.description = "Error: \(error.localizedDescription)"
        }
    }
    
    private func fetchOrCreateAttribute() throws -> (
        SchemaAttributeOptionModel,
        AttributeFetchResult
    ) {
        let descriptor = FetchDescriptor<SchemaAttributeOptionModel>(
            predicate: #Predicate { $0.id == testModelID }
        )
        let results = try modelContext.fetch(descriptor)
        if let existing = results.first {
            return (existing, .existing)
        } else {
            let model = SchemaAttributeOptionModel(id: testModelID, externalData: nil)
            modelContext.insert(model)
            try modelContext.save()
            return (model, .created)
        }
    }
    
    private func encodePayload(
        _ payload: SamplePayload,
        into model: SchemaAttributeOptionModel
    ) throws {
        let data = try JSONEncoder().encode(payload)
        model.externalData = data
        try modelContext.save()
    }
    
    private func decodePayload(for id: String) throws -> SamplePayload {
        let descriptor = FetchDescriptor<SchemaAttributeOptionModel>(
            predicate: #Predicate { $0.id == id }
        )
        guard let model = try modelContext.fetch(descriptor).first else {
            throw Database.Error.modelNotFound
        }
        guard let data = model.externalData else {
            throw Error.missingData
        }
        do {
            return try JSONDecoder().decode(SamplePayload.self, from: data)
        } catch {
            let details = detailedDecodingFailure(for: error, data: data)
            throw Error.decodingFailed(details)
        }
    }
    
    private func detailedDecodingFailure(for error: any Swift.Error, data: Data) -> String {
        var parts = [String]()
        if let decodingError = error as? DecodingError {
            parts.append(contentsOf: describeDecodingError(decodingError))
        } else {
            parts.append(error.localizedDescription)
        }
        parts.append("Bytes: \(data.count)")
        if let utf8 = String(data: data.prefix(256), encoding: .utf8) {
            parts.append("UTF-8 preview (first 256 bytes):")
            parts.append(utf8)
        } else {
            parts.append("UTF-8 preview: <not valid UTF-8>")
        }
        let hex = data.prefix(64).map { String(format: "%02hhx", $0) }.joined(separator: " ")
        parts.append("Hex preview (first 64 bytes):")
        parts.append(hex)
        return parts.joined(separator: "\n")
    }
    
    private func describeDecodingError(_ error: DecodingError) -> [String] {
        switch error {
        case .dataCorrupted(let context):
            [
                "Decoding failed: `dataCorrupted` \(context.debugDescription)",
                "Path: \(codingPathString(context.codingPath))"
            ]
        case .keyNotFound(let key, let context):
            [
                "Decoding failed: `keyNotFound` '\(key.stringValue)' \(context.debugDescription)",
                "Path: \(codingPathString(context.codingPath))"
            ]
        case .valueNotFound(let type, let context):
            [
                "Decoding failed: `valueNotFound` for \(type) \(context.debugDescription)",
                "Path: \(codingPathString(context.codingPath))"
            ]
        case .typeMismatch(let type, let context):
            [
                "Decoding failed: `typeMismatch` for \(type) \(context.debugDescription)",
                "Path: \(codingPathString(context.codingPath))"
            ]
        @unknown default:
            fatalError()
        }
    }
    
    private func codingPathString(_ path: [CodingKey]) -> String {
        let components = path.map { $0.stringValue }
        if components.isEmpty {
            return "<root>"
        } else {
            return components.joined(separator: ".")
        }
    }
    
    struct Test {
        var status: Status = .idle
        var description: String = "Not run yet."
    }
    
    enum AttributeFetchResult {
        case created
        case existing
    }
    
    struct SamplePayload: Codable, Equatable {
        let text: String
        let timestamp: Date
    }
    
    enum Error: LocalizedError {
        case notFound
        case missingData
        case decodingFailed(String)
        
        var errorDescription: String? {
            switch self {
            case .notFound: "No model with `id` found."
            case .missingData: "`externalData` was nil."
            case .decodingFailed(let details): details
            }
        }
    }
    
    struct TestChecklistRow: View {
        let title: String
        let description: String
        let status: Status
        
        var body: some View {
            HStack(alignment: .top, spacing: 12) {
                status.icon.transition(.scale)
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(LocalizedStringKey(title))
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        status.badge
                    }
                    Text(LocalizedStringKey(description))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}
