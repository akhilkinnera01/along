import AlongCore
import Foundation

public enum LocalMissionStoreError: Error, Equatable, Sendable {
    case pathEscapedStoreDirectory
}

public actor LocalMissionStore: MissionEventStore {
    private let directoryURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(directoryURL: URL) throws {
        self.directoryURL = directoryURL.standardizedFileURL
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()

        try FileManager.default.createDirectory(
            at: self.directoryURL,
            withIntermediateDirectories: true
        )
    }

    public func append(_ event: MissionEvent) async throws {
        var missionEvents = try readEvents(for: event.missionID)
        missionEvents.append(event)
        missionEvents.sort { $0.sequence < $1.sequence }
        try writeEvents(missionEvents, for: event.missionID)
    }

    public func events(for missionID: MissionID) async throws -> [MissionEvent] {
        try readEvents(for: missionID)
    }

    public func allMissionIDs() async throws -> [MissionID] {
        let urls = try FileManager.default.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: nil
        )

        var missionIDs: [MissionID] = []
        for url in urls where url.pathExtension == "jsonl" {
            if let missionID = try readEvents(at: url).first?.missionID {
                missionIDs.append(missionID)
            }
        }

        return missionIDs.sorted { $0.rawValue < $1.rawValue }
    }

    public func deleteMission(_ missionID: MissionID) async throws {
        let url = try missionFileURL(for: missionID)
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }

    public func exportMission(_ missionID: MissionID) async throws -> Data {
        try encoder.encode(readEvents(for: missionID))
    }

    private func readEvents(for missionID: MissionID) throws -> [MissionEvent] {
        try readEvents(at: missionFileURL(for: missionID))
    }

    private func readEvents(at url: URL) throws -> [MissionEvent] {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return []
        }

        let data = try Data(contentsOf: url)
        guard !data.isEmpty else {
            return []
        }

        let body = String(decoding: data, as: UTF8.self)
        return try body
            .split(whereSeparator: \.isNewline)
            .map { try decoder.decode(MissionEvent.self, from: Data($0.utf8)) }
    }

    private func writeEvents(_ events: [MissionEvent], for missionID: MissionID) throws {
        var data = Data()
        for event in events {
            data.append(try encoder.encode(event))
            data.append(0x0A)
        }
        try data.write(to: missionFileURL(for: missionID), options: .atomic)
    }

    private func missionFileURL(for missionID: MissionID) throws -> URL {
        let fileName = Self.fileName(for: missionID)
        let fileURL = directoryURL.appendingPathComponent(fileName, isDirectory: false).standardizedFileURL
        let directoryPath = directoryURL.path.hasSuffix("/") ? directoryURL.path : "\(directoryURL.path)/"

        guard fileURL.path.hasPrefix(directoryPath) else {
            throw LocalMissionStoreError.pathEscapedStoreDirectory
        }

        return fileURL
    }

    static func fileName(for missionID: MissionID) -> String {
        let encoded = Data(missionID.rawValue.utf8)
            .base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")

        return "\(encoded).jsonl"
    }
}
