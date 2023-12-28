//
//  CSAssetManager.swift
//
//  Licensed to the Apache Software Foundation (ASF) under one
//  or more contributor license agreements.  See the NOTICE file
//  distributed with this work for additional information
//  regarding copyright ownership.  The ASF licenses this file
//  to you under the Apache License, Version 2.0 (the
//  "License"); you may not use this file except in compliance
//  with the License.  You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing,
//  software distributed under the License is distributed on an
//  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
//  KIND, either express or implied.  See the License for the
//  specific language governing permissions and limitations
//  under the License.
//
//  Created by Tola Voeung on 12/28/23.
//  Copyright © 2020 cosync. All rights reserved.
//

import Foundation
import RealmSwift

@available(macOS 10.15, *)
public class CSAssetManager: NSObject {
    
    public static var shared = CSAssetManager()
    private var realm: Realm!
    private var app: App!
    private var userId: String!
    
    // Start the asset manager.
    // Must be called upon first access of the sigleton
    @MainActor
    public func configure(app: App, realm: Realm) {
        
        self.app = app
        self.realm = realm
    }
    
    @MainActor
    public func getUserAssets(userId: String) async throws -> Results<CosyncAsset> {
        return realm!.objects(CosyncAsset.self).filter("userId = '\(userId)'")
    }
    
    @MainActor
    public func getAssets(assetIds: [ObjectId]) async throws -> Results<CosyncAsset> {
        return realm!.objects(CosyncAsset.self).filter("_id IN  %@", assetIds)
    }
    
    @MainActor
    public func updateAssetStatus(assetId: ObjectId, status:String) async throws {
        if let asset = realm!.objects(CosyncAsset.self).filter("_id = %@", assetId).first {
            try! realm!.write {
                asset.status = status
                asset.updatedAt = Date()
            }
        }
    }
    
    @MainActor
    public func deleteAssets(assetIds: [ObjectId]) async throws {
        let assets = realm!.objects(CosyncAsset.self).filter("_id IN  %@", assetIds)
        try! realm!.write {
            realm.delete(assets)
        }
        
    }
    
    @MainActor
    public func deleteUserAssets(userId: String) async throws {
        let assets = realm!.objects(CosyncAsset.self).filter("userId = '\(userId)'")
        try! realm!.write {
            realm.delete(assets)
        }
    }
    
    
}
