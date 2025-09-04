import XCTest
@testable import FountainRuntime
import Yams
import Foundation

final class ZoneManagerTests: XCTestCase {
    func temporaryFile() -> URL {
        let dir = FileManager.default.temporaryDirectory
        return dir.appendingPathComponent(UUID().uuidString)
    }

    func testLoadsExistingZonesFromDisk() async throws {
        let file = temporaryFile()
        let record = ZoneManager.Record(id: UUID(), name: "", type: "A", value: "1.2.3.4")
        let zone = ZoneManager.Zone(id: UUID(), name: "example.com", records: [record.id: record])
        let yaml = try YAMLEncoder().encode([zone.id: zone])
        try yaml.write(to: file, atomically: true, encoding: .utf8)
        let manager = try ZoneManager(fileURL: file)
        let fetched = await manager.record(name: "example.com", type: "A")
        XCTAssertEqual(fetched?.value, "1.2.3.4")
    }

    func testPersistsUpdatesToDisk() async throws {
        let file = temporaryFile()
        let manager = try ZoneManager(fileURL: file)
        let zone = try await manager.createZone(name: "example.com")
        _ = try await manager.createRecord(zoneId: zone.id, name: "", type: "A", value: "5.6.7.8")
        let contents = try String(contentsOf: file, encoding: .utf8)
        let decoded = try YAMLDecoder().decode([UUID: ZoneManager.Zone].self, from: contents)
        XCTAssertEqual(decoded[zone.id]?.records.values.first?.value, "5.6.7.8")
    }

    func testConcurrentUpdatesAreSerialized() async throws {
        let file = temporaryFile()
        let manager = try ZoneManager(fileURL: file)
        let zone = try await manager.createZone(name: "test")
        try await withThrowingTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    _ = try await manager.createRecord(zoneId: zone.id, name: "host\(i)", type: "A", value: "1.1.1.\(i)")
                }
            }
            try await group.waitForAll()
        }
        let records = await manager.listRecords(zoneId: zone.id)
        XCTAssertEqual(records?.count, 10)
    }

    func testReloadUpdatesCache() async throws {
        let file = temporaryFile()
        let manager = try ZoneManager(fileURL: file)
        let zone = try await manager.createZone(name: "example.com")
        _ = try await manager.createRecord(zoneId: zone.id, name: "", type: "A", value: "1.1.1.1")
        try await Task.sleep(nanoseconds: 1_000_000_000)
        let record = ZoneManager.Record(id: UUID(), name: "", type: "A", value: "2.2.2.2")
        let newZone = ZoneManager.Zone(id: zone.id, name: "example.com", records: [record.id: record])
        let yaml = try YAMLEncoder().encode([zone.id: newZone])
        try yaml.write(to: file, atomically: true, encoding: .utf8)
        await manager.reload()
        let fetched = await manager.record(name: "example.com", type: "A")
        XCTAssertEqual(fetched?.value, "2.2.2.2")
    }

    func testDeleteZoneReturnsFalseForUnknownID() async throws {
        let file = temporaryFile()
        let manager = try ZoneManager(fileURL: file)
        let result = try await manager.deleteZone(id: UUID())
        XCTAssertFalse(result)
    }

    func testCreateRecordReturnsNilForUnknownZone() async throws {
        let file = temporaryFile()
        let manager = try ZoneManager(fileURL: file)
        let rec = try await manager.createRecord(zoneId: UUID(), name: "a", type: "A", value: "1.1.1.1")
        XCTAssertNil(rec)
    }

    func testUpdateRecordReturnsNilForMissingRecord() async throws {
        let file = temporaryFile()
        let manager = try ZoneManager(fileURL: file)
        let zone = try await manager.createZone(name: "example.com")
        let updated = try await manager.updateRecord(zoneId: zone.id, recordId: UUID(), name: "a", type: "A", value: "1.1.1.1")
        XCTAssertNil(updated)
    }

    func testDeleteRecordReturnsFalseForUnknownRecord() async throws {
        let file = temporaryFile()
        let manager = try ZoneManager(fileURL: file)
        let zone = try await manager.createZone(name: "example.com")
        let result = try await manager.deleteRecord(zoneId: zone.id, recordId: UUID())
        XCTAssertFalse(result)
    }

    func testInitBuildsRecordMapWithSubrecord() async throws {
        let file = temporaryFile()
        let record = ZoneManager.Record(id: UUID(), name: "www", type: "A", value: "1.2.3.4")
        let zone = ZoneManager.Zone(id: UUID(), name: "example.com", records: [record.id: record])
        let yaml = try YAMLEncoder().encode([zone.id: zone])
        try yaml.write(to: file, atomically: true, encoding: .utf8)
        let manager = try ZoneManager(fileURL: file)
        let fetched = await manager.record(name: "www.example.com", type: "A")
        XCTAssertEqual(fetched?.value, "1.2.3.4")
    }

    func testSetCommitsChangesToGit() async throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let file = dir.appendingPathComponent("zones.yaml")
        try "".write(to: file, atomically: true, encoding: .utf8)
        let initTask = Process()
        initTask.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        initTask.currentDirectoryURL = dir
        initTask.arguments = ["init"]
        try initTask.run()
        initTask.waitUntilExit()
        let manager = try ZoneManager(fileURL: file)
        let zone = try await manager.createZone(name: "example.com")
        _ = try await manager.createRecord(zoneId: zone.id, name: "", type: "A", value: "3.3.3.3")
        let logTask = Process()
        logTask.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        logTask.currentDirectoryURL = dir
        logTask.arguments = ["log", "--oneline"]
        let pipe = Pipe()
        logTask.standardOutput = pipe
        try logTask.run()
        logTask.waitUntilExit()
        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        XCTAssertTrue(output.contains("Update zone file"))
    }

    func testListAndDeleteZonesAndRecords() async throws {
        let file = temporaryFile()
        let manager = try ZoneManager(fileURL: file)
        let zone1 = try await manager.createZone(name: "example.com")
        let zone2 = try await manager.createZone(name: "example.org")
        let record1 = try await manager.createRecord(zoneId: zone1.id, name: "www", type: "A", value: "1.1.1.1")
        _ = try await manager.createRecord(zoneId: zone2.id, name: "", type: "A", value: "2.2.2.2")

        let zones = await manager.listZones()
        XCTAssertEqual(zones.count, 2)

        let recordsZone1 = await manager.listRecords(zoneId: zone1.id)
        XCTAssertEqual(recordsZone1?.count, 1)

        _ = try await manager.deleteRecord(zoneId: zone1.id, recordId: record1!.id)
        let afterDeleteRecords = await manager.listRecords(zoneId: zone1.id)
        XCTAssertEqual(afterDeleteRecords?.count, 0)

        _ = try await manager.deleteZone(id: zone2.id)
        let zonesAfterDelete = await manager.listZones()
        XCTAssertEqual(zonesAfterDelete.count, 1)
    }

    func testUpdatesStreamEmitsOnModification() async throws {
        let file = temporaryFile()
        let manager = try ZoneManager(fileURL: file)
        var iterator = manager.updates.makeAsyncIterator()
        _ = await iterator.next() // initial snapshot

        let zone = try await manager.createZone(name: "example.com")
        _ = await iterator.next() // snapshot after zone creation
        let record = try await manager.createRecord(zoneId: zone.id, name: "", type: "A", value: "1.1.1.1")
        let afterCreate = await iterator.next()
        let key = ZoneManager.RecordKey(name: "example.com", type: "A")
        XCTAssertEqual(afterCreate?[key]?.value, "1.1.1.1")

        _ = try await manager.updateRecord(zoneId: zone.id, recordId: record!.id, name: "", type: "A", value: "2.2.2.2")
        let afterUpdate = await iterator.next()
        XCTAssertEqual(afterUpdate?[key]?.value, "2.2.2.2")
    }

    func testDisableGitCommitsSkipsCommit() async throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let file = dir.appendingPathComponent("zones.yaml")
        try "".write(to: file, atomically: true, encoding: .utf8)
        let initTask = Process()
        initTask.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        initTask.currentDirectoryURL = dir
        initTask.arguments = ["init"]
        try initTask.run()
        initTask.waitUntilExit()
        let addTask = Process()
        addTask.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        addTask.currentDirectoryURL = dir
        addTask.arguments = ["add", "zones.yaml"]
        try addTask.run()
        addTask.waitUntilExit()
        let commitTask = Process()
        commitTask.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        commitTask.currentDirectoryURL = dir
        commitTask.arguments = ["commit", "-m", "Initial"]
        try commitTask.run()
        commitTask.waitUntilExit()

        let manager = try ZoneManager(fileURL: file, enableGitCommits: false)
        let zone = try await manager.createZone(name: "example.com")
        _ = try await manager.createRecord(zoneId: zone.id, name: "", type: "A", value: "4.4.4.4")

        let logTask = Process()
        logTask.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        logTask.currentDirectoryURL = dir
        logTask.arguments = ["log", "--oneline"]
        let pipe = Pipe()
        logTask.standardOutput = pipe
        try logTask.run()
        logTask.waitUntilExit()
        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        XCTAssertFalse(output.contains("Update zone file"))
    }
}

final class ZoneManagerRecordTypeTests: XCTestCase {
    func temporaryFile() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    }

    func testRetrievesRecordsByType() async throws {
        let file = temporaryFile()
        let manager = try ZoneManager(fileURL: file)
        let zone = try await manager.createZone(name: "example.com")
        _ = try await manager.createRecord(zoneId: zone.id, name: "", type: "A", value: "1.1.1.1")
        _ = try await manager.createRecord(zoneId: zone.id, name: "", type: "AAAA", value: "2001:db8::1")
        _ = try await manager.createRecord(zoneId: zone.id, name: "alias", type: "CNAME", value: "example.com")
        let a = await manager.record(name: "example.com", type: "A")
        let aaaa = await manager.record(name: "example.com", type: "AAAA")
        let cname = await manager.record(name: "alias.example.com", type: "CNAME")
        XCTAssertEqual(a?.value, "1.1.1.1")
        XCTAssertEqual(aaaa?.value, "2001:db8::1")
        XCTAssertEqual(cname?.value, "example.com")
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
