//
//  RoomView.swift
//  mactrix
//
//  Created by Annie Worrell on 8/6/25.
//

import SwiftUI
import MatrixRustSDK
import Combine

struct RoomView: View {
    @Environment(MatrixState.self) private var matrixState: MatrixState
    var roomInfo: RoomInfo

    @State private var room: Room?
    @State private var roomName: String = ""

    @State private var message: String = ""

    let scrollToBottomNotification = NotificationCenter.default
      .publisher(for: .scrollToBottomTriggered)
      .receive(on: RunLoop.main)

    var body: some View {
        VStack(spacing: 0) {
            if let room, let timelineItemsListener = matrixState.timelineItemsListener {
                let timelineItems = timelineItemsListener.timelineItems.compactMap({$0.asEvent()})
                ScrollViewReader { proxy in
                    List {
                        ForEach(timelineItems.enumerated(), id: \.offset) { index, timelineItem in
                            MessageView(timelineItem: timelineItem)
                                .id(timelineItem.eventOrTransactionId)
                                .tag(timelineItem.eventOrTransactionId)
                        }
                    }
                    .onChange(of: message, initial: true) {
                        proxy.scrollTo(timelineItems.last?.eventOrTransactionId)
                    }
                    .onReceive(scrollToBottomNotification) { notification in
                        proxy.scrollTo(timelineItems.last?.eventOrTransactionId)
                    }
                }

                Spacer()

                Divider()

                HStack {
                    TextField("", text: $message, prompt: Text("Message"))
                        .frame(maxWidth: .infinity)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            sendMessage()
                        }
                    Button {
                        sendMessage()
                    } label: {
                        Label("Send", systemImage: "paperplane.fill")
                    }
                    .disabled(matrixState.sendHandle != nil)
                    .disabled(message.trimmingCharacters(in: .whitespaces).isEmpty)
                    .labelStyle(.iconOnly)
                    .buttonStyle(.glass)
                    .submitLabel(.send)
                }
                .padding()
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
        .frame(minWidth: 400)
    }

    func sendMessage() {
        if message.trimmingCharacters(in: .whitespaces).isEmpty { return }
        Task {
            let msg = messageEventContentFromMarkdown(md: message)
            matrixState.sendHandle = try await matrixState.timeline.send(msg: msg)
            message = ""
        }
    }
}
