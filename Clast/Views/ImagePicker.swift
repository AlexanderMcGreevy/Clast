//
//  ImagePicker.swift
//  Clast
//
//  Created by Alexander McGreevy on 11/13/25.
//

import SwiftUI
import PhotosUI

struct ImagePicker: View {
    @Binding var selectedImages: [UIImage]
    @State private var selectedItems: [PhotosPickerItem] = []
    
    let maxSelection: Int
    
    var body: some View {
        PhotosPicker(
            selection: $selectedItems,
            maxSelectionCount: maxSelection,
            matching: .images
        ) {
            HStack {
                Image(systemName: "photo.on.rectangle.angled")
                Text("Add Images")
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(.white.opacity(0.5), lineWidth: 2)
            )
        }
        .onChange(of: selectedItems) { oldValue, newValue in
            Task {
                selectedImages.removeAll()
                
                for item in newValue {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImages.append(image)
                    }
                }
            }
        }
    }
}

struct ImagePreviewGrid: View {
    let images: [UIImage]
    let onRemove: (Int) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        Button {
                            onRemove(index)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .background(
                                    Circle()
                                        .fill(.black.opacity(0.5))
                                        .frame(width: 24, height: 24)
                                )
                        }
                        .offset(x: 8, y: -8)
                    }
                }
            }
            .padding(.horizontal, 40)
        }
    }
}
