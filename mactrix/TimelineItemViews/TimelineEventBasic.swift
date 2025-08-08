//
//  TimelineEventBasic.swift
//  mactrix
//
//  Created by Annie Worrell on 8/7/25.
//

import SwiftUI
import MatrixRustSDK

struct TimelineEventBasic: View {
    var timelineItem: EventTimelineItem
    @State var text: String
    var body: some View {
        HStack(alignment: .top) {
            Text(text)
                .layoutPriority(1)

            Spacer()
                .frame(minWidth: 4)

            TimelineTimestamp(timelineItem: timelineItem)
                .layoutPriority(1)
            ShieldsButton(shieldState: timelineItem.lazyProvider.getShields(strict: false))
                .layoutPriority(1)
        }
    }
}
