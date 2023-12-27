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
                        TextField("Name", text: $model.name)
                        TextField("http[s]://192.168.11.199", text: $model.address)
                        TextField("Username", text: $model.username)
                        SecureField("Password", text: $model.password)
                    }
                    Section(header: Text("Advanced")) {
                        #if os(macOS)
                        TextField("Port", value: $model.port, formatter: NumberFormatter())
                        #else
                        TextField("Port", value: $model.port, formatter: NumberFormatter())
                            .keyboardType(.numberPad)
                        #endif
                        TextField("Path, eg: /subfolder", text: $model.path)
                    }
                    Button("Submit") {
                        guard !model.address.isEmpty else {
                            return
                        }
                        presentedListPage = [1]
                        WebDAV(baseURL: model.address,
                                            port: model.port,
                                            username: model.username,
                                            password: model.password,
                                            path: model.path).listFiles(atPath: "/") { files, error in
                            print(files)
                        }
                    }
                }
                .onChange(of: presentedListPage) { oldValue, newValue in
//                    print(oldValue, newValue)
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
