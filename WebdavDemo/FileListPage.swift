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
    @State private var webdav: WebDAV?
    var body: some View {
        List(data) { item in
            NavigationLink {
                if item.isDirectory {
                    FileListPage(path: item.path)
                } else if item.extension == "png" {
                    AsyncImageWithAuth(file: item) { image in
                        image.resizable()
                    } placeholder: {
                        Text(item.fileName)
                    }
                } else if item.extension == "mp4" {
                    VideoPlayerPage(file: item)
                } else {
                    Text(item.fileName)
                }
            } label: {
                HStack {
                    Text(item.fileName)
                    Spacer()
                    Text("\(item.size)")
                }
            }
        }
        .refreshable {
            loadData()
        }
        .navigationTitle("WebDAV")
        .onAppear {
            webdav = WebDAV(baseURL: model.address,
                                 port: model.port,
                                 username: model.username,
                                 password: model.password,
                                 path: model.path)
            loadData()
        }
    }
    private func loadData() {
        Task {
            do {
                data = try await webdav!.listFiles(atPath: path)
            } catch {
                print("error=\(error)")
            }
        }
    }
}
