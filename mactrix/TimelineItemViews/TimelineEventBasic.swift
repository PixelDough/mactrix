//
//  TimelineEventBasic.swift
//  mactrix
//
//  Created by Annie Worrell on 8/7/25.
//

import SwiftUI
import MatrixRustSDK

struct TimelineEventBasic: View {
    @State var timelineItem: EventTimelineItem
    @State var text: String
    var body: some View {
        HStack {
            Text(text)

            Spacer()
                .frame(minWidth: 4)

            TimelineTimestamp(timelineItem: timelineItem)
            ShieldsButton(shieldState: timelineItem.lazyProvider.getShields(strict: false))
        }
    }
}
