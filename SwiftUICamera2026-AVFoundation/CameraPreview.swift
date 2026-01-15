//
    // Project: SwiftUICamera2026-AVFoundation
    //  File: CameraPreview.swift
//  Created by Noah Carpenter
//  🐱 Follow me on YouTube! 🎥
//  https://www.youtube.com/@NoahDoesCoding97
//  Like and Subscribe for coding tutorials and fun! 💻✨
//  Fun Fact: Cats have five toes on their front paws, but only four on their back paws! 🐾
//  Dream Big, Code Bigger

    
import SwiftUI
import AVFoundation

// SwiftUI wrapper for camera preview layer
struct CameraPreview: UIViewRepresentable {
    
    let session: AVCaptureSession
    let cameraManager: CameraManager
    
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        
        context.coordinator.previewLayer = previewLayer
        
        // Add pinch gesture for zoom
        let pinchGesture = UIPinchGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePinch(_:))
        )
        view.addGestureRecognizer(pinchGesture)
        
        context.coordinator.cameraManager = cameraManager
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update layer frame when view size changes
        if let previewLayer = context.coordinator.previewLayer {
            DispatchQueue.main.async {
                previewLayer.frame = uiView.bounds
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
        var cameraManager: CameraManager?
        var lastZoomFactor: CGFloat = 1.0
        
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let manager = cameraManager else { return }
            
            switch gesture.state {
            case .began:
                lastZoomFactor = manager.zoomFactor
                
            case .changed:
                let newZoom = lastZoomFactor * gesture.scale
                manager.zoom(factor: newZoom)
                
            default:
                break
            }
        }
    }
}
