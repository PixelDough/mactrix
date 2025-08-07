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

    @State private var earlierEventsExist: Bool = true

    let scrollToBottomNotification = NotificationCenter.default
      .publisher(for: .scrollToBottomTriggered)
      .receive(on: RunLoop.main)

    @State private var timelineItems: [EventTimelineItem] = []

    var body: some View {
        VStack(spacing: 0) {
            if let room {
                ScrollView {
                    ScrollViewReader { proxy in
                        LazyVStack {
                            Button {
                                Task {
                                    do {
                                        earlierEventsExist = try await !matrixState.timeline.paginateBackwards(numEvents: 50)
                                        print("Load earlier: \(earlierEventsExist)")
                                    } catch {
                                        print("Error paginating backwards: \(error)")
                                    }
                                }
                            } label: {
                                Text("Load Earlier")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.glass)
                            .disabled(!earlierEventsExist)
                            ForEach(timelineItems.enumerated(), id: \.offset) { index, timelineItem in
                                MessageView(timelineItem: timelineItem)
                                Divider()
                            }
                            Divider()
                                .frame(height: 0)
                                .hidden()
                                .id("BOTTOM_DIVIDER")
                        }
                        .onChange(of: message, initial: true) {
                            proxy.scrollTo("BOTTOM_DIVIDER")
                        }
                        .onReceive(scrollToBottomNotification) { notification in
                            proxy.scrollTo("BOTTOM_DIVIDER")
                        }
                        .padding()
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
            earlierEventsExist = true
            matrixState.timelineItemsListener?.timelineItems.removeAll()
        }
        .task(id: roomInfo.id) {
            do {
                try await matrixState.step3LoadRoomTimeline(roomID: roomInfo.id)
            } catch {
                print("Error loading room timeline: \(error)")
            }
        }
        .onChange(of: matrixState.timelineItemsListener?.timelineItems) {
            timelineItems = matrixState.timelineItemsListener?.timelineItems.compactMap({$0.asEvent()}) ?? []
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
