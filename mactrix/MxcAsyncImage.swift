//
//  MxcAsyncImage.swift
//  mactrix
//
//  Created by Annie Worrell on 8/6/25.
//

import SwiftUI
import MatrixRustSDK

private struct MxcAsyncImageBody<Content: View, Placeholder: View> : View {
    @Environment(MatrixState.self) private var matrixState: MatrixState

    @State var cachedUrl: String = ""
    @Binding var mxcUrl: String

    @ViewBuilder var content: (Image) -> Content
    @ViewBuilder var placeholder: () -> Placeholder

    @State private var loaded: Bool = false
    @State private var image: Image? = nil
    @State private var errored: Bool = false

    var body: some View {
        Group {
            if errored {
                content(Image(systemName: "exclamationmark.octagon"))
            } else if loaded, let image {
                content(image)
            } else {
                placeholder()
            }
        }
        .task(id: mxcUrl) {
            if cachedUrl == mxcUrl { return }
            if mxcUrl.isEmpty { return }
            await loadData()
        }
    }

    func loadData() async {
        errored = false
        loaded = false
        image = nil

        do {
            image = try await matrixState.loadImageData(urlOrJson: mxcUrl)
        } catch {
            errored = true
            print("Error fetching image in MxcAsyncImageBody: \(error)")
        }

        if image == nil {
            print("Couldn't load image from url: \(mxcUrl)")
        } else {
            cachedUrl = mxcUrl
            loaded = true
        }
    }
}

struct MxcAsyncImage<Content: View, Placeholder: View> : View {
    @Environment(MatrixState.self) private var matrixState: MatrixState
    var mxcUrl: String?
    @ViewBuilder var content: (Image) -> Content
    @ViewBuilder var placeholder: () -> Placeholder

    var body: some View {
        MxcAsyncImageBody(mxcUrl: .constant(mxcUrl ?? ""), content: content, placeholder: placeholder)
    }
}

extension Image {
    /// Initializes a SwiftUI `Image` from data.
    init?(data: Data) {
        #if canImport(UIKit)
        if let uiImage = UIImage(data: data) {
            self.init(uiImage: uiImage)
        } else {
            return nil
        }
        #elseif canImport(AppKit)
        if let nsImage = NSImage(data: data) {
            self.init(nsImage: nsImage)
        } else {
            return nil
        }
        #else
        return nil
        #endif
    }
}
