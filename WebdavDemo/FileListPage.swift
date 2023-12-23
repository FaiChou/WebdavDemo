//
//  FileListPage.swift
//  WebdavDemo
//
//  Created by FaiChou on 2023/12/23.
//

import Foundation
import SwiftUI

struct FileListPage: View {
    var body: some View {
        VStack {
            Text("file list")
            NavigationLink("next page") {
                Text("next page!!")
            }
        }
    }
}
