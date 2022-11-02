//
//  Title.swift
//  Memories
//
//  Created by Fadey Notchenko on 03.10.2022.
//

import SwiftUI
import AVKit
import Kingfisher

struct Title: View {
    let text: LocalizedStringKey
    var font: Font?
    
    var body: some View {
        Text(text)
            .bold()
            .font(font != nil ? font! : .title2)
            .foregroundColor(.white)
            .shadow(radius: 3)
    }
}

struct TextButton: View {
    let text: LocalizedStringKey
    let size: CGFloat
    let color: Color
    let action: () -> ()
    
    var body: some View {
        Button {
            action()
        } label: {
            Text(text)
                .bold()
                .font(.title3)
                .foregroundColor(color)
                .padding()
                .frame(width: size)
                .background(.ultraThickMaterial)
                .cornerRadius(15)
                .shadow(radius: 3)
        }
    }
}

struct ImageButton: View {
    var systemName: String
    var color: Color
    var size: CGFloat?
    var action: () -> ()
    
    var body: some View {
        Button {
            action()
        } label: {
            Image(systemName: systemName)
                .resizable()
                .scaledToFit()
                .padding(10)
                .frame(width: size != nil ? size! : 35, height: size != nil ? size! : 35)
                .foregroundColor(color)
                .background(.ultraThickMaterial)
                .clipShape(Circle())
                .shadow(radius: 3)
        }
    }
}

struct AddMediaButton: View {
    let width: CGFloat
    let action: () -> ()
    
    var body: some View {
        Button {
            action()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 30))
                .foregroundColor(.blue)
                .frame(width: width, height: width)
                .background(.ultraThickMaterial)
                .cornerRadius(15)
                .shadow(radius: 3)
        }
    }
}

struct ImageItem: View {
    let type: ImageItemType
    let size: CGFloat
    
    var body: some View {
        switch type {
            
        case .image(let image):
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .cornerRadius(15)
                .clipped()
                .shadow(radius: 3)
            
        case .url(let url):
            KFImage(url)
                .loadDiskFileSynchronously()
                .resizable()
                .placeholder {
                    ProgressView()
                        .font(.system(size: 24))
                        .frame(width: size, height: size)
                        .background(.ultraThickMaterial)
                        .cornerRadius(15)
                        .shadow(radius: 3)
                }
                .scaledToFill()
                .frame(width: size, height: size)
                .cornerRadius(15)
                .shadow(radius: 3)
                .clipped()
                .transition(.identity)
        }
    }
}

struct Header<Content: View>: View {
    
    let text: LocalizedStringKey
    let menu: Content
    
    init(text: LocalizedStringKey, @ViewBuilder menu: @escaping () -> Content) {
        self.text = text
        self.menu = menu()
    }
    
    var body: some View {
        VStack {
            HStack {
                Title(text: text)
                
                Spacer()
                
                menu
            }
        }
        .padding()
    }
}
