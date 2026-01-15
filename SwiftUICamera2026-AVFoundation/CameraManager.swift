//
    // Project: SwiftUICamera2026-AVFoundation
    //  File: Untitled.swift
//  Created by Noah Carpenter
//  🐱 Follow me on YouTube! 🎥
//  https://www.youtube.com/@NoahDoesCoding97
//  Like and Subscribe for coding tutorials and fun! 💻✨
//  Fun Fact: Cats have five toes on their front paws, but only four on their back paws! 🐾
//  Dream Big, Code Bigger

    
import AVFoundation
import SwiftUI
import Combine
//manages camera capture session and controls

class CameraManager: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate, AVCaptureFileOutputRecordingDelegate{
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: (any Error)?) {
        if let error = error {
            print("Video recording error: \(error.localizedDescription)")
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.recordedVideoURL = outputFileURL
        }
    }
    
    
    // Published properties for SwiftUI observation
    @Published var capturedImage: IdentifiableImage?
    @Published var isSessionRunning = false
    @Published var authorizationStatus: AVAuthorizationStatus = .notDetermined
    @Published var isRecording = false
    @Published var recordedVideoURL: URL?
    @Published var flashMode: AVCaptureDevice.FlashMode = .off
    
    @Published var zoomFactor: CGFloat = 1.0
    private let minZoomFactor: CGFloat = 1.0
    private let maxZoomFactor: CGFloat = 5.0
    
    
    private var outputURL: URL?
    
    // AVFoundation components
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let videoOutput = AVCaptureMovieFileOutput()
    private var currentInput: AVCaptureDeviceInput?
    
    // Queue for session configuration (off main thread)
    private let sessionQueue = DispatchQueue(label: "com.customcamera.sessionQueue")
    
    override init() {
        super.init()
    }
    
    func checkAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // Already authorized, setup session
            authorizationStatus = .authorized
            setupSession()
            
        case .notDetermined:
            // Request permission
            authorizationStatus = .notDetermined
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.authorizationStatus = granted ? .authorized : .denied
                    if granted {
                        self?.setupSession()
                    }
                }
            }
            
        case .denied, .restricted:
            authorizationStatus = .denied
            
        @unknown default:
            authorizationStatus = .denied
        }
    }
    
    
    private func setupSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Set session preset for quality
            self.session.beginConfiguration()
            self.session.sessionPreset = .high
            
            // Add camera input
            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                       for: .video,
                                                       position: .back),
                  let input = try? AVCaptureDeviceInput(device: camera) else {
                print("Failed to access camera")
                self.session.commitConfiguration()
                return
            }
            
            if self.session.canAddInput(input) {
                self.session.addInput(input)
                self.currentInput = input
            }
            
            // Add photo output
            if self.session.canAddOutput(self.photoOutput) {
                self.session.addOutput(self.photoOutput)
                
                // Configure photo output settings
                self.photoOutput.isHighResolutionCaptureEnabled = true
                self.photoOutput.maxPhotoQualityPrioritization = .quality
            }
            //Add video output
            if self.session.canAddOutput(self.videoOutput) {
                self.session.addOutput(self.videoOutput)
            }
            
            // Add microphone for video audio
            if let microphone = AVCaptureDevice.default(for: .audio),
               let audioInput = try? AVCaptureDeviceInput(device: microphone),
               self.session.canAddInput(audioInput) {
                self.session.addInput(audioInput)
            }
            
            self.session.commitConfiguration()
            
            // Start the session
            self.session.startRunning()
            
            DispatchQueue.main.async {
                self.isSessionRunning = self.session.isRunning
            }
        }
    }
    
    func capturePhoto() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Configure photo settings
            let settings = AVCapturePhotoSettings()
            settings.flashMode = self.flashMode
            
            // Enable high resolution capture
            if self.photoOutput.isHighResolutionCaptureEnabled {
                settings.isHighResolutionPhotoEnabled = true
            }
            
            // Request photo capture
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        
        if let error = error {
            print("Photo capture error: \(error.localizedDescription)")
            return
        }
        
        // Extract image data
        guard let imageData = photo.fileDataRepresentation(),
              let uiImage = UIImage(data: imageData) else {
            print("Failed to convert photo to image")
            return
        }
        
        // Update UI on main thread
        DispatchQueue.main.async { [weak self] in
            self?.capturedImage = IdentifiableImage(image: uiImage)
        }
    }
    
    // Start recording video
    func startRecording() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Generate temporary file URL
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("mov")
            
            self.outputURL = tempURL
            
            // Start recording to file
            self.videoOutput.startRecording(to: tempURL, recordingDelegate: self)
            
            DispatchQueue.main.async {
                self.isRecording = true
            }
        }
    }
    
    // Stop recording video
    func stopRecording() {
        sessionQueue.async { [weak self] in
            self?.videoOutput.stopRecording()
            
            DispatchQueue.main.async {
                self?.isRecording = false
            }
        }
    }
    
    func switchCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.session.beginConfiguration()
            
            // Remove current input
            if let currentInput = self.currentInput {
                self.session.removeInput(currentInput)
            }
            
            // Determine new camera position
            let currentPosition = self.currentInput?.device.position ?? .back
            let newPosition: AVCaptureDevice.Position = (currentPosition == .back) ? .front : .back
            
            // Get new camera device
            guard let newCamera = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                          for: .video,
                                                          position: newPosition),
                  let newInput = try? AVCaptureDeviceInput(device: newCamera) else {
                // Failed to get new camera, re-add old input
                if let currentInput = self.currentInput,
                   self.session.canAddInput(currentInput) {
                    self.session.addInput(currentInput)
                }
                self.session.commitConfiguration()
                return
            }
            
            // Add new camera input
            if self.session.canAddInput(newInput) {
                self.session.addInput(newInput)
                self.currentInput = newInput
            }
            
            self.session.commitConfiguration()
        }
    }
    func toggleFlash() {
        flashMode = switch flashMode {
        case .off: .on
        case .on: .auto
        case .auto: .off
        @unknown default: .off
        }
    }
    
    
    func zoom(factor: CGFloat) {
        sessionQueue.async { [weak self] in
            guard let self = self,
                  let device = self.currentInput?.device else { return }
            
            do {
                try device.lockForConfiguration()
                
                // Clamp zoom to device limits
                let clampedZoom = max(self.minZoomFactor,
                                      min(factor,
                                          min(self.maxZoomFactor, device.activeFormat.videoMaxZoomFactor)))
                
                device.videoZoomFactor = clampedZoom
                
                DispatchQueue.main.async {
                    self.zoomFactor = clampedZoom
                }
                
                device.unlockForConfiguration()
            } catch {
                print("Zoom error: \(error.localizedDescription)")
            }
        }
    }
    
}


struct IdentifiableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}
