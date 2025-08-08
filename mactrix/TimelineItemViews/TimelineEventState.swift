//
//  TimelineEventState.swift
//  mactrix
//
//  Created by Annie Worrell on 8/7/25.
//

import SwiftUI
import MatrixRustSDK

struct TimelineEventState: View {
    var timelineItem: EventTimelineItem
    @State var stateKey: String
    @State var content: OtherState

    @State var displayName: String = ""
    @State var displayNameAmbiguous: Bool = false
    @State var avatarUrl: String? = nil

    var body: some View {
        Group {
            switch content {
            case .roomCreate:
                TimelineEventBasic(timelineItem: timelineItem, text: "\(displayName) created the room.")
            case .roomEncryption:
                TimelineEventBasic(timelineItem: timelineItem, text: "\(displayName) changed the room encryption state.")
            case .roomName(name: let roomName):
                if let roomName {
                    TimelineEventBasic(timelineItem: timelineItem, text: "\(displayName) changed the room name to \(roomName).")
                } else {
                    TimelineEventBasic(timelineItem: timelineItem, text: "\(displayName) removed the room name.")
                }
            case .roomTopic(topic: let roomTopic):
                if let roomTopic {
                    TimelineEventBasic(timelineItem: timelineItem, text: "\(displayName) changed the room topic to \(roomTopic).")
                } else {
                    TimelineEventBasic(timelineItem: timelineItem, text: "\(displayName) removed the room topic.")
                }
            case .roomAvatar(url: let roomAvatar):
                if let roomAvatar {
                    TimelineEventBasic(timelineItem: timelineItem, text: "\(displayName) changed the room avatar.")
                } else {
                    TimelineEventBasic(timelineItem: timelineItem, text: "\(displayName) removed the room avatar.")
                }
            default:
                TimelineEventBasic(timelineItem: timelineItem, text: "Unhandled state change: \(String(describing: content)), key: \(stateKey)")
            }
        }
        .onChange(of: timelineItem.senderProfile, initial: true) { oldValue, newValue in
            switch newValue {
            case let .ready(displayName: displayName, displayNameAmbiguous: displayNameAmbiguous, avatarUrl: avatarUrl):
                self.displayName = displayName ?? timelineItem.sender
                self.displayNameAmbiguous = displayNameAmbiguous
                self.avatarUrl = avatarUrl
            case .pending, .error, .unavailable:
                self.displayName = timelineItem.sender
                self.displayNameAmbiguous = true
                self.avatarUrl = nil
            }
        }
    }
}
