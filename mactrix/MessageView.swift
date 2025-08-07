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

    var body: some View {
        if case let .failedToParseMessageLike(eventType: eventType, error: error) = timelineItem.content {
            Text("Failed to parse message like event: \(eventType), \(error)")
        }
        if case let .msgLike(content: messageEvent) = timelineItem.content,
           case let .message(content: messageContent) = messageEvent.kind {
            VStack(alignment: .leading) {
                Text(timelineItem.sender)
                    .fontWeight(.bold)
                if case let .file(content: fileContent) = messageContent.msgType {
                    Text("FILE: \(fileContent.filename)")
                }
                if case let .gallery(content: galleryContent) = messageContent.msgType {
                    Text("gallery: \(galleryContent.itemtypes.count)")
                }
                if case let .image(content: imageContent) = messageContent.msgType {
                    Text("Image: \(imageContent.filename)")
                    MxcAsyncImage(mxcUrl: imageContent.source.toJson()) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 300, height: (CGFloat(imageContent.info!.height!) / CGFloat(imageContent.info!.width!)) * 300)
                            .clipShape(
                                RoundedRectangle(cornerRadius: 10)
                            )
                    } placeholder: {
                        Rectangle()
                            .fill(.thinMaterial)
                            .frame(width: CGFloat(imageContent.info!.width!), height: CGFloat(imageContent.info!.height!))
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 300, height: (CGFloat(imageContent.info!.height!) / CGFloat(imageContent.info!.width!)) * 300)
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
        if case let .profileChange(displayName: displayName, prevDisplayName: prevDisplayName, avatarUrl: avatarUrl, prevAvatarUrl: prevAvatarUrl) = timelineItem.content {
            if let displayName, displayName != prevDisplayName {
                Text("\(timelineItem.sender) changed their display name to \(displayName)")
                    .fontWeight(.bold)
            }
            if let avatarUrl, avatarUrl != prevAvatarUrl {
                Text("\(timelineItem.sender) changed their avatar")
                    .fontWeight(.bold)
            }
        }
    }
}
