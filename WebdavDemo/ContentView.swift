//
//  ContentView.swift
//  WebdavDemo
//
//  Created by FaiChou on 2023/12/22.
//

import SwiftUI

struct ContentView: View {
    @StateObject var model = WebDAVSetupModel()
    @State private var presentedListPage: [Int] = []
    var body: some View {
        NavigationStack(path: $presentedListPage) {
            NavigationView {
                Form {
                    Section(header: Text("Basic")) {
                        Picker("Protocol", selection: $model.webdavProtocol) {
                            Text("WebDAV").tag(WebDAVProtocol.HTTP)
                            Text("WebDAV(HTTPS)").tag(WebDAVProtocol.HTTPS)
                        }
                        TextField("Name", text: $model.name)
                        TextField("192.168.11.199", text: $model.address)
                        TextField("Username", text: $model.username)
                        SecureField("Password", text: $model.password)
                    }
                    Section(header: Text("Advanced")) {
                        TextField("Port", value: $model.port, formatter: NumberFormatter())
                            .keyboardType(.numberPad)
                        TextField("Path, eg: /subfolder", text: $model.path)
                    }
                    Button("Submit") {
                        presentedListPage = [1]
                    }
                }
                .onChange(of: model.webdavProtocol) { _, newValue in
                    switch newValue {
                    case .HTTP:
                        model.port = 80
                    case .HTTPS:
                        model.port = 443
                    }
                }
                .onChange(of: presentedListPage) { oldValue, newValue in
                    print(oldValue, newValue)
                }
            }
            .navigationDestination(for: Int.self) { _ in
                FileListPage()
            }
        }
    }
}

#Preview {
    ContentView()
}
