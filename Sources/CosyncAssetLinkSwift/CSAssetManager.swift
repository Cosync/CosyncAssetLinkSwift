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
    
    
    // This function will return an option array of CSRefreshAssetResult
    // You can request multiple asset at once by using comma separator in assetId eg: assetId1,assetId2
    @MainActor
    public func refreshAsset(assetId: String) async throws -> [CSRefreshAssetResult]? {
        
        var assetResult = [CSRefreshAssetResult]()
   
        let result = try await self.app.currentUser!.functions.CosyncRefreshAsset([AnyBSON(assetId)])
        
        if result == false{
            return nil
        }
        
        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        //ISO8601 UTC
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        decoder.dataDecodingStrategy = .base64
        
        do {
            if let stringValue = result.stringValue {
                assetResult = try decoder.decode([CSRefreshAssetResult].self, from: Data(stringValue.utf8))
            }
        } catch {
            print("refreshAsset error \(error.localizedDescription)")
            return nil
        }
        
        return assetResult
    }
    
    
    // This function will return Realm result of CosyncAsset that belong to the requested user
    @MainActor
    public func getUserAssets(userId: String) async throws -> Results<CosyncAsset> {
        return realm!.objects(CosyncAsset.self).filter("userId = '\(userId)'")
    }
    
    // This function will return Realm result of CosyncAsset
    @MainActor
    public func getAssets(assetIds: [ObjectId]) async throws -> Results<CosyncAsset> {
        return realm!.objects(CosyncAsset.self).filter("_id IN  %@", assetIds)
    }
    
    
    // This function will update a status of CosyncAsset
    @MainActor
    public func updateAssetStatus(assetId: ObjectId, status:String) async throws {
        if let asset = realm!.objects(CosyncAsset.self).filter("_id = %@", assetId).first {
            try! realm!.write {
                asset.status = status
                asset.updatedAt = Date()
            }
        }
    }
    
    // This function will delete a CosyncAsset
    @MainActor
    public func deleteAssets(assetIds: [ObjectId]) async throws {
        let assets = realm!.objects(CosyncAsset.self).filter("_id IN  %@", assetIds)
        try! realm!.write {
            realm.delete(assets)
        }
        
    }
    
    // This function will update status to 'deleted' for all CosyncAsset that belong to the reqeusted user
    // The server will handle the assets deletion
    @MainActor
    public func deleteUserAssets(userId: String) async throws {
        let assets = realm!.objects(CosyncAsset.self).filter("userId = '\(userId)'")
        try! realm!.write {
            assets.setValue("deleted", forKey: "status")
        }
    }
    
    
    // This function will return an amount total storage usage in bytes of the reqeusted user
    @MainActor
    public func getUserStorageUsed(userId: String) async throws -> Int {
        return try await self.app.currentUser!.functions.CosyncCountUserS3Directory([AnyBSON("")]).asInt() ?? 0
    }
    
    
}
