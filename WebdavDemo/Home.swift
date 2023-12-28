//
//  Home.swift
//  WebdavDemo
//
//  Created by FaiChou on 2023/12/28.
//

import SwiftUI

struct Home: View {
    @StateObject private var model = DriveListModel()
    @State private var presentedPage: [DriveModel] = []
    @State private var showAddView = false
    var body: some View {
        NavigationStack(path: $presentedPage) {
            List(model.drives, id: \.self) { item in
                NavigationLink {
//                        FileListPage()
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(item.alias)
                            Text(item.driveDetail)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        model.delete(drive: item)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    Button {
                        presentedPage = [item]
                    } label: {
                        Label("Edit", systemImage: "square.and.pencil")
                    }
                }
            }
            .navigationDestination(for: DriveModel.self) {
                DriveSetupPage(listModel: model, driveModel: $0)
            }
            .navigationTitle("Drives")
            .toolbar {
                Button {
                    showAddView = true
                } label: {
                    Image(systemName: "plus")
                        .resizable()
                        .foregroundStyle(.blue)
                }
            }
            .sheet(isPresented: $showAddView) {
                DriveSetupPage(listModel: model)
            }
        }
    }
}
