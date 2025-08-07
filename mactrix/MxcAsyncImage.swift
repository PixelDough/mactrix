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

    @State var content: (Image) -> Content
    @State var placeholder: () -> Placeholder

    @State var loaded: Bool = false
    @State var image: Image? = nil
    @State var errored: Bool = false

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
            errored = false
            loaded = false
            image = nil
            await loadData()
        }
    }

    func loadData() async {
        do {
            errored = false
            let mediaSource = mxcUrl.hasPrefix("mxc://") ? try MediaSource.fromUrl(url: mxcUrl) : try MediaSource.fromJson(json: mxcUrl)
            let media = try await matrixState.client.getMediaContent(mediaSource: mediaSource)

            if let newImage = Image(data: media) {
                image = newImage
            } else {
                print("Couldn't load image from url: \(mxcUrl)... \(media)")
                errored = true
            }
            loaded = true
            cachedUrl = mxcUrl
        } catch {
            print("Failed to load image from \(mxcUrl): \(error)")
            errored = true
        }
    }
}

struct MxcAsyncImage<Content: View, Placeholder: View> : View {
    @Environment(MatrixState.self) private var matrixState: MatrixState
    var mxcUrl: String?
    @State var content: (Image) -> Content
    @State var placeholder: () -> Placeholder

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
