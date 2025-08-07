//
//  VerificationView.swift
//  mactrix
//
//  Created by Annie Worrell on 8/6/25.
//

import SwiftUI
import MatrixRustSDK

struct VerificationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(MatrixState.self) private var matrixState: MatrixState

    var body: some View {
        VStack(spacing: 0) {
            VStack {
                Text("Verification")
                    .font(.title)
                    .padding(.bottom)
                    .frame(maxWidth: .infinity)

                Spacer()
                switch matrixState.verificationDelegate?.flowState {
                case .verificationRequested:
                    Text("Waiting on approval from another device to continue")
                case .verificationRequestAccepted:
                    Text("Verification request accepted")
                case .receivedVerificationRequest:
                    Text("Received verification request")
                case .sasVerificationStarted:
                    Text("Started SAS verification")
                case .receivedVerificationData:
                    if let verificationData = matrixState.verificationDelegate?.sessionVerificationData {
                        switch verificationData {
                        case .emojis(let emojis, _):
                            Text("Make sure the emojis shown on the other device match this order exactly.")

                            VStack(alignment: .leading) {
                                ForEach(emojis.enumerated(), id: \.offset) { index, emoji in
                                    Label{
                                        Text(emoji.description())
                                    } icon: {
                                        Text(emoji.symbol())
                                    }
                                    .font(.title)
                                }
                            }
                            .padding()
                        case .decimals(let values):
                            Text(values.map(\.description).joined(separator: ", "))
                        }
                    }
                case .failed:
                    Text("Verification failed. Please try again.")
                case .cancelled:
                    Text("Verification cancelled.")
                case .finished:
                    Text("Verification successful!")
                case nil:
                    EmptyView()
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()

            Divider()
                .frame(height: 1)

            HStack(alignment: .center) {
                Spacer()

                let flowState = matrixState.verificationDelegate?.flowState ?? .verificationRequested

                if flowState == .cancelled || flowState == .failed || flowState == .finished {
                    Button {
                        dismiss.callAsFunction()
                    } label: {
                        Label("Close", systemImage: "xmark")
                            .labelStyle(.titleOnly)
                    }
                } else {
                    Button {
                        dismiss.callAsFunction()
                        Task {
                            try await matrixState.sessionVerificationController?.cancelVerification()
                        }
                    } label: {
                        Label("Cancel", systemImage: "xmark")
                            .labelStyle(.titleOnly)
                    }

                    if flowState == .receivedVerificationData {
                        Button {
                            Task {
                                try await matrixState.sessionVerificationController?.approveVerification()
                            }
                        } label: {
                            Label("Confirm", systemImage: "check")
                                .labelStyle(.titleOnly)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.accentColor)
                    }
                }
            }
            .padding()
        }
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
    }
}
