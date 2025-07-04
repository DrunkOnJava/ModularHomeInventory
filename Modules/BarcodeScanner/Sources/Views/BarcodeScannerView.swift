//
//  BarcodeScannerView.swift
//  HomeInventoryModular
//
//  Apple Configuration:
//  Bundle Identifier: com.homeinventory.app
//  Display Name: Home Inventory
//  Version: 1.0.5
//  Build: 5
//  Deployment Target: iOS 17.0
//  Supported Devices: iPhone & iPad
//  Team ID: 2VXBQV4XC9
//
//  Makefile Configuration:
//  Default Simulator: iPhone 16 Pro Max (DD192264-DFAA-4582-B2FE-D6FC444C9DDF)
//  iPad Simulator: iPad Pro 13-inch (M4) (CE6D038C-840B-4BDB-AA63-D61FA0755C4A)
//  App Bundle ID: com.homeinventory.app
//  Build Path: build/Build/Products/Debug-iphonesimulator/
//
//  Google Sign-In Configuration:
//  Client ID: 316432172622-6huvbn752v0ep68jkfdftrh8fgpesikg.apps.googleusercontent.com
//  URL Scheme: com.googleusercontent.apps.316432172622-6huvbn752v0ep68jkfdftrh8fgpesikg
//  OAuth Scope: https://www.googleapis.com/auth/gmail.readonly
//  Config Files: GoogleSignIn-Info.plist (project root), GoogleServices.plist (Gmail module)
//
//  Key Commands:
//  Build and run: make build run
//  Fast build (skip module prebuild): make build-fast run
//  iPad build and run: make build-ipad run-ipad
//  Clean build: make clean build run
//  Run tests: make test
//
//  Project Structure:
//  Main Target: HomeInventoryModular
//  Test Targets: HomeInventoryModularTests, HomeInventoryModularUITests
//  Swift Version: 5.9 (DO NOT upgrade to Swift 6)
//  Minimum iOS Version: 17.0
//
//  Architecture: Modular SPM packages with local package dependencies
//  Repository: https://github.com/DrunkOnJava/ModularHomeInventory.git
//  Module: BarcodeScanner
//  Dependencies: SwiftUI, UIKit, AVFoundation, Core, SharedUI, AppSettings
//  Testing: Modules/BarcodeScanner/Tests/ScannerTests/BarcodeScannerViewTests.swift
//
//  Description: Camera-based barcode scanner view with real-time scanning capabilities,
//               flash control, and camera permission handling
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import UIKit
import AVFoundation
import Core
import SharedUI
import AppSettings

/// Barcode scanner view
/// Swift 5.9 - No Swift 6 features
struct BarcodeScannerView: View {
    @StateObject private var viewModel: BarcodeScannerViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    init(viewModel: BarcodeScannerViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Camera view
                CameraPreview(
                    session: viewModel.captureSession,
                    shouldScan: $viewModel.isScanning
                )
                .ignoresSafeArea()
                
                // Overlay
                VStack {
                    // Top bar
                    HStack {
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundStyle(.white)
                        .appPadding()
                        
                        Spacer()
                        
                        Button(action: { viewModel.toggleFlash() }) {
                            Image(systemName: viewModel.isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                                .foregroundStyle(.white)
                        }
                        .appPadding()
                    }
                    .background(Color.black.opacity(0.7))
                    
                    Spacer()
                    
                    // Scanning frame
                    Rectangle()
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: 250, height: 250)
                        .overlay(
                            Rectangle()
                                .stroke(AppColors.primary, lineWidth: 3)
                                .scaleEffect(viewModel.isScanning ? 1.1 : 1.0)
                                .opacity(viewModel.isScanning ? 0.6 : 1.0)
                                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: viewModel.isScanning)
                        )
                    
                    Spacer()
                    
                    // Instructions
                    VStack(spacing: AppSpacing.sm) {
                        Text("Position barcode within frame")
                            .textStyle(.bodyLarge)
                            .foregroundStyle(.white)
                        
                        if let lastScanned = viewModel.lastScannedCode {
                            Text("Last scanned: \(lastScanned)")
                                .textStyle(.bodySmall)
                                .foregroundStyle(.white.opacity(0.8))
                                .appPadding(.horizontal)
                                .appPadding(.vertical, AppSpacing.xs)
                                .background(Color.black.opacity(0.5))
                                .cornerRadius(8)
                        }
                    }
                    .appPadding()
                    .background(Color.black.opacity(0.7))
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.checkCameraPermission()
            }
            .onDisappear {
                viewModel.stopScanning()
            }
            .alert("Camera Permission", isPresented: $viewModel.showingPermissionAlert) {
                Button("Settings") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("Camera access is required to scan barcodes. Please enable it in Settings.")
            }
            .alert("Scanned", isPresented: $showingAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
}

// MARK: - Camera Preview
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    @Binding var shouldScan: Bool
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        guard let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer else { return }
        previewLayer.frame = uiView.bounds
        
        if shouldScan {
            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
            }
        } else {
            DispatchQueue.global(qos: .userInitiated).async {
                session.stopRunning()
            }
        }
    }
}

// MARK: - View Model
@MainActor
final class BarcodeScannerViewModel: NSObject, ObservableObject {
    @Published var isScanning = false
    @Published var lastScannedCode: String?
    @Published var isFlashOn = false
    @Published var showingPermissionAlert = false
    
    let captureSession = AVCaptureSession()
    private let metadataOutput = AVCaptureMetadataOutput()
    private var videoDevice: AVCaptureDevice?
    private let completion: (String) -> Void
    private let soundService: SoundFeedbackService?
    private let settingsStorage: (any Core.SettingsStorageProtocol)?
    private let scanHistoryRepository: (any ScanHistoryRepository)?
    private var lastScanTime: Date = Date()
    
    init(
        soundService: SoundFeedbackService? = nil,
        settingsStorage: (any Core.SettingsStorageProtocol)? = nil,
        scanHistoryRepository: (any ScanHistoryRepository)? = nil,
        completion: @escaping (String) -> Void
    ) {
        self.soundService = soundService
        self.settingsStorage = settingsStorage
        self.scanHistoryRepository = scanHistoryRepository
        self.completion = completion
        super.init()
        setupCaptureSession()
    }
    
    func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            startScanning()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.startScanning()
                    } else {
                        self?.showingPermissionAlert = true
                    }
                }
            }
        case .denied, .restricted:
            showingPermissionAlert = true
        @unknown default:
            break
        }
    }
    
    private func setupCaptureSession() {
        captureSession.sessionPreset = .high
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        videoDevice = videoCaptureDevice
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            }
            
            if captureSession.canAddOutput(metadataOutput) {
                captureSession.addOutput(metadataOutput)
                
                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                
                // Get enabled formats from settings
                let settings = settingsStorage?.loadSettings() ?? AppSettings()
                let enabledTypes = settings.enabledBarcodeFormats.compactMap { formatString in
                    AVMetadataObject.ObjectType(rawValue: formatString)
                }
                
                // Use enabled formats or fall back to all formats
                metadataOutput.metadataObjectTypes = enabledTypes.isEmpty ? 
                    BarcodeFormat.allMetadataTypes : enabledTypes
                
                // Configure focus area based on sensitivity
                configureFocusArea()
            }
        } catch {
            print("Failed to setup capture session: \(error)")
        }
    }
    
    private func configureFocusArea() {
        let settings = settingsStorage?.loadSettings() ?? AppSettings()
        let scale = settings.scannerSensitivity.focusAreaScale
        
        // Set the rect of interest (centered)
        let x = (1.0 - scale) / 2.0
        let y = (1.0 - scale) / 2.0
        
        // Note: rectOfInterest is in landscape orientation (y,x,height,width)
        metadataOutput.rectOfInterest = CGRect(x: y, y: x, width: scale, height: scale)
    }
    
    func startScanning() {
        isScanning = true
        
        if !captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.startRunning()
            }
        }
    }
    
    func stopScanning() {
        isScanning = false
        
        if captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.stopRunning()
            }
        }
    }
    
    func toggleFlash() {
        guard let device = videoDevice, device.hasTorch else { return }
        
        do {
            try device.lockForConfiguration()
            isFlashOn.toggle()
            device.torchMode = isFlashOn ? .on : .off
            device.unlockForConfiguration()
        } catch {
            print("Failed to toggle flash: \(error)")
        }
    }
    
    func handleScannedCode(_ code: String) {
        // Prevent duplicate scans
        guard code != lastScannedCode else { return }
        
        // Check scan interval based on sensitivity
        let settings = settingsStorage?.loadSettings() ?? AppSettings()
        let scanInterval = settings.scannerSensitivity.scanInterval
        let timeSinceLastScan = Date().timeIntervalSince(lastScanTime)
        
        guard timeSinceLastScan >= scanInterval else { return }
        
        lastScannedCode = code
        lastScanTime = Date()
        
        // Play sound if enabled (will also include haptic feedback)
        soundService?.playSuccessSound()
        
        // Save to scan history
        if let scanHistoryRepository = scanHistoryRepository {
            Task {
                let entry = ScanHistoryEntry(
                    barcode: code,
                    scanType: .single
                )
                try? await scanHistoryRepository.save(entry)
            }
        }
        
        completion(code)
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate
extension BarcodeScannerViewModel: AVCaptureMetadataOutputObjectsDelegate {
    nonisolated func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let metadataObject = metadataObjects.first,
              let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
              let stringValue = readableObject.stringValue else { return }
        
        Task { @MainActor in
            handleScannedCode(stringValue)
        }
    }
}