//  ImagePicker.swift
//  Memories
//
//  Created by Fadey Notchenko on 16.09.2022.
//

import Foundation
import SwiftUI
import PhotosUI
import FYVideoCompressor

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var images: [Any]
    @Binding var picker: Bool
    
    func makeCoordinator() -> Coordinator {
        ImagePicker.Coordinator(parent1: self)
    }
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        let photoLibrary = PHPhotoLibrary.shared()
        var config = PHPickerConfiguration(photoLibrary: photoLibrary)
        
        config.selectionLimit = 10 - images.count
        config.filter = .images
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        //
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        
        var parent: ImagePicker
        
        init(parent1: ImagePicker) {
            parent = parent1
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            self.parent.picker = false
            
            let identifiers = results.compactMap(\.assetIdentifier)
            let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
            
            let manager = PHImageManager.default()
            
            fetchResult.enumerateObjects { obj, i, _ in
                let size = CGSize(width: 1200, height: 1200)
                
                let option = PHImageRequestOptions()
                option.isSynchronous = true
                if obj.mediaType == .image {
                    manager.requestImage(for: obj, targetSize: size, contentMode: .aspectFit, options: option) { image, _ in
                        if let image = image {
                            self.parent.images.append(image)
                        }
                    }
                }
            }
            
        }
    }
}

