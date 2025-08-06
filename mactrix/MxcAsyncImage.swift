//
//  MxcAsyncImage.swift
//  mactrix
//
//  Created by Annie Worrell on 8/6/25.
//

import SwiftUI
import MatrixRustSDK

struct MxcAsyncImage<Content: View, Placeholder: View> : View {
    @Environment(MatrixState.self) private var matrixState: MatrixState
    var mxcUrl: String = ""
    @State var content: (Image) -> Content
    @State var placeholder: () -> Placeholder

    @State var loaded: Bool = false
    @State var image: Image? = nil

    var body: some View {
        if loaded, let image {
            content(image)
        } else {
            placeholder()
                .task(id: mxcUrl) {
                    if mxcUrl.isEmpty || !mxcUrl.hasPrefix("mxc://") { return }
                    await loadData()
                }
        }
    }

    func loadData() async {
        do {
            let media = try await matrixState.client.getMediaContent(mediaSource: MediaSource.fromUrl(url: mxcUrl))
            let baseImage = NSImage(data: media)
            if let baseImage {
                image = Image(nsImage: baseImage)
            }
            loaded = true
        } catch {
            print("Failed to load image from \(mxcUrl): \(error)")
        }
    }
}
