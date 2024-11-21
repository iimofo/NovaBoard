//
//  NovaBoardApp.swift
//  NovaBoard
//
//  Created by Mofo on 14/09/2024.
//

import SwiftUI

@main
struct NovaBoardApp: App {
    @StateObject private var clipboardManager = ClipboardManager()

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(clipboardManager)
        } label: {
            Image(systemName: "doc.on.doc")
        }
        .menuBarExtraStyle(.window)
    }
}
