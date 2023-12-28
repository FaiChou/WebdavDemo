//
//  ContentView.swift
//  WebdavDemo
//
//  Created by FaiChou on 2023/12/22.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var model: WebDAVSetupModel
    @State private var presentedListPage: [String] = []
    @State private var showLoading = false
    @State private var showError = false
    var body: some View {
        ZStack {
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
                                print("INVALID ADDRESS")
                                return
                            }
                            showLoading = true
                            Task {
                                let webdav = WebDAV(baseURL: model.address,
                                                    port: model.port,
                                                    username: model.username,
                                                    password: model.password,
                                                    path: model.path)
                                if await webdav.ping() {
                                    showLoading = false
                                    presentedListPage = ["/"]
                                } else {
                                    showLoading = false
                                    showError = true
                                    print("Invalid configration")
                                }
                            }
                        }
                    }
                    .onChange(of: presentedListPage) { oldValue, newValue in
    //                    print(oldValue, newValue)
                    }
                }
                .navigationDestination(for: String.self) { path in
                    FileListPage(path: path)
                }
            }
            .alert(
                "Validate failed",
                isPresented: $showError
            ) { 
                Button(role: .destructive) {
                    // Handle the deletion.
                } label: {
                    Text("OK")
                }
            }
            if showLoading {
                VStack {
                    ProgressView()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.gray.opacity(0.1))
            }
        }
    }
}

#Preview {
    ContentView()
}
