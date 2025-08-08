//
//  MessageView.swift
//  mactrix
//
//  Created by Annie Worrell on 8/6/25.
//

import SwiftUI
import MatrixRustSDK

struct MessageView: View {
    @Environment(MatrixState.self) private var matrixState: MatrixState
    var timelineItem: EventTimelineItem

    @State var displayName: String? = nil
    @State var displayNameAmbiguous: Bool = false
    @State var avatarUrl: String? = nil

    var body: some View {
        let messageDate: Date = Date(timeIntervalSince1970: TimeInterval(timelineItem.timestamp / 1000))
        let shields = timelineItem.lazyProvider.getShields(strict: false)
        let displayName = displayName ?? timelineItem.sender

        VStack {
            switch timelineItem.content {
            case .state(stateKey: let stateKey, content: let content):
                TimelineEventState(timelineItem: timelineItem, stateKey: stateKey, content: content)
            case .failedToParseState(eventType: let eventType, stateKey: let stateKey, error: let error):
                TimelineEventBasic(timelineItem: timelineItem, text: "Failed to parse state event: \(eventType), key: \(stateKey), \(error)")
            case .msgLike(content: let messageEvent):
                TimelineEventMessageLike(timelineItem: timelineItem, messageEvent: messageEvent)
            case .failedToParseMessageLike(eventType: let eventType, error: let error):
                TimelineEventBasic(timelineItem: timelineItem, text: "Failed to parse message-like event: \(eventType), \(error)")
            case .profileChange(displayName: let newDisplayName, prevDisplayName: let prevDisplayName, avatarUrl: let newAvatarUrl, prevAvatarUrl: let prevAvatarUrl):
                if let newDisplayName {
                    TimelineEventBasic(timelineItem: timelineItem, text: "\(prevDisplayName ?? displayName) changed their display name to \(newDisplayName)")
                }
                if let newAvatarUrl {
                    TimelineEventBasic(timelineItem: timelineItem, text: "\(newDisplayName ?? displayName) changed their avatar")
                }
                if newDisplayName == nil && newAvatarUrl == nil {
                    TimelineEventBasic(timelineItem: timelineItem, text: "\(displayName) experienced an unhandled profile change.")
                }
            case .roomMembership(userId: let userId, userDisplayName: let userDisplayName, change: let change, reason: let reason):
                let reason: String = (reason != nil) ? " (\(reason ?? ""))" : ""
                let userDisplayName: String = userDisplayName ?? userId
                switch change {
                case .error:
                    TimelineEventBasic(timelineItem: timelineItem, text: "Error changing room membership for \(userDisplayName)\(reason).")
                case .joined:
                    TimelineEventBasic(timelineItem: timelineItem, text: "\(userDisplayName) joined\(reason).")
                case .left:
                    TimelineEventBasic(timelineItem: timelineItem, text: "\(userDisplayName) left\(reason).")
                case .banned:
                    TimelineEventBasic(timelineItem: timelineItem, text: "Banned \(userDisplayName)\(reason).")
                case .unbanned:
                    TimelineEventBasic(timelineItem: timelineItem, text: "Unbanned \(userDisplayName)\(reason).")
                case .kicked:
                    TimelineEventBasic(timelineItem: timelineItem, text: "Kicked \(userDisplayName)\(reason).")
                case .invited:
                    TimelineEventBasic(timelineItem: timelineItem, text: "Invited \(userDisplayName)\(reason).")
                case .kickedAndBanned:
                    TimelineEventBasic(timelineItem: timelineItem, text: "Kicked and banned \(userDisplayName)\(reason).")
                case .invitationAccepted:
                    TimelineEventBasic(timelineItem: timelineItem, text: "\(userDisplayName) accepted invite\(reason).")
                case .invitationRejected:
                    TimelineEventBasic(timelineItem: timelineItem, text: "\(userDisplayName) rejected invite\(reason).")
                case .invitationRevoked:
                    TimelineEventBasic(timelineItem: timelineItem, text: "\(userDisplayName) revoked invitation\(reason).")
                case .knocked:
                    TimelineEventBasic(timelineItem: timelineItem, text: "\(userDisplayName) knocked\(reason).")
                case .knockAccepted:
                    TimelineEventBasic(timelineItem: timelineItem, text: "\(userDisplayName) accepted knock\(reason).")
                case .knockRetracted:
                    TimelineEventBasic(timelineItem: timelineItem, text: "\(userDisplayName) retracted knock\(reason).")
                case .knockDenied:
                    TimelineEventBasic(timelineItem: timelineItem, text: "\(userDisplayName) denied knock\(reason).")
                case .notImplemented:
                    TimelineEventBasic(timelineItem: timelineItem, text: "Event not implemented\(reason).")
                default:
                    TimelineEventBasic(timelineItem: timelineItem, text: "Unhandeled event type.")
                }
            case .callInvite:
                TimelineEventBasic(timelineItem: timelineItem, text: "\(displayName) started a call.")
            case .callNotify:
                TimelineEventBasic(timelineItem: timelineItem, text: "\(displayName) started a call.")
            }
        }
        .padding(10)
        .background() {
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThickMaterial)
        }
        .onChange(of: timelineItem.senderProfile, initial: true) { oldValue, newValue in
            switch newValue {
            case let .ready(displayName: displayName, displayNameAmbiguous: displayNameAmbiguous, avatarUrl: avatarUrl):
                self.displayName = displayName
                self.displayNameAmbiguous = displayNameAmbiguous
                self.avatarUrl = avatarUrl
            case .pending, .error, .unavailable:
                self.displayName = nil
                self.displayNameAmbiguous = true
                self.avatarUrl = nil
            }
        }
    }
}
