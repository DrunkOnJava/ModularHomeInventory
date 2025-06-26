//
//  LaunchPerformanceView.swift
//  AppSettings Module
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
//  Module: AppSettings
//  Dependencies: SwiftUI, Core, Charts
//  Testing: Modules/AppSettings/Tests/Views/LaunchPerformanceViewTests.swift
//
//  Description: Performance monitoring view displaying app launch metrics, phase breakdowns, optimization tips, and performance trends with charting
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import Core
import Charts

/// View showing app launch performance metrics
public struct LaunchPerformanceView: View {
    @State private var launchReports: [LaunchReport] = []
    @State private var selectedReport: LaunchReport?
    @State private var showingOptimizationTips = false
    
    private let optimizer = AppLaunchOptimizer.shared
    
    public init() {}
    
    public var body: some View {
        List {
            // Current session
            let currentReport = optimizer.getLaunchReport()
            Section("Current Session") {
                LaunchReportCard(report: currentReport, isLive: true)
            }
            
            // Performance chart
            if !launchReports.isEmpty {
                Section("Launch Time Trend") {
                    LaunchPerformanceChart(reports: launchReports)
                        .frame(height: 200)
                        .padding(.vertical)
                }
            }
            
            // Historical data
            if !launchReports.isEmpty {
                Section("Launch History") {
                    ForEach(launchReports.reversed()) { report in
                        LaunchReportRow(report: report) {
                            selectedReport = report
                        }
                    }
                }
            }
            
            // Optimization tips
            Section {
                Button(action: {
                    showingOptimizationTips = true
                }) {
                    Label("Optimization Tips", systemImage: "lightbulb")
                }
            }
        }
        .navigationTitle("Launch Performance")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadLaunchReports()
        }
        .sheet(item: $selectedReport) { report in
            LaunchReportDetailView(report: report)
        }
        .sheet(isPresented: $showingOptimizationTips) {
            OptimizationTipsView()
        }
    }
    
    private func loadLaunchReports() {
        if let data = UserDefaults.standard.data(forKey: "launch_metrics_history"),
           let reports = try? JSONDecoder().decode([LaunchReport].self, from: data) {
            launchReports = reports
        }
    }
}

// MARK: - Launch Report Card

struct LaunchReportCard: View {
    let report: LaunchReport
    let isLive: Bool
    
    var performanceColor: Color {
        if report.isOptimal {
            return .green
        } else if report.totalDuration < 1.5 {
            return .orange
        } else {
            return .red
        }
    }
    
    var performanceIcon: String {
        if report.isOptimal {
            return "checkmark.circle.fill"
        } else if report.totalDuration < 1.5 {
            return "exclamationmark.circle.fill"
        } else {
            return "xmark.circle.fill"
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: performanceIcon)
                    .font(.largeTitle)
                    .foregroundColor(performanceColor)
                
                VStack(alignment: .leading) {
                    Text("\(report.totalDurationMilliseconds)ms")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(report.isOptimal ? "Optimal Performance" : "Needs Optimization")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isLive {
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .foregroundColor(.green)
                        .symbolEffect(.pulse)
                }
            }
            
            // Phase breakdown
            VStack(alignment: .leading, spacing: 8) {
                ForEach(report.phases, id: \.phase) { phaseReport in
                    PhaseProgressBar(phaseReport: phaseReport)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Phase Progress Bar

struct PhaseProgressBar: View {
    let phaseReport: PhaseReport
    
    var progressColor: Color {
        phaseReport.isWithinTarget ? .green : .red
    }
    
    var progressPercentage: Double {
        min(phaseReport.duration / phaseReport.targetDuration, 2.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(phaseReport.phase.rawValue.capitalized)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(phaseReport.durationMilliseconds)ms")
                    .font(.caption)
                    .foregroundColor(progressColor)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(.systemGray4))
                        .frame(height: 4)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 2)
                        .fill(progressColor)
                        .frame(width: geometry.size.width * progressPercentage, height: 4)
                    
                    // Target marker
                    Rectangle()
                        .fill(Color.primary)
                        .frame(width: 1, height: 8)
                        .offset(x: geometry.size.width * 1.0 - 0.5, y: -2)
                }
            }
            .frame(height: 4)
        }
    }
}

// MARK: - Launch Performance Chart

struct LaunchPerformanceChart: View {
    let reports: [LaunchReport]
    
    var body: some View {
        Chart(Array(reports.enumerated()), id: \.offset) { index, report in
            LineMark(
                x: .value("Launch", index),
                y: .value("Time", report.totalDurationMilliseconds)
            )
            .foregroundStyle(.blue)
            
            PointMark(
                x: .value("Launch", index),
                y: .value("Time", report.totalDurationMilliseconds)
            )
            .foregroundStyle(report.isOptimal ? Color.green : Color.orange)
            
            // Target line
            RuleMark(y: .value("Target", 1000))
                .foregroundStyle(.green.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
        }
        .chartYAxisLabel("Launch Time (ms)")
        .chartXAxisLabel("Recent Launches")
        .chartYAxis {
            AxisMarks(position: .leading)
        }
    }
}

// MARK: - Launch Report Row

struct LaunchReportRow: View {
    let report: LaunchReport
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(report.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.headline)
                    
                    Text("\(report.totalDurationMilliseconds)ms total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Launch Report Detail View

struct LaunchReportDetailView: View {
    let report: LaunchReport
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Summary") {
                    LabeledContent("Total Duration", value: "\(report.totalDurationMilliseconds)ms")
                    LabeledContent("Performance", value: report.isOptimal ? "Optimal" : "Needs Improvement")
                    LabeledContent("Timestamp", value: report.timestamp.formatted())
                }
                
                Section("Phase Breakdown") {
                    ForEach(report.phases, id: \.phase) { phaseReport in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(phaseReport.phase.rawValue.capitalized)
                                    .font(.headline)
                                
                                Text("Target: \(phaseReport.targetDurationMilliseconds)ms")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("\(phaseReport.durationMilliseconds)ms")
                                    .font(.headline)
                                    .foregroundColor(phaseReport.isWithinTarget ? .green : .red)
                                
                                if !phaseReport.isWithinTarget {
                                    Text("+\(phaseReport.durationMilliseconds - phaseReport.targetDurationMilliseconds)ms")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Launch Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Optimization Tips View

struct OptimizationTipsView: View {
    @Environment(\.dismiss) private var dismiss
    
    let tips = [
        OptimizationTip(
            title: "Reduce Initial View Complexity",
            description: "Simplify your launch screen and initial view controller to reduce rendering time.",
            impact: .high
        ),
        OptimizationTip(
            title: "Defer Non-Critical Work",
            description: "Move non-essential initialization to after the first frame is rendered.",
            impact: .high
        ),
        OptimizationTip(
            title: "Optimize Image Loading",
            description: "Use smaller images for launch screens and defer loading large images.",
            impact: .medium
        ),
        OptimizationTip(
            title: "Minimize Dependencies",
            description: "Reduce the number of frameworks and libraries loaded at launch.",
            impact: .high
        ),
        OptimizationTip(
            title: "Enable Link-Time Optimization",
            description: "Turn on LTO in build settings to improve binary size and performance.",
            impact: .medium
        ),
        OptimizationTip(
            title: "Profile with Instruments",
            description: "Use Time Profiler to identify bottlenecks in your launch sequence.",
            impact: .high
        )
    ]
    
    var body: some View {
        NavigationStack {
            List(tips) { tip in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(tip.title)
                            .font(.headline)
                        
                        Spacer()
                        
                        ImpactBadge(impact: tip.impact)
                    }
                    
                    Text(tip.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Optimization Tips")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Types

struct OptimizationTip: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let impact: Impact
    
    enum Impact {
        case low, medium, high
        
        var color: Color {
            switch self {
            case .low: return .blue
            case .medium: return .orange
            case .high: return .red
            }
        }
        
        var text: String {
            switch self {
            case .low: return "Low"
            case .medium: return "Medium"
            case .high: return "High"
            }
        }
    }
}

struct ImpactBadge: View {
    let impact: OptimizationTip.Impact
    
    var body: some View {
        Text(impact.text)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(impact.color)
            .clipShape(Capsule())
    }
}

// Make LaunchReport Identifiable
extension LaunchReport: Identifiable {
    public var id: Date { timestamp }
}