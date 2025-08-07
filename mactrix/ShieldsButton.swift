//
//  ShieldsButton.swift
//  mactrix
//
//  Created by Annie Worrell on 8/7/25.
//

import SwiftUI
import MatrixRustSDK

struct ShieldsButton: View {
    @State var shieldState: ShieldState?

    @State private var showShieldMessage: Bool = false

    var body: some View {
        Button {
            showShieldMessage = true
        } label: {
            ShieldsStatus(shieldState: shieldState)
                .labelStyle(.iconOnly)
        }
        .buttonStyle(.plain)
        .buttonBorderShape(.circle)
        .buttonSizing(.flexible)
        .glassEffect(.regular, in: .circle.inset(by: -4))
        .popover(isPresented: $showShieldMessage) {
            VStack {
                ShieldsStatus(shieldState: shieldState)
            }
            .padding()
        }
    }
}

struct ShieldsStatus: View {
    @State var shieldState: ShieldState?

    var body: some View {
        switch shieldState {
        case .grey(code: let code, message: let message):
            Label("\(message) (\(String(describing: code)))", systemImage: "shield.fill")
                .tint(.gray)
                .foregroundStyle(.gray)
        case .red(code: let code, message: let message):
            Label("\(message) (\(String(describing: code)))", systemImage: "exclamationmark.shield.fill")
                .tint(.red)
                .foregroundStyle(.red)
        default:
            Label("Sender is verified", systemImage: "checkmark.shield.fill")
                .tint(.primary)
                .foregroundStyle(.foreground)
        }
    }
}
