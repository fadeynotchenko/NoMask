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

struct Avatar: View {
    
    let avatarType: AvatarImageType
    let size: CGSize
    
    var body: some View {
        switch avatarType {
        case .url(let url):
            KFImage(url)
                .loadDiskFileSynchronously()
                .resizable()
                .placeholder {
                    ProgressView()
                        .frame(width: size.width, height: size.height)
                        .background(Color("Background"))
                        .clipShape(Circle())
                        .shadow(radius: 3)
                }
                .scaledToFill()
                .frame(width: size.width, height: size.height)
                .background(Color("Background"))
                .clipShape(Circle())
                .foregroundColor(.white)
                .shadow(radius: 3)
        case .image(let image):
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: size.width, height: size.height)
                .clipShape(Circle())
                .shadow(radius: 3)
        case .empty:
            Image(systemName: "questionmark")
                .resizable()
                .scaledToFit()
                .scaleEffect(0.6)
                .foregroundColor(.gray)
                .frame(width: size.width, height: size.height)
                .background(Color("Background"))
                .clipShape(Circle())
                .shadow(radius: 3)
        }
        
    }
}

struct ImageItem: View {
    let url: URL
    let size: CGSize
    
    var body: some View {
        KFImage(url)
            .cacheMemoryOnly()
            .resizable()
            .placeholder {
                ProgressView()
                    .font(.system(size: 24))
                    .frame(width: size.width, height: size.height)
                    .background(.ultraThickMaterial)
                    .shadow(radius: 3)
            }
            .scaledToFill()
            .frame(width: size.width, height: size.height)
            .shadow(radius: 3)
            .clipped()
            .transition(.identity)
    }
}

struct Chevron: View {
    var body: some View {
        Image(systemName: "chevron.right")
            .foregroundColor(.gray)
    }
}

struct RoundedCorner: Shape {

    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

struct Permission: View {
    
    let text: LocalizedStringKey
    
    var body: some View {
        VStack(spacing: 15) {
            Text(text)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Перейти в настройки") {
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }
        }
        .edgesIgnoringSafeArea(.all)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThickMaterial)
    }
}

struct Download: View {
    var body: some View {
        ProgressView()
            .shadow(radius: 3)
            .padding()
            .background(.ultraThickMaterial)
            .cornerRadius(15)
    }
}

struct NicknameTF: View {
    @Binding var nickname: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Title(text: "nickname", font: .headline)
            
            VStack {
                TextField("nickname", text: $nickname)
                    .onChange(of: nickname) { _ in
                        nickname = String(nickname.prefix(Constants.nicknameLimit))
                        }
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.gray)
            }
            .shadow(radius: 3)
            .overlay(alignment: .trailing) {
                Text("\(nickname.count)/\(Constants.nicknameLimit)")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
        .padding()
    }
}

