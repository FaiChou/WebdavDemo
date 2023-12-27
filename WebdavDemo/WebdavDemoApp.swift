//
//  WebdavDemoApp.swift
//  WebdavDemo
//
//  Created by FaiChou on 2023/12/22.
//

import SwiftUI

@main
struct WebdavDemoApp: App {
    @StateObject private var model = WebDAVSetupModel()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
        }
    }
}
