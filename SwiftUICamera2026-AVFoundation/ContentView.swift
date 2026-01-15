//
    // Project: SwiftUICamera2026-AVFoundation
    //  File: ContentView.swift
//  Created by Noah Carpenter
//  🐱 Follow me on YouTube! 🎥
//  https://www.youtube.com/@NoahDoesCoding97
//  Like and Subscribe for coding tutorials and fun! 💻✨
//  Fun Fact: Cats have five toes on their front paws, but only four on their back paws! 🐾
//  Dream Big, Code Bigger

    

import SwiftUI
import AVFoundation
import AVKit

enum CaptureMode {
    case photo, video
}

struct ContentView: View {
    
    private var flashIcon: String {
        switch cameraManager.flashMode {
        case .off: return "bolt.slash.fill"
        case .on: return "bolt.fill"
        case .auto: return "bolt.badge.automatic.fill"
        @unknown default: return "bolt.slash.fill"
        }
    }
    
    @StateObject private var cameraManager = CameraManager()
    @State private var captureMode: CaptureMode = .photo
    
    var body: some View {
        ZStack {
            // Camera preview fills entire screen
            if cameraManager.authorizationStatus == .authorized {
                CameraPreview(session: cameraManager.session, cameraManager: cameraManager)
                    .ignoresSafeArea()
            } else {
                // Permission not granted
                VStack(spacing: 20) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.gray)
                    
                    Text("Camera Access Required")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    if cameraManager.authorizationStatus == .denied {
                        Text("Please enable camera access in Settings")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Open Settings") {
                            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(settingsURL)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            VStack {
                // Mode switcher at top
                HStack {
                    if captureMode == .photo {
                        Button {
                            cameraManager.toggleFlash()
                        } label: {
                            Image(systemName: flashIcon)
                                .font(.title2)
                                .foregroundStyle(.white)
                                .padding()
                        }
                    }
                        
                    Spacer()
                    
                    Picker("Mode", selection: $captureMode) {
                        Text("Photo").tag(CaptureMode.photo)
                        Text("Video").tag(CaptureMode.video)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                    .padding()
                }
                
                Spacer()
                
                Button {
                    cameraManager.switchCamera()
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath.camera")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
                
                // Capture button (adapts to mode)
                if captureMode == .photo {
                    // Photo button
                    Button {
                        cameraManager.capturePhoto()
                    } label: {
                        Circle()
                            .strokeBorder(.white, lineWidth: 3)
                            .frame(width: 70, height: 70)
                            .overlay {
                                Circle()
                                    .fill(.white)
                                    .frame(width: 60, height: 60)
                            }
                    }
                } else {
                    // Video button
                    Button {
                        if cameraManager.isRecording {
                            cameraManager.stopRecording()
                        } else {
                            cameraManager.startRecording()
                        }
                    } label: {
                        Circle()
                            .strokeBorder(.white, lineWidth: 3)
                            .frame(width: 70, height: 70)
                            .overlay {
                                RoundedRectangle(cornerRadius: cameraManager.isRecording ? 6 : 30)
                                    .fill(.red)
                                    .frame(width: cameraManager.isRecording ? 30 : 60,
                                           height: cameraManager.isRecording ? 30 : 60)
                            }
                    }
                }
                
                // Recording indicator
                if cameraManager.isRecording {
                    HStack {
                        Circle()
                            .fill(.red)
                            .frame(width: 10, height: 10)
                        Text("Recording")
                            .foregroundStyle(.white)
                    }
                    .padding(.top, 8)
                }
                
                Spacer()
                    .frame(height: 40)
                
            }
            .sheet(item: $cameraManager.capturedImage) { image in
                // Wrap UIImage in Identifiable for sheet binding
                PhotoPreviewView(item: image, onDismiss: {
                    cameraManager.capturedImage = nil
                })
            }

            .sheet(item: Binding(
                get: { cameraManager.recordedVideoURL.map { IdentifiableURL(url: $0) } },
                set: { cameraManager.recordedVideoURL = $0?.url }
            )) { item in
                VideoPreviewView(url: item.url, onDismiss: {
                    cameraManager.recordedVideoURL = nil
                })
            }
            
        }
        .onAppear {
            cameraManager.checkAuthorization()
        }
    }
}

#Preview {
    ContentView()
}


struct PhotoPreviewView: View {
    let item: IdentifiableImage
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Retake") {
                    onDismiss()
                }
                .padding()
                
                Spacer()
                
                Button("Save") {
                    UIImageWriteToSavedPhotosAlbum(item.image, nil, nil, nil)
                    onDismiss()
                }
                .padding()
            }
            .background(.ultraThinMaterial)
            
            Image(uiImage: item.image)
                .resizable()
                .scaledToFit()
            
            Spacer()
        }
    }
}
   
struct VideoPreviewView: View {
    let url: URL
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Retake") {
                    onDismiss()
                }
                .padding()
                
                Spacer()
                
                Button("Save") {
                    UISaveVideoAtPathToSavedPhotosAlbum(url.path(), nil, nil, nil)
                    onDismiss()
                }
                .padding()
            }
            .background(.ultraThinMaterial)
            
            VideoPlayer(player: AVPlayer(url: url))
            
            Spacer()
        }
    }
}


struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}
