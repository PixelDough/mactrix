//
//  RoomLabel.swift
//  mactrix
//
//  Created by Annie Worrell on 8/6/25.
//

import SwiftUI
import MatrixRustSDK

struct RoomLabel : View {
    @Environment(MatrixState.self) private var matrixState: MatrixState
    @State var roomInfo: RoomInfo

    @State private var members: [RoomMember] = []
    @State private var myUserId: String = ""

    var body: some View {
        ZStack {
            if let singleMember = members.filter({$0.userId != myUserId }).first, let avatarUrl = singleMember.avatarUrl {
                Label {
                    Text("\(roomInfo.displayName ?? roomInfo.rawName ?? "Unknown Room")")
                } icon: {
                    MxcAsyncImage(mxcUrl: avatarUrl) { image in
                        image
                            .resizable()
                            .scaledToFit()
                            .clipShape(
                                Circle()
                            )
                    } placeholder: {
                        ProgressView()
                            .controlSize(.mini)
                    }
                }
            } else if let avatarUrl = roomInfo.avatarUrl {
                Label {
                    Text("\(roomInfo.displayName ?? roomInfo.rawName ?? "Unknown Room")")
                } icon: {
                    MxcAsyncImage(mxcUrl: avatarUrl) { image in
                        image
                            .resizable()
                            .scaledToFit()
                            .clipShape(
                                Circle()
                            )
                    } placeholder: {
                        ProgressView()
                            .controlSize(.mini)
                    }
                }
            } else {
                Label("\(roomInfo.displayName ?? roomInfo.rawName ?? "Unknown Room")", systemImage: "square.split.bottomrightquarter")
            }
        }
        .onAppear {
            Task {
                await loadData()
            }
        }
    }

    func loadData() async {
        do {
            guard let client = matrixState.client else { return }
            let userId = try client.userId()
            myUserId = userId

            guard let room = try client.getRoom(roomId: roomInfo.id) else { return }
            let roomMembersIterator = try await room.members()
            var newMembers: [RoomMember] = []
            while let chunk = roomMembersIterator.nextChunk(chunkSize: 32) {
                for member in chunk {
                    newMembers.append(member)
                }
            }
            members = newMembers
        } catch {
            print("Failed to load members from room \(roomInfo.id): \(error)")
        }
    }
}
