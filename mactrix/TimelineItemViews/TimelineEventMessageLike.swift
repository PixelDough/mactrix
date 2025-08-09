//
//  TimelineEventMessageLike.swift
//  mactrix
//
//  Created by Annie Worrell on 8/7/25.
//

import SwiftUI
import MatrixRustSDK
import AVKit

struct TimelineEventMessageLike: View {
    @Environment(MatrixState.self) private var matrixState: MatrixState
    var timelineItem: EventTimelineItem
    @State var messageEvent: MsgLikeContent

    @State private var displayName: String? = nil
    @State private var displayNameAmbiguous: Bool = false
    @State private var avatarUrl: String? = nil

    @State private var mediaFileHandle: MediaFileHandle? = nil
    @State private var videoPlayer: AVPlayer = AVPlayer()

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
                        switch messageContent.msgType {
                        case .emote(let content):
                            Text("emote: \(content.body)")
                        case .image(let content):
                            Text("Image: \(content.filename)")
                                .font(.subheadline)
                            MxcAsyncImageSavable(mxcUrl: content.source.toJson()) { image in
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
                        case .audio(let content):
                            Text("audio: \(content.filename)")
                        case .video(let content):
                            Text("video: \(content.filename)")
                            VideoPlayer(player: videoPlayer)
                                .clipShape(
                                    RoundedRectangle(cornerRadius: 10)
                                )
                                .frame(width: 300, height: 300)
                                .task(id: content.info?.blurhash ?? "") {
                                    do {
                                        mediaFileHandle = try await matrixState.getMediaFile(urlOrJson: content.source.toJson(), filename: content.filename, mimeType: "video/mp4", useCache: true)
                                        guard let mediaFileHandle else { return }
                                        let url: URL = URL(fileURLWithPath: try mediaFileHandle.path())

                                        videoPlayer.replaceCurrentItem(with: AVPlayerItem(url: url))
                                    } catch {
                                        print("Error loading video: \(error)")
                                    }
                                }
                                .onDisappear {
                                    videoPlayer.pause()
                                }
                        case .file(let content):
                            Text("file: \(content.filename)")
                        case .gallery(let content):
                            Text("gallery: \(content.itemtypes.count)")
                        case .notice(let content):
                            Text("notice: \(content.body)")
                        case .text(let content):
                            Text(content.body)
                        case .location(let content):
                            Text("location: \(content.body)")
                        case .other(let msgtype, let body):
                            Text("other (\(msgtype)): \(body)")
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
