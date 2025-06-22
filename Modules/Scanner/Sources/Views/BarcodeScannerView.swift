import SwiftUI
import AVFoundation
import SharedUI

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
    
    init(completion: @escaping (String) -> Void) {
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
                metadataOutput.metadataObjectTypes = [
                    .qr,
                    .ean13,
                    .ean8,
                    .upce,
                    .code128,
                    .code39,
                    .aztec,
                    .pdf417,
                    .interleaved2of5,
                    .itf14,
                    .dataMatrix
                ]
            }
        } catch {
            print("Failed to setup capture session: \(error)")
        }
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
        
        lastScannedCode = code
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Play sound if enabled
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        
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