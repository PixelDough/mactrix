//
//  RoomsList.swift
//  mactrix
//
//  Created by Annie Worrell on 8/6/25.
//

import SwiftUI
import MatrixRustSDK
import Combine

struct RoomsList: View {
    @Environment(MatrixState.self) private var matrixState: MatrixState

    var rooms: [Room]
    @State private var dmRoomItems: [RoomInfo] = []
    @State private var roomItems: [RoomInfo] = []

    var body: some View {
        Section("Direct Messages") {
            ForEach(dmRoomItems, id: \.id) { roomItem in
                NavigationLink(value: roomItem) {
                    RoomLabel(
                        roomInfo: roomItem
                    )
                }
            }
        }
        Section("Rooms") {
            ForEach(roomItems, id: \.id) { roomItem in
                NavigationLink(value: roomItem) {
                    RoomLabel(
                        roomInfo: roomItem
                    )
                }
            }
        }
        .task(id: rooms) {
            dmRoomItems.removeAll()
            roomItems.removeAll()

            var roomInfos: [RoomInfo] = []

            print("Loading rooms... \(rooms)")

            do {
                roomInfos = try await withThrowingTaskGroup(of: RoomInfo.self) { group in
                    for room in self.rooms {
                        print("Loading room \(room.displayName() ?? "Unknown Name")")
                        group.addTask { try await room.roomInfo() }
                    }

                    print("Started all room load tasks")

                    var collected: [RoomInfo] = []

                    for try await value in group {
                        print("Got room value: \(value.displayName ?? "Unknown Name")")
                        collected.append(value)
                    }

                    print("Collected all room infos!")

                    return collected
                }
            } catch {
                print("Error loading room infos: \(error)")
            }

            print("Setting room arrays...")

            dmRoomItems.removeAll()
            roomItems.removeAll()

            for roomInfo in roomInfos {
                if roomInfo.isDirect { dmRoomItems.append(roomInfo) }
                else { roomItems.append(roomInfo) }
            }

            print("Finished setting room arrays!")
        }
    }
}
