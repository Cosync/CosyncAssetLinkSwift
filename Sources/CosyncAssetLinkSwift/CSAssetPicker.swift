//
//  CSAssetPicker.swift
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
//  Created by Tola Voeung on 3/19/23.
//  Copyright © 2020 cosync. All rights reserved.
//

import Foundation
import PhotosUI
import SwiftUI



public struct AssetPickerResult {
    
    public var success: Bool = true
    public var error: String = ""
    public var assetId: String = ""
    public var assetType: String = ""
    public var data: Any // as UIImage or URL
}

public typealias AssetPickerCallback = (_ result: AssetPickerResult) -> Void

@available(iOS 15, *)
public struct AssetPicker: UIViewControllerRepresentable {
    
    @Binding var isPresented: Bool
    var preferredType:String = "all"
    var isMultipleSelection:Bool = false
    var onPicked: AssetPickerCallback
     
    public init(isPresented:Binding<Bool>,
                preferredType:String,
                isMultipleSelection:Bool,
                onPicked: @escaping AssetPickerCallback) {
        self._isPresented = isPresented
        self.preferredType = preferredType
        self.isMultipleSelection = isMultipleSelection
        self.onPicked = onPicked
    }
    
    
    public func makeUIViewController(context: Context) -> PHPickerViewController {
         
        var config = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
        
        if(preferredType == "image"){
            config.filter = .any(of: [.images])
        }
        else if(preferredType == "video"){
            config.filter = .all(of: [.videos])
             
        }
        else {
            config.filter = .any(of: [.images, .videos])
        }
        
        
        config.selectionLimit = isMultipleSelection ? 0 : 1 //0 => any, set 1-2-3 for hard limit
        
        config.preferredAssetRepresentationMode = .current
        config.selection = .ordered
        
        let controller = PHPickerViewController(configuration: config)
        controller.delegate = context.coordinator
        return controller
    }
    
     
    public func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) { }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public func onPickedAsset(pickedAsset: PHPickerResult) {
        
        let provider = pickedAsset.itemProvider
        var result = AssetPickerResult(success: false, error: "", assetId: "", assetType: "", data: "")
        
        if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
            let progress:Progress = provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { fileURL, err in
                do {
                    if let url = fileURL {
                        let fm = FileManager.default
                        let filename = url.lastPathComponent
                        let destination = fm.temporaryDirectory.appendingPathComponent(filename)
                        if fm.fileExists(atPath: destination.path) {
                            try fm.removeItem(at: destination)
                        }
                        
                        try fm.copyItem(at: url, to: destination)
                        result = AssetPickerResult(success: true, error: "", assetId: pickedAsset.assetIdentifier ?? "", assetType: "video", data: destination)
                        
                        self.onPicked(result)
                    }
                    else {
                        result.error = "Unable to load video"
                        self.onPicked(result)
                    }
                }
                catch {
                    result.error = "Unable to load video"
                    self.onPicked(result)
                }
            }
            
            print("load progress \(String(describing: progress.estimatedTimeRemaining))")
        }
        else if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            if provider.canLoadObject(ofClass: UIImage.self) {
                
                provider.loadObject(ofClass: UIImage.self, completionHandler: { (object, error) in
                     
                    if let err = error {
                        result.error  = err.localizedDescription
                    }
                    else if let image = object as? UIImage {
                        result = AssetPickerResult(success: true, error: "", assetId: pickedAsset.assetIdentifier ?? "", assetType: "image", data: image)
                        self.onPicked(result)
                    }
                })
                
            }
            else {
                result.error  = "Can not load this image."
                self.onPicked(result)
            }
        }
        else {
            result.error = "Unsupported type"
            self.onPicked(result)
        }
    }
    
    /// PHPickerViewControllerDelegate => Coordinator
    public class Coordinator: PHPickerViewControllerDelegate {
        
        private var parent: AssetPicker
        
        init(_ parent: AssetPicker) {
            self.parent = parent
        }
        
            
        public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            
            picker.dismiss(animated: true, completion: nil)
            
            for result in results {
                parent.onPickedAsset(pickedAsset: result)
            }
            
            // dissmiss the picker
            parent.isPresented = false
        }
    }
}
