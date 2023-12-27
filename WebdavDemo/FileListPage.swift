//
//  FileListPage.swift
//  WebdavDemo
//
//  Created by FaiChou on 2023/12/23.
//

import Foundation
import SwiftUI

struct FileListPage: View {
    @EnvironmentObject var model: WebDAVSetupModel
    let path: String
    @State private var data: [WebDAVFile] = []
    var body: some View {
        NavigationView {
             List(data) { item in
                 HStack {
                     Text(item.path)
                     Spacer()
                 }
             }
             .refreshable {
                 loadData()
             }
             .navigationTitle("WebDAV")
         }
        .onAppear {
            loadData()
        }
    }
    private func loadData() {
        Task {
            let w = WebDAV(baseURL: model.address,
                   port: model.port,
                   username: model.username,
                   password: model.password,
                   path: model.path)
            do {
                data = try await w.listFiles(atPath: path)
            } catch {
                print("error=\(error)")
            }
        }
    }
}
