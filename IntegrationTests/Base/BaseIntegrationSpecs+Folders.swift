//
//  BaseIntegrationSpecs+Folders.swift
//  BoxSDKIntegrationTests-iOS
//
//  Created by Artur Jankowski on 14/10/2022.
//  Copyright © 2022 box. All rights reserved.
//

@testable import BoxSDK
import Nimble
import Quick

extension BaseIntegrationSpecs {

    func createFolder(name: String, parentId: String = "0", callback: @escaping (Folder) -> Void) {
        waitUntil(timeout: .seconds(Constants.Timeout.default)) { done in
            self.client.folders.create(name: name, parentId: parentId) { result in
                switch result {
                case let .success(folder):
                    callback(folder)
                case let .failure(error):
                    fail("Expected create call to suceeded, but instead got \(error)")
                }

                done()
            }
        }
    }

    func deleteFolder(_ folder: Folder?, recursive: Bool = false) {
        guard let folder = folder else {
            return
        }

        waitUntil(timeout: .seconds(Constants.Timeout.default)) { done in
            self.client.folders.delete(folderId: folder.id, recursive: recursive) { result in
                if case let .failure(error) = result {
                    fail("Expected delete call to succeed, but instead got \(error)")
                }

                done()
            }
        }
    }
}
