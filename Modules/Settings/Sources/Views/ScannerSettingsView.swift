import SwiftUI
import SharedUI

/// Scanner settings view for adjusting scanner behavior
/// Swift 5.9 - No Swift 6 features
struct ScannerSettingsView: View {
    @Binding var settings: AppSettings
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                // Scanner Sound
                Section {
                    Toggle(isOn: $settings.scannerSoundEnabled) {
                        Label("Scanner Sound", systemImage: "speaker.wave.2")
                    }
                } header: {
                    Text("Audio")
                } footer: {
                    Text("Play sound when items are successfully scanned")
                        .textStyle(.labelSmall)
                }
                
                // Scanner Sensitivity
                Section {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Label("Scan Sensitivity", systemImage: "camera.viewfinder")
                            .textStyle(.bodyMedium)
                        
                        Picker("Sensitivity", selection: $settings.scannerSensitivity) {
                            ForEach(ScannerSensitivity.allCases, id: \.self) { sensitivity in
                                Text(sensitivity.rawValue).tag(sensitivity)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        Text(sensitivityDescription)
                            .textStyle(.labelSmall)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                } header: {
                    Text("Performance")
                } footer: {
                    Text("Adjust scanner sensitivity based on your environment and lighting conditions")
                        .textStyle(.labelSmall)
                }
                
                // Continuous Scan Settings
                Section {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Label("Continuous Scan Delay", systemImage: "timer")
                            .textStyle(.bodyMedium)
                        
                        HStack {
                            Text("\(settings.continuousScanDelay, specifier: "%.1f")s")
                                .textStyle(.bodyLarge)
                                .monospacedDigit()
                            
                            Slider(
                                value: $settings.continuousScanDelay,
                                in: 0.5...3.0,
                                step: 0.5
                            )
                        }
                        
                        Text("Time between scans in continuous mode")
                            .textStyle(.labelSmall)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                } header: {
                    Text("Batch Scanning")
                }
                
                // Barcode Formats
                Section {
                    NavigationLink(destination: BarcodeFormatSettingsView(viewModel: viewModel)) {
                        HStack {
                            Label("Barcode Formats", systemImage: "barcode")
                            Spacer()
                            Text("\(viewModel.settings.enabledBarcodeFormats.count) enabled")
                                .textStyle(.bodySmall)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                } header: {
                    Text("Format Support")
                } footer: {
                    Text("Choose which barcode formats to scan. Fewer formats may improve scanning speed.")
                        .textStyle(.bodySmall)
                }
                
                // Tips
                Section {
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Label("Scanner Tips", systemImage: "lightbulb")
                            .textStyle(.labelLarge)
                            .foregroundStyle(AppColors.primary)
                        
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            tipRow(
                                icon: "sun.max",
                                title: "Good Lighting",
                                description: "Scan in well-lit areas for best results"
                            )
                            
                            tipRow(
                                icon: "camera.fill",
                                title: "Hold Steady",
                                description: "Keep the camera still while scanning"
                            )
                            
                            tipRow(
                                icon: "viewfinder",
                                title: "Center Barcode",
                                description: "Position barcode in the center frame"
                            )
                            
                            tipRow(
                                icon: "bolt.fill",
                                title: "Use Flash",
                                description: "Enable flash in low-light conditions"
                            )
                        }
                    }
                    .padding(.vertical, AppSpacing.xs)
                }
            }
            .navigationTitle("Scanner Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var sensitivityDescription: String {
        switch settings.scannerSensitivity {
        case .low:
            return "Slower scanning, better for damaged barcodes"
        case .medium:
            return "Balanced speed and accuracy"
        case .high:
            return "Faster scanning in good conditions"
        }
    }
    
    private func tipRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(AppColors.textSecondary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .textStyle(.labelMedium)
                    .foregroundStyle(AppColors.textPrimary)
                
                Text(description)
                    .textStyle(.labelSmall)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }
}

#Preview {
    @State var settings = AppSettings()
    let viewModel = SettingsViewModel(settingsStorage: UserDefaultsSettingsStorage())
    return ScannerSettingsView(settings: $settings, viewModel: viewModel)
}