//
//  TimelineTimestamp.swift
//  mactrix
//
//  Created by Annie Worrell on 8/7/25.
//

import SwiftUI
import MatrixRustSDK

struct TimelineTimestamp: View {
    @State var timelineItem: EventTimelineItem

    @State private var date: Date = .now

    var body: some View {
        Text("\(date.formatted(date: .abbreviated, time: .shortened))")
            .onAppear {
                date = Date(timeIntervalSince1970: TimeInterval(timelineItem.timestamp / 1000))
            }
    }
}
