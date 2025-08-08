//
//  TimelineEventMessageLike.swift
//  mactrix
//
//  Created by Annie Worrell on 8/7/25.
//

import SwiftUI
import MatrixRustSDK

struct TimelineEventMessageLike: View {
    var timelineItem: EventTimelineItem
    @State var messageEvent: MsgLikeContent

    @State var displayName: String? = nil
    @State var displayNameAmbiguous: Bool = false
    @State var avatarUrl: String? = nil
    
    var body: some View {
        Group {
            switch messageEvent.kind {
            case .message(content: let messageContent):
                HStack(alignment: .top) {
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
                    .frame(height: 30)

                    VStack(alignment: .leading) {
                        HStack(alignment: .top) {
                            TimelineUser(timelineItem: timelineItem, showAvatar: false)
                                .layoutPriority(1)

                            Spacer()
                                .frame(minWidth: 4)
                            TimelineTimestamp(timelineItem: timelineItem)
                                .layoutPriority(1)
                            ShieldsButton(shieldState: timelineItem.lazyProvider.getShields(strict: false))
                                .layoutPriority(1)
                        }
                        if case let .file(content: fileContent) = messageContent.msgType {
                            Text("FILE: \(fileContent.filename)")
                        }
                        if case let .gallery(content: galleryContent) = messageContent.msgType {
                            Text("gallery: \(galleryContent.itemtypes.count)")
                        }
                        if case let .image(content: imageContent) = messageContent.msgType {
                            Text("Image: \(imageContent.filename)")
                                .font(.subheadline)
                            MxcAsyncImageSavable(mxcUrl: imageContent.source.toJson()) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .clipShape(
                                        RoundedRectangle(cornerRadius: 10)
                                    )
                            } placeholder: {
                                Rectangle()
                                    .fill(.thinMaterial)
                                    .aspectRatio(contentMode: .fit)
                                    .clipShape(
                                        RoundedRectangle(cornerRadius: 10)
                                    )
                                    .redacted(reason: .placeholder)
                            }
                            .frame(maxHeight: 300)
                        }
                        if case let .text(content: textContent) = messageContent.msgType {
                            Text(textContent.body)
                        }
                    }
                }
            case .redacted:
                TimelineEventBasic(timelineItem: timelineItem, text: "\(displayName ?? timelineItem.sender) redacted a message.")
            case .unableToDecrypt(msg: let encryptedMessage):
                switch encryptedMessage {
                case .olmV1Curve25519AesSha2(let senderKey):
                    TimelineEventBasic(timelineItem: timelineItem, text: "Unable to decrypt message (olmV1Curve25519AesSha2)")
                case .megolmV1AesSha2(let sessionId, let cause):
                    TimelineEventBasic(timelineItem: timelineItem, text: "Unable to decrypt message (megolmV1AesSha2) for session id \(sessionId). Cause: \(cause)")
                case .unknown:
                    TimelineEventBasic(timelineItem: timelineItem, text: "Unable to decrypt message (unknown).")
                }
            default:
                TimelineEventBasic(timelineItem: timelineItem, text: "Unhandeled message event type.")
            }
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
