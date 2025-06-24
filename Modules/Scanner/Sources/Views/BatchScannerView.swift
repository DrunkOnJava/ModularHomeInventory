import SwiftUI
import AVFoundation
import SharedUI
import Core
import Settings

/// Batch scanner view for scanning multiple items consecutively
/// Swift 5.9 - No Swift 6 features
struct BatchScannerView: View {
    @StateObject private var viewModel: BatchScannerViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddItemView = false
    @State private var currentBarcode: String?
    
    init(viewModel: BatchScannerViewModel) {
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
                    topBar
                    
                    Spacer()
                    
                    // Scanning frame
                    scanningFrame
                    
                    Spacer()
                    
                    // Bottom section with stats and instructions
                    bottomSection
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.checkCameraPermission()
            }
            .onDisappear {
                viewModel.stopScanning()
            }
            .sheet(isPresented: $showingAddItemView) {
                if let barcode = currentBarcode,
                   let addView = viewModel.makeAddItemView(barcode: barcode) {
                    addView
                        .onDisappear {
                            // Resume scanning after adding item
                            viewModel.resumeScanning()
                            currentBarcode = nil
                        }
                }
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
            .alert("Scan Complete", isPresented: $viewModel.showingCompleteAlert) {
                Button("Done") {
                    dismiss()
                }
                Button("Continue Scanning") {
                    viewModel.resumeScanning()
                }
            } message: {
                Text("Successfully scanned \(viewModel.scannedItems.count) items")
            }
        }
    }
    
    // MARK: - View Components
    
    private var topBar: some View {
        HStack {
            Button("Done") {
                dismiss()
            }
            .foregroundStyle(.white)
            .appPadding()
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(viewModel.scannedItems.count) items")
                    .textStyle(.headlineMedium)
                    .foregroundStyle(.white)
                
                Text("scanned")
                    .textStyle(.bodySmall)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .appPadding()
            
            Spacer()
            
            Button(action: { viewModel.toggleFlash() }) {
                Image(systemName: viewModel.isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                    .foregroundStyle(.white)
            }
            .appPadding()
        }
        .background(Color.black.opacity(0.7))
    }
    
    private var scanningFrame: some View {
        VStack(spacing: AppSpacing.md) {
            Rectangle()
                .stroke(Color.white, lineWidth: 2)
                .frame(width: 280, height: 280)
                .overlay(
                    Rectangle()
                        .stroke(AppColors.primary, lineWidth: 3)
                        .scaleEffect(viewModel.isScanning ? 1.1 : 1.0)
                        .opacity(viewModel.isScanning ? 0.6 : 1.0)
                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: viewModel.isScanning)
                )
            
            if viewModel.scanMode == .continuous {
                Text("CONTINUOUS MODE")
                    .textStyle(.labelSmall)
                    .foregroundStyle(AppColors.success)
                    .appPadding(.horizontal, AppSpacing.sm)
                    .appPadding(.vertical, AppSpacing.xs)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(4)
            }
        }
    }
    
    private var bottomSection: some View {
        VStack(spacing: AppSpacing.md) {
            // Recent scans
            if !viewModel.recentScans.isEmpty {
                VStack(spacing: AppSpacing.xs) {
                    Text("Recent Scans")
                        .textStyle(.labelSmall)
                        .foregroundStyle(.white.opacity(0.7))
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppSpacing.sm) {
                            ForEach(viewModel.recentScans, id: \.self) { scan in
                                Text(scan)
                                    .textStyle(.bodySmall)
                                    .foregroundStyle(.white)
                                    .appPadding(.horizontal, AppSpacing.sm)
                                    .appPadding(.vertical, AppSpacing.xs)
                                    .background(AppColors.primary.opacity(0.7))
                                    .cornerRadius(4)
                            }
                        }
                        .appPadding(.horizontal)
                    }
                }
            }
            
            // Instructions and mode toggle
            VStack(spacing: AppSpacing.sm) {
                Text(viewModel.scanMode == .continuous ? 
                     "Scanning continuously - items added automatically" : 
                     "Scan barcode to add item details")
                    .textStyle(.bodyMedium)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                
                Toggle("Continuous Mode", isOn: $viewModel.isContinuousMode)
                    .toggleStyle(SwitchToggleStyle(tint: AppColors.primary))
                    .foregroundStyle(.white)
                    .appPadding(.horizontal, AppSpacing.xl)
            }
            .appPadding()
            .background(Color.black.opacity(0.7))
        }
    }
}

// MARK: - View Model
@MainActor
final class BatchScannerViewModel: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var isScanning = false
    @Published var isFlashOn = false
    @Published var showingPermissionAlert = false
    @Published var showingCompleteAlert = false
    @Published var scannedItems: [ScannedItem] = []
    @Published var recentScans: [String] = []
    @Published var isContinuousMode = false {
        didSet {
            scanMode = isContinuousMode ? .continuous : .manual
        }
    }
    @Published var scanMode: ScanMode = .manual
    
    // MARK: - Types
    enum ScanMode {
        case manual      // Show add item form for each scan
        case continuous  // Add items automatically with default values
    }
    
    struct ScannedItem {
        let id = UUID()
        let barcode: String
        let timestamp: Date
        var item: Item?
    }
    
    // MARK: - Properties
    let captureSession = AVCaptureSession()
    private let metadataOutput = AVCaptureMetadataOutput()
    private var videoDevice: AVCaptureDevice?
    private let completion: ([Item]) -> Void
    private var lastScannedCode: String?
    private var scanCooldown = false
    
    // Dependencies
    private let itemRepository: any ItemRepository
    private let itemTemplateRepository: any ItemTemplateRepository
    private let createItemView: ((String) -> AnyView)?
    private let soundService: SoundFeedbackService?
    private let settingsStorage: SettingsStorageProtocol?
    private let scanHistoryRepository: (any ScanHistoryRepository)?
    
    // MARK: - Initialization
    init(
        itemRepository: any ItemRepository,
        itemTemplateRepository: any ItemTemplateRepository,
        createItemView: ((String) -> AnyView)? = nil,
        soundService: SoundFeedbackService? = nil,
        settingsStorage: (any Core.SettingsStorageProtocol)? = nil,
        scanHistoryRepository: (any ScanHistoryRepository)? = nil,
        completion: @escaping ([Item]) -> Void
    ) {
        self.itemRepository = itemRepository
        self.itemTemplateRepository = itemTemplateRepository
        self.createItemView = createItemView
        self.soundService = soundService
        self.settingsStorage = settingsStorage
        self.scanHistoryRepository = scanHistoryRepository
        self.completion = completion
        super.init()
        setupCaptureSession()
    }
    
    // MARK: - Camera Setup
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
    
    // MARK: - Scanning Control
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
    
    func pauseScanning() {
        isScanning = false
    }
    
    func resumeScanning() {
        isScanning = true
        scanCooldown = false
        lastScannedCode = nil
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
    
    // MARK: - Barcode Handling
    func handleScannedCode(_ code: String) {
        // Prevent duplicate scans and respect cooldown
        guard code != lastScannedCode, !scanCooldown else { return }
        
        lastScannedCode = code
        scanCooldown = true
        
        // Add to recent scans (keep last 5)
        recentScans.insert(code, at: 0)
        if recentScans.count > 5 {
            recentScans.removeLast()
        }
        
        // Play sound if enabled (will also include haptic feedback)
        soundService?.playSuccessSound()
        
        let scannedItem = ScannedItem(barcode: code, timestamp: Date())
        scannedItems.append(scannedItem)
        
        // Save to scan history
        if let scanHistoryRepository = scanHistoryRepository {
            Task {
                let entry = ScanHistoryEntry(
                    barcode: code,
                    scanType: isContinuousMode ? .continuous : .batch
                )
                try? await scanHistoryRepository.save(entry)
            }
        }
        
        switch scanMode {
        case .manual:
            // Pause scanning and show add item form
            pauseScanning()
            Task { @MainActor in
                // This will be handled by the view showing the add item sheet
            }
            
        case .continuous:
            // Create item with default values
            Task {
                await createItemWithDefaults(barcode: code)
                
                // Resume scanning after delay based on settings
                let settings = settingsStorage?.loadSettings() ?? AppSettings()
                let delayNanoseconds = UInt64(settings.continuousScanDelay * 1_000_000_000)
                try? await Task.sleep(nanoseconds: delayNanoseconds)
                await MainActor.run {
                    self.scanCooldown = false
                }
            }
        }
    }
    
    private func createItemWithDefaults(barcode: String) async {
        do {
            let item = Item(
                id: UUID(),
                name: "Scanned Item \(scannedItems.count)",
                brand: nil,
                model: nil,
                category: .other,
                condition: .new,
                quantity: 1,
                value: nil,
                purchasePrice: nil,
                purchaseDate: Date(),
                notes: "Batch scanned on \(Date().formatted())",
                barcode: barcode,
                serialNumber: nil,
                tags: ["batch-scanned"],
                imageIds: [],
                locationId: nil,
                warrantyId: nil,
                createdAt: Date(),
                updatedAt: Date()
            )
            
            try await itemRepository.save(item)
            
            // Update the scanned item with the created item
            if let index = scannedItems.firstIndex(where: { $0.barcode == barcode }) {
                scannedItems[index].item = item
            }
        } catch {
            print("Failed to create item: \(error)")
        }
    }
    
    func makeAddItemView(barcode: String) -> AnyView? {
        createItemView?(barcode)
    }
    
    func completeScanning() {
        let items = scannedItems.compactMap { $0.item }
        completion(items)
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate
extension BatchScannerViewModel: AVCaptureMetadataOutputObjectsDelegate {
    nonisolated func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let metadataObject = metadataObjects.first,
              let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
              let stringValue = readableObject.stringValue else { return }
        
        Task { @MainActor in
            handleScannedCode(stringValue)
        }
    }
}