//
//  WebDAVSetupModel.swift
//  WebdavDemo
//
//  Created by FaiChou on 2023/12/23.
//

import Foundation
import SwiftUI

enum WebDAVProtocol: String, CaseIterable, Identifiable {
    case HTTP
    case HTTPS
    var id: Self { self }
}

class WebDAVSetupModel: ObservableObject {
    @AppStorage("webdav-setup-model-name") var name: String = "My WebDAV"
    @AppStorage("webdav-setup-model-protocol") var webdavProtocol: WebDAVProtocol = .HTTP
    @AppStorage("webdav-setup-model-address") var address: String = ""
    @AppStorage("webdav-setup-model-username") var username: String = ""
    @AppStorage("webdav-setup-model-password") var password: String = ""
    @AppStorage("webdav-setup-model-port") var port: Int = 80
    @AppStorage("webdav-setup-model-path") var path: String = ""
}
