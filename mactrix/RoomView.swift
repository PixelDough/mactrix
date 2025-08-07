//
//  RoomView.swift
//  mactrix
//
//  Created by Annie Worrell on 8/6/25.
//

import SwiftUI
import MatrixRustSDK

struct RoomView: View {
    @Environment(MatrixState.self) private var matrixState: MatrixState
    @State var roomInfo: RoomInfo

    @State private var room: Room?
    @State private var roomName: String = ""

    var body: some View {
        VStack {
            if let room {
                if let timelineItemsListener = matrixState.timelineItemsListener {
                    let timelineItems = timelineItemsListener.timelineItems.compactMap({$0.asEvent()})
                    ForEach(timelineItems, id: \.localCreatedAt) { timelineItem in
                        if case let .msgLike(content: messageEvent) = timelineItem.content,
                           case let .message(content: messageContent) = messageEvent.kind {
                            Text(messageContent.body)
                        }
                    }
                }
            } else {
                ProgressView("Loading Room")
                    .task(id: roomInfo) {
                        do {
                            room = try matrixState.client.getRoom(roomId: roomInfo.id)
                        } catch {
                            print("Error loading room with id \(roomInfo.id): \(error)")
                        }
                    }
            }
        }
        .onChange(of: roomInfo.id, initial: true) { oldValue, newValue in
            roomName = newValue
        }
        .task(id: roomInfo.id) {
            do {
                try await matrixState.step3LoadRoomTimeline(roomID: roomInfo.id)
            } catch {
                print("Error loading room timeline: \(error)")
            }
        }
    }
}
