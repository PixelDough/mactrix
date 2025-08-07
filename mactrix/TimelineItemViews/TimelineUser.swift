//
//  TimelineUser.swift
//  mactrix
//
//  Created by Annie Worrell on 8/7/25.
//

import SwiftUI
import MatrixRustSDK

struct TimelineUser: View {
    @State var timelineItem: EventTimelineItem

    @State var displayName: String? = nil
    @State var displayNameAmbiguous: Bool = false
    @State var avatarUrl: String? = nil
    
    var body: some View {
        HStack {
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
            if let displayName {
                Text("**\(displayName)** (\(timelineItem.sender))")
            } else {
                Text("**\(timelineItem.sender)**")
            }
        }
        .frame(height: 30)
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
