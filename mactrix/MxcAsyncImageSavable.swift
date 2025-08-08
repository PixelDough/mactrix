//
//  MxcAsyncImageSavable.swift
//  mactrix
//
//  Created by Annie Worrell on 8/8/25.
//

import SwiftUI
internal import UniformTypeIdentifiers

struct MxcAsyncImageSavable<Content: View, Placeholder: View> : View {
    @Environment(MatrixState.self) private var matrixState: MatrixState
    var mxcUrl: String?
    @ViewBuilder var content: (Image) -> Content
    @ViewBuilder var placeholder: () -> Placeholder

    @State var showFileExporter: Bool = false

    var body: some View {
        MxcAsyncImage(mxcUrl: mxcUrl) { image in
            content(image)
                .fileExporter(isPresented: $showFileExporter, item: image, contentTypes: [.image], defaultFilename: "image.png", onCompletion: { result in
                    switch result {
                    case .success(let url):
                        print("Saved file to \(url)")
                    case .failure(let error):
                        print("Failed to save file: \(error)")
                    }
                }, onCancellation: {
                    print("Save cancelled")
                })
                .contextMenu {
                    Button {
                        showFileExporter = true
                        print("Save file!")
                    } label: {
                        Label("Save Image", systemImage: "square.and.arrow.down")
                    }
                    ShareLink(item: image, preview: SharePreview("Image", image: image))
                }
                .onChange(of: showFileExporter) { oldValue, newValue in
                    print("SHOW FILE EXPORTER: \(newValue)")
                }
        } placeholder: {
            placeholder()
        }
    }
}
