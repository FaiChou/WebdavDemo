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
                            print("INVALID ADDRESS")
                            return
                        }
                        presentedListPage = ["/"]
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
    }
}

#Preview {
    ContentView()
}
