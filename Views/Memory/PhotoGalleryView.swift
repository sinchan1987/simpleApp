//
//  PhotoGalleryView.swift
//  simpleApp
//
//  Created by Sinchan Roychowdhury on 11/5/25.
//

import SwiftUI

struct PhotoGalleryView: View {
    @EnvironmentObject var memoryViewModel: MemoryViewModel
    let photoURLs: [String]

    @State private var selectedPhotoIndex: Int? = nil
    @State private var showFullScreen = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Photos (\(photoURLs.count))")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(photoURLs.indices, id: \.self) { index in
                        PhotoThumbnail(url: photoURLs[index])
                            .onTapGesture {
                                selectedPhotoIndex = index
                                showFullScreen = true
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showFullScreen) {
            if let index = selectedPhotoIndex {
                FullScreenPhotoGallery(
                    photoURLs: photoURLs,
                    initialIndex: index,
                    isPresented: $showFullScreen
                )
                .environmentObject(memoryViewModel)
            }
        }
    }
}

// MARK: - Photo Thumbnail
struct PhotoThumbnail: View {
    let url: String

    var body: some View {
        AsyncImage(url: URL(string: url)) { phase in
            switch phase {
            case .empty:
                ZStack {
                    Color.gray.opacity(0.2)
                    ProgressView()
                }
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: Color.black.opacity(0.1), radius: 4, y: 2)

            case .failure:
                ZStack {
                    Color.gray.opacity(0.2)
                    VStack(spacing: 8) {
                        Image(systemName: "photo.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                        Text("Failed to load")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                }
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            @unknown default:
                EmptyView()
            }
        }
    }
}

// MARK: - Full Screen Gallery
struct FullScreenPhotoGallery: View {
    @EnvironmentObject var memoryViewModel: MemoryViewModel
    let photoURLs: [String]
    let initialIndex: Int
    @Binding var isPresented: Bool

    @State private var currentIndex: Int
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var showControls = true

    init(photoURLs: [String], initialIndex: Int, isPresented: Binding<Bool>) {
        self.photoURLs = photoURLs
        self.initialIndex = initialIndex
        self._isPresented = isPresented
        self._currentIndex = State(initialValue: initialIndex)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Photo viewer with swipe gesture
            TabView(selection: $currentIndex) {
                ForEach(photoURLs.indices, id: \.self) { index in
                    GeometryReader { geometry in
                        ZoomablePhotoView(url: photoURLs[index])
                            .frame(width: geometry.size.width, height: geometry.size.height)
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            // Top controls
            VStack {
                HStack {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.5))
                            )
                    }

                    Spacer()

                    Text("\(currentIndex + 1) / \(photoURLs.count)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.5))
                        )
                }
                .padding()

                Spacer()
            }
            .opacity(showControls ? 1 : 0)
            .animation(.easeInOut(duration: 0.2), value: showControls)

            // Bottom thumbnail strip
            if showControls {
                VStack {
                    Spacer()

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(photoURLs.indices, id: \.self) { index in
                                ThumbnailPreview(url: photoURLs[index], isSelected: index == currentIndex)
                                    .onTapGesture {
                                        currentIndex = index
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 12)
                    .background(
                        Rectangle()
                            .fill(Color.black.opacity(0.5))
                            .ignoresSafeArea(edges: .bottom)
                    )
                }
                .transition(.move(edge: .bottom))
            }
        }
        .statusBar(hidden: !showControls)
        .onTapGesture {
            withAnimation {
                showControls.toggle()
            }
        }
    }
}

// MARK: - Zoomable Photo View
struct ZoomablePhotoView: View {
    let url: String

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geometry in
            AsyncImage(url: URL(string: url)) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        Color.black
                        ProgressView()
                            .tint(.white)
                    }

                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastScale
                                    lastScale = value
                                    scale = min(max(scale * delta, 1), 5)
                                }
                                .onEnded { _ in
                                    lastScale = 1.0
                                    if scale < 1 {
                                        withAnimation(.spring()) {
                                            scale = 1
                                            offset = .zero
                                        }
                                    }
                                }
                        )
                        .simultaneousGesture(
                            DragGesture()
                                .onChanged { value in
                                    if scale > 1 {
                                        offset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                        .onTapGesture(count: 2) {
                            withAnimation(.spring()) {
                                if scale > 1 {
                                    scale = 1
                                    offset = .zero
                                    lastOffset = .zero
                                } else {
                                    scale = 2
                                }
                            }
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }

                case .failure:
                    ZStack {
                        Color.black
                        VStack(spacing: 16) {
                            Image(systemName: "photo.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.white.opacity(0.5))
                            Text("Failed to load image")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }

                @unknown default:
                    Color.black
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

// MARK: - Thumbnail Preview
struct ThumbnailPreview: View {
    let url: String
    let isSelected: Bool

    var body: some View {
        AsyncImage(url: URL(string: url)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
                    )
                    .opacity(isSelected ? 1.0 : 0.6)

            case .empty:
                ZStack {
                    Color.gray.opacity(0.3)
                    ProgressView()
                        .tint(.white)
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            case .failure:
                ZStack {
                    Color.gray.opacity(0.3)
                    Image(systemName: "photo.fill")
                        .foregroundColor(.white.opacity(0.5))
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            @unknown default:
                EmptyView()
            }
        }
    }
}

#Preview {
    PhotoGalleryView(photoURLs: [
        "https://picsum.photos/400/400",
        "https://picsum.photos/400/401",
        "https://picsum.photos/400/402"
    ])
    .environmentObject(MemoryViewModel())
}
