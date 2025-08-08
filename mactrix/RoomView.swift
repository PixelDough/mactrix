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

    @State private var scrollPositionID: EventOrTransactionId?

    var body: some View {
        ScrollView {
            if let room {
                ScrollViewReader { proxy in
                    LazyVStack(pinnedViews: .sectionFooters) {
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
                        .buttonStyle(.bordered)
                        .disabled(!earlierEventsExist)
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
                .scrollTargetLayout()
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
        .scrollPosition(id: $scrollPositionID)
        .onAppear{ scrollPositionID = timelineItems.first?.eventOrTransactionId }
        .defaultScrollAnchor(.bottom, for: .alignment)
        .task(id: roomInfo.id) {
            roomName = roomInfo.id
            earlierEventsExist = true
            scrollPositionID = nil
//            matrixState.timelineItemsListener?.timelineItems.removeAll()

            do {
                try await matrixState.step3LoadRoomTimeline(roomID: roomInfo.id)
            } catch {
                print("Error loading room timeline: \(error)")
            }
        }
        .onChange(of: matrixState.timelineItemsListener?.timelineItems) {
            timelineItems = matrixState.timelineItemsListener?.timelineItems.compactMap({$0.asEvent()}) ?? []
        }
        .contentMargins(.horizontal, 20, for: .scrollContent)
        .frame(minWidth: 400)
        .safeAreaInset(edge: .bottom) {
            HStack {
                TextField("", text: $message, prompt: Text("Message"))
                    .frame(maxWidth: .infinity)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        sendMessage()
                    }
                    .padding(4)
                    .glassEffect(.regular.interactive(), in: .capsule.inset(by: -4))
                Button {
                    sendMessage()
                } label: {
                    Label("Send", systemImage: "paperplane.fill")
                        .padding(4)
                }
                .disabled(matrixState.sendHandle != nil)
                .disabled(message.trimmingCharacters(in: .whitespaces).isEmpty)
                .labelStyle(.iconOnly)
                .buttonStyle(.plain)
                .buttonSizing(.fitted)
                .glassEffect(.regular.interactive(), in: .circle.inset(by: -4))
                .submitLabel(.send)
            }
            .padding()
//            .background {
//                LinearGradient(colors: [Color.clear, Color.black], startPoint: .top, endPoint: .bottom)
//                    .glassEffect()
//            }
        }
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
