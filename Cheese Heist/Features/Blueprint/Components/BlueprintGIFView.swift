//
//  BlueprintGIFView.swift
//  Cheese Heist
//
//  Plays a bundled GIF via a transparent, non-scrolling `WKWebView` — ported from the
//  reference build (`cheezy-dev-nay`'s `GIFImageView`). `updateUIView` reloads the HTML
//  on every `gifName` change; a plain `UIImageView.animatedImage` assigned once in
//  `makeUIView` misses exactly this, which is why every blueprint step showed the first
//  step's clip.
//

import SwiftUI
import WebKit

struct BlueprintGIFView: UIViewRepresentable {

    let gifName: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard let url = Bundle.main.url(forResource: gifName, withExtension: "gif") else { return }

        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body, html {
                    margin: 0;
                    padding: 0;
                    width: 100%;
                    height: 100%;
                    overflow: hidden;
                    background-color: transparent;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                }
                img {
                    max-width: 100%;
                    max-height: 100%;
                    object-fit: contain;
                }
            </style>
        </head>
        <body>
            <img src="\(url.lastPathComponent)">
        </body>
        </html>
        """
        uiView.loadHTMLString(html, baseURL: url.deletingLastPathComponent())
    }
}

#Preview {
    BlueprintGIFView(gifName: "blueprint_step_1")
        .frame(width: 400, height: 300)
        .previewBackdrop(.parchment)
}
