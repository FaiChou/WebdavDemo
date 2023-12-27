//
//  WebDAV.swift
//  WebDAV-Swift
//
//  Created by Isaac Lyons on 10/29/20.
//

import UIKit
import SWXMLHash

public class WebDAV: NSObject, URLSessionDelegate {
    var baseURL: URL
    var auth: String
    init(baseURL: String, port: Int, username: String? = nil, password: String? = nil, path: String? = nil) {
        let processedBaseURL: String
        if baseURL.hasPrefix("http://") || baseURL.hasPrefix("https://") {
            processedBaseURL = baseURL
        } else {
            processedBaseURL = "http://" + baseURL
        }
        let trimmedBaseURL = processedBaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        var fullURLString = trimmedBaseURL
        if port != 80 && port != 443 {
            fullURLString += ":\(port)"
        }
        if let path, !path.isEmpty {
            let slashPrefixedPath = path.hasPrefix("/") ? path : "/\(path)"
            fullURLString += slashPrefixedPath
        }
        self.baseURL = URL(string: fullURLString)!
        let authString = (username ?? "") + ":" + (password ?? "")
        let authData = authString.data(using: .utf8)
        self.auth = authData?.base64EncodedString() ?? ""
    }
    public static func sortedFiles(_ files: [WebDAVFile], foldersFirst: Bool, includeSelf: Bool) -> [WebDAVFile] {
        var files = files
        if !includeSelf, !files.isEmpty {
            files.removeFirst()
        }
        if foldersFirst {
            files = files.filter { $0.isDirectory } + files.filter { !$0.isDirectory }
        }
        return files
    }
}

//MARK: Public

public extension WebDAV {
    @discardableResult
    func listFiles(atPath path: String, foldersFirst: Bool = true, includeSelf: Bool = false, completion: @escaping (_ files: [WebDAVFile]?, _ error: WebDAVError?) -> Void) -> URLSessionDataTask? {
        guard var request = authorizedRequest(path: path, method: .propfind) else {
            completion(nil, .invalidCredentials)
            return nil
        }

        let body =
"""
<?xml version="1.0"?>
<D:propfind xmlns:D="DAV:">
    <D:prop>
        <D:getcontentlength/>
        <D:getlastmodified/>
        <D:getcontenttype />
        <D:resourcetype/>
    </D:prop>
</D:propfind>
"""
        request.httpBody = body.data(using: .utf8)
        let task = URLSession(configuration: .ephemeral, delegate: self, delegateQueue: nil).dataTask(with: request) { [weak self] data, response, error in
            let error = WebDAVError.getError(response: response, error: error)
            // Check the response
            let response = response as? HTTPURLResponse
            guard 200...299 ~= response?.statusCode ?? 0,
                  let data = data,
                  let string = String(data: data, encoding: .utf8) else {
                return completion(nil, error)
            }
            // Create WebDAVFiles from the XML response
            let xml = XMLHash.config { config in
                config.shouldProcessNamespaces = true
            }.parse(string)
//            print(xml)
            let files = xml["multistatus"]["response"].all.compactMap { WebDAVFile(xml: $0, baseURL: self!.baseURL.absoluteString) }
            let sortedFiles = WebDAV.sortedFiles(files, foldersFirst: foldersFirst, includeSelf: includeSelf)
            completion(sortedFiles, error)
        }
        task.resume()
        return task
    }
    
    /// Upload data to the specified file path.
    /// - Parameters:
    ///   - data: The data of the file to upload.
    ///   - path: The path, including file name and extension, to upload the file to.
    ///   - account: The WebDAV account.
    ///   - password: The WebDAV account's password.
    ///   - completion: If account properties are invalid, this will run immediately on the same thread.
    ///   Otherwise, it runs when the network call finishes on a background thread.
    ///   - error: A WebDAVError if the call was unsuccessful. `nil` if it was.
    /// - Returns: The upload task for the request.
    @discardableResult
    func upload(data: Data, toPath path: String, completion: @escaping (_ error: WebDAVError?) -> Void) -> URLSessionUploadTask? {
        guard let request = authorizedRequest(path: path, method: .put) else {
            completion(.invalidCredentials)
            return nil
        }
        let task = URLSession(configuration: .ephemeral, delegate: self, delegateQueue: nil).uploadTask(with: request, from: data) { _, response, error in
            completion(WebDAVError.getError(response: response, error: error))
        }
        
        task.resume()
        return task
    }
    /// Upload a file to the specified file path.
    /// - Parameters:
    ///   - file: The path to the file to upload.
    ///   - path: The path, including file name and extension, to upload the file to.
    ///   - account: The WebDAV account.
    ///   - password: The WebDAV account's password.
    ///   - completion: If account properties are invalid, this will run immediately on the same thread.
    ///   Otherwise, it runs when the network call finishes on a background thread.
    ///   - error: A WebDAVError if the call was unsuccessful. `nil` if it was.
    /// - Returns: The upload task for the request.
    @discardableResult
    func upload(file: URL, toPath path: String, completion: @escaping (_ error: WebDAVError?) -> Void) -> URLSessionUploadTask? {
        guard let request = authorizedRequest(path: path, method: .put) else {
            completion(.invalidCredentials)
            return nil
        }
        
        let task = URLSession(configuration: .ephemeral, delegate: self, delegateQueue: nil).uploadTask(with: request, fromFile: file) { _, response, error in
            completion(WebDAVError.getError(response: response, error: error))
        }
        
        task.resume()
        return task
    }
    
    /// Create a folder at the specified path
    /// - Parameters:
    ///   - path: The path to create a folder at.
    ///   - account: The WebDAV account.
    ///   - password: The WebDAV account's password.
    ///   - completion: If account properties are invalid, this will run immediately on the same thread.
    ///   Otherwise, it runs when the network call finishes on a background thread.
    ///   - error: A WebDAVError if the call was unsuccessful. `nil` if it was.
    /// - Returns: The data task for the request.
    @discardableResult
    func createFolder(atPath path: String, completion: @escaping (_ error: WebDAVError?) -> Void) -> URLSessionDataTask? {
        basicDataTask(path: path, method: .mkcol, completion: completion)
    }
    
    /// Delete the file or folder at the specified path.
    /// - Parameters:
    ///   - path: The path of the file or folder to delete.
    ///   - account: The WebDAV account.
    ///   - password: The WebDAV account's password.
    ///   - completion: If account properties are invalid, this will run immediately on the same thread.
    ///   Otherwise, it runs when the network call finishes on a background thread.
    ///   - error: A WebDAVError if the call was unsuccessful. `nil` if it was.
    /// - Returns: The data task for the request.
    @discardableResult
    func deleteFile(atPath path: String, completion: @escaping (_ error: WebDAVError?) -> Void) -> URLSessionDataTask? {
        basicDataTask(path: path, method: .delete, completion: completion)
    }
    
    /// Move the file to the specified destination.
    /// - Parameters:
    ///   - path: The original path of the file.
    ///   - destination: The desired destination path of the file.
    ///   - account: The WebDAV account.
    ///   - password: The WebDAV account's password.
    ///   - completion: If account properties are invalid, this will run immediately on the same thread.
    ///   Otherwise, it runs when the network call finishes on a background thread.
    ///   - error: A WebDAVError if the call was unsuccessful. `nil` if it was.
    /// - Returns: The data task for the request.
    @discardableResult
    func moveFile(fromPath path: String, to destination: String, completion: @escaping (_ error: WebDAVError?) -> Void) -> URLSessionDataTask? {
        basicDataTask(path: path, destination: destination, method: .move, completion: completion)
    }
    
    /// Copy the file to the specified destination.
    /// - Parameters:
    ///   - path: The original path of the file.
    ///   - destination: The desired destination path of the copy.
    ///   - account: The WebDAV account.
    ///   - password: The WebDAV account's password.
    ///   - completion: If account properties are invalid, this will run immediately on the same thread.
    ///   Otherwise, it runs when the network call finishes on a background thread.
    ///   - error: A WebDAVError if the call was unsuccessful. `nil` if it was.
    /// - Returns: The data task for the request.
    @discardableResult
    func copyFile(fromPath path: String, to destination: String, completion: @escaping (_ error: WebDAVError?) -> Void) -> URLSessionDataTask? {
        basicDataTask(path: path, destination: destination, method: .copy, completion: completion)
    }
}

//MARK: Internal

extension WebDAV {
    /// Creates an authorized URL request at the path and with the HTTP method specified.
    /// - Parameters:
    ///   - path: The path of the request
    ///   - account: The WebDAV account
    ///   - method: The HTTP Method for the request.
    /// - Returns: The URL request if the credentials are valid (can be encoded as UTF-8).
    func authorizedRequest(path: String, method: HTTPMethod) -> URLRequest? {
        let url = self.baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.addValue("Basic \(self.auth)", forHTTPHeaderField: "Authorization")
        return request
    }

    func basicDataTask(path: String, destination: String? = nil, method: HTTPMethod, completion: @escaping (_ error: WebDAVError?) -> Void) -> URLSessionDataTask? {
        guard var request = authorizedRequest(path: path, method: method) else {
            completion(.invalidCredentials)
            return nil
        }
        if let destination = destination {
            let destionationURL = self.baseURL.appendingPathComponent(destination)
            request.addValue(destionationURL.absoluteString, forHTTPHeaderField: "Destination")
        }
        let task = URLSession(configuration: .ephemeral, delegate: self, delegateQueue: nil).dataTask(with: request) { data, response, error in
            completion(WebDAVError.getError(response: response, error: error))
        }
        task.resume()
        return task
    }
}
