//
//  MatrixState.swift
//  mactrix
//
//  Created by Annie Worrell on 8/6/25.
//

import SwiftUI
import ArgumentParser
import Foundation
import KeychainAccess
import MatrixRustSDK
import Combine

@Observable
class MatrixState {

    let applicationID = "dev.anniesden.mactrix"
    let keychainSessionKey = "WalkthroughUser"

    var cancellables: Set<AnyCancellable> = []

    func logout() async throws {
        defer {
            client = nil

            syncService = nil
            roomListService = nil
            allRoomsListener.rooms = []
            allRoomsListener = nil
            roomListEntriesHandle = nil

            timeline = nil
            timelineItemsListener = nil
            timelineHandle = nil

            sendHandle = nil
        }

        do {
            try await client.logout()
        } catch {
            print("Error calling client.logout(): \(error)")
        }
    }

    // MARK: - Step 1
    // Authenticate the user.

    var client: Client!

    func step1Login(username: String, password: String) async throws -> WalkthroughUser {
        let storeID = UUID().uuidString

        print("Step 1: Login")

        // Create a client for a particular homeserver.
        // Note that we can pass a server name (the second part of a Matrix user ID) instead of the direct URL.
        // This allows the SDK to discover the homeserver's well-known configuration for Sliding Sync support.
        let client = try await ClientBuilder()
            .serverNameOrHomeserverUrl(serverNameOrUrl: "matrix.org")
            .sessionPaths(dataPath: URL.sessionData(for: storeID).path(percentEncoded: false),
                          cachePath: URL.sessionCaches(for: storeID).path(percentEncoded: false))
            .slidingSyncVersionBuilder(versionBuilder: .discoverNative)
            .build()
        print("Created client")

        // Login using password authentication.
        print("Awaiting login...")
        try await client.login(username: username, password: password, initialDeviceName: nil, deviceId: nil)
        print("Logged in!")

        self.client = client

        print("\(client.homeserver())")

        let session = try client.session()

        // This data should be stored securely in the keychain.
        return WalkthroughUser(session: session, storeID: storeID)
    }

    // Or, if the user has previously authenticated we can restore their session instead.

    func step1Restore(_ walkthroughUser: WalkthroughUser) async throws {
        print("Step 1: Restore")

        let session = walkthroughUser.session
        let sessionID = walkthroughUser.storeID

        // Build a client for the homeserver.
        print("Creating client...")
        let client = try await ClientBuilder()
            .sessionPaths(dataPath: URL.sessionData(for: sessionID).path(percentEncoded: false),
                          cachePath: URL.sessionCaches(for: sessionID).path(percentEncoded: false))
            .homeserverUrl(url: session.homeserverUrl)
            .build()
        print("Created client")

        // Restore the client using the session.
        print("Restoring session...")
        try await client.restoreSession(session: session)
        print("Logged in!")

        print("\(client.homeserver())")

        await client.encryption().waitForE2eeInitializationTasks()

        self.client = client
    }

    // MARK: - Step 2
    // Build the room list.

    @Observable
    class AllRoomsListener: RoomListEntriesListener {
        /// The user's list of rooms.
        var rooms: [Room] = []

        func onUpdate(roomEntriesUpdate: [RoomListEntriesUpdate]) {
            // Update the user's room list on each update.
            for update in roomEntriesUpdate {
                switch update {
                case .append(let values):
                    rooms.append(contentsOf: values)
                case .clear:
                    rooms.removeAll()
                case .pushFront(let room):
                    rooms.insert(room, at: 0)
                case .pushBack(let room):
                    rooms.append(room)
                case .popFront:
                    rooms.removeFirst()
                case .popBack:
                    rooms.removeLast()
                case .insert(let index, let room):
                    rooms.insert(room, at: Int(index))
                case .set(let index, let room):
                    rooms[Int(index)] = room
                case .remove(let index):
                    rooms.remove(at: Int(index))
                case .truncate(let length):
                    rooms.removeSubrange(Int(length)..<rooms.count)
                case .reset(values: let values):
                    rooms = values
                }
            }
        }
    }

    var syncService: SyncService!
    var roomListService: RoomListService!
    var allRoomsListener: AllRoomsListener!
    var roomListEntriesHandle: RoomListEntriesWithDynamicAdaptersResult!

    func step2StartSync() async throws {
        print("Step 2: Start Sync")

        // Create a sync service which controls the sync loop.
        print("Starting sync service...")
        syncService = try await client.syncService().finish()
        print("Sync service started!")

        // Listen to room list updates.
        print("Listen to room list updates")
        allRoomsListener = AllRoomsListener()
        roomListService = syncService.roomListService()
        roomListEntriesHandle = try await roomListService.allRooms().entriesWithDynamicAdapters(pageSize: 100, listener: allRoomsListener)
        _ = roomListEntriesHandle.controller().setFilter(kind: .all(filters: []))

        // Start the sync loop.
        print("Starting the sync loop")
        await syncService.start()
    }

    // MARK: - Step 2.5
    // Verification State

    @Observable
    class VerificationListener: VerificationStateListener {
        func onUpdate(status: MatrixRustSDK.VerificationState) {
            switch status {
            case .unknown:
                print(status)
            case .unverified:
                print(status)
            case .verified:
                print(status)
            }
        }
    }

    @Observable
    class VerificationDelegate: SessionVerificationControllerDelegate {
        enum VerificationFlowState {
            case verificationRequested
            case verificationRequestAccepted
            case receivedVerificationRequest
            case sasVerificationStarted
            case receivedVerificationData
            case failed
            case cancelled
            case finished
        }
        var sessionVerificationData: SessionVerificationData?
        var flowState: VerificationFlowState = .verificationRequested
        func didReceiveVerificationRequest(details: MatrixRustSDK.SessionVerificationRequestDetails) {
            print("Received Verification Request: \(details)")
            flowState = .receivedVerificationRequest
        }

        func didAcceptVerificationRequest() {
            print("Accepted Verification Request")
            flowState = .verificationRequestAccepted
        }

        func didStartSasVerification() {
            print("Started SAS Verification")
            flowState = .sasVerificationStarted
        }

        func didReceiveVerificationData(data: MatrixRustSDK.SessionVerificationData) {
            print("Received Verification Data: \(data)")

            flowState = .receivedVerificationData
            sessionVerificationData = data

            switch data {
            case .emojis(let emojis, let indices):
                print("Emojis: \(emojis.map({$0.description()}))")
                print("Indices: \(indices)")
            case .decimals(let values):
                print("Decimals: \(values)")
            }
        }

        func didFail() {
            print("Failed Verification!")

            sessionVerificationData = nil
            flowState = .failed
        }

        func didCancel() {
            print("Canceled Verification!")

            sessionVerificationData = nil
            flowState = .cancelled
        }

        func didFinish() {
            print("Finished Verification!")

            sessionVerificationData = nil
            flowState = .finished
        }
    }

    var sessionVerificationController: SessionVerificationController?
    var verificationDelegate: VerificationDelegate?

    func verificationStep() async throws {
        print("Verification Step")

        if sessionVerificationController == nil {
            print("Getting verification controller...")
            let newVerificationController = try await client.getSessionVerificationController()
            sessionVerificationController = newVerificationController
        }
        if let sessionVerificationController, verificationDelegate == nil {
            verificationDelegate = VerificationDelegate()
            sessionVerificationController.setDelegate(delegate: verificationDelegate)
        }

        verificationDelegate?.flowState = .verificationRequested

        let encryption = client.encryption()
        print("Encryption verification state: \(encryption.verificationState())")

        if encryption.verificationState() != .verified, let sessionVerificationController {
            print("Requesting device verification...")
            try await sessionVerificationController.requestDeviceVerification()
            print("Device verification requested!")
        }

        print("Wait for E2EE Initialization Tasks...")
        await encryption.waitForE2eeInitializationTasks()
//        var verificationListener: VerificationListener = VerificationListener()
//        encryption.verificationStateListener(listener: verificationListener)
//        try await verificationController.startSasVerification()
//        print("Sas Verification Started")
    }

    // MARK: - Step 3
    // Create a timeline.

    @Observable
    class TimelineItemListener: TimelineListener {
        /// The loaded items for this room's timeline
        var timelineItems: [TimelineItem] = []

        func onUpdate(diff: [TimelineDiff]) {
            // Update the timeline items on each update.
            for update in diff {
                switch update {
                case .append(let values):
                    timelineItems.append(contentsOf: values)
                case .clear:
                    timelineItems.removeAll()
                case .pushFront(let room):
                    timelineItems.insert(room, at: 0)
                case .pushBack(let room):
                    timelineItems.append(room)
                case .popFront:
                    timelineItems.removeFirst()
                case .popBack:
                    timelineItems.removeLast()
                case .insert(let index, let room):
                    timelineItems.insert(room, at: Int(index))
                case .set(let index, let room):
                    timelineItems[Int(index)] = room
                case .remove(let index):
                    timelineItems.remove(at: Int(index))
                case .truncate(let length):
                    timelineItems.removeSubrange(Int(length)..<timelineItems.count)
                case .reset(values: let values):
                    timelineItems = values
                }
            }
        }
    }

    var timeline: Timeline!
    var timelineItemsListener: TimelineItemListener!
    var timelineHandle: TaskHandle!

    func step3LoadRoomTimeline(roomID: String) async throws {
        print("Step 3: Load Room Timeline")

        // Wait for the rooms array to contain the desired room…
        print("Waiting for desired room...")
        while !allRoomsListener.rooms.contains(where: { $0.id() == roomID }) {
            try await Task.sleep(for: .milliseconds(250))
        }

        // Fetch the room from the listener and initialise its timeline.
        print("Waiting for room's timeline...")
        let room = allRoomsListener.rooms.first { $0.id() == roomID }!
        timeline = try await room.timeline()
        try await timeline.paginateBackwards(numEvents: 100)

        // Listen to timeline item updates.
        print("Listening for timeline item updates...")
        timelineItemsListener = TimelineItemListener()
        timelineHandle = await timeline.addListener(listener: timelineItemsListener)

        // Wait for the items array to be updated…
        print("Waiting for items array to be updated...")
        while timelineItemsListener.timelineItems.isEmpty {
            try await Task.sleep(for: .milliseconds(250))
        }
    }

    // MARK: - Step 4
    // Sending events.

    var sendHandle: SendHandle?

    func step4SendMessage() async throws {
        // Create the message content from a markdown string.
        let message = messageEventContentFromMarkdown(md: "Hello, World!")

        // Send the message content via the room's timeline (so that we show a local echo).
        sendHandle = try await timeline.send(msg: message)
    }
}


extension Client: @retroactive Equatable {}
extension Client: @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        do {
            hasher.combine(try self.userId())
        } catch {
            print("Error hashing client: \(error)")
        }
    }
    public static func == (lhs: Client, rhs: Client) -> Bool {
        do {
            let lhsId = try lhs.userId()
            let rhsId = try rhs.userId()
            return lhsId == rhsId
        } catch {
            print("Error checking equality of two clients: \(error)")
        }
        return false;
    }
}

extension RoomInfo: @retroactive Equatable {}
extension RoomInfo: @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    public static func == (lhs: RoomInfo, rhs: RoomInfo) -> Bool {
        lhs.id == rhs.id
    }
}

extension Room: @retroactive Equatable {}
extension Room: @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id())
    }
    public static func == (lhs: Room, rhs: Room) -> Bool {
        lhs.id() == rhs.id()
    }
}

extension SessionVerificationEmoji: @retroactive Equatable {}
extension SessionVerificationEmoji: @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(description())
    }
    public static func == (lhs: SessionVerificationEmoji, rhs: SessionVerificationEmoji) -> Bool {
        lhs.description() == rhs.description()
    }
}
