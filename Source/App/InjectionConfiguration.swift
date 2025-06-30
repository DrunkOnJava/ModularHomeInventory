//
//  InjectionConfiguration.swift
//  HomeInventoryModular
//
//  Configuration for InjectionIII hot reload
//

import Foundation

#if DEBUG
import SwiftUI

extension UIViewController {
    @objc func injected() {
        // This method is called when code is injected
        // Reload the view controller's view
        viewDidLoad()
    }
}

extension View {
    func enableInjection() -> some View {
        self
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("INJECTION_BUNDLE_NOTIFICATION"))) { _ in
                // Force SwiftUI to re-evaluate the view
            }
    }
}

class InjectionConfiguration {
    static func setup() {
        #if targetEnvironment(simulator)
        // Load injection bundle
        Bundle(path: "/Applications/InjectionIII.app/Contents/Resources/iOSInjection.bundle")?.load()
        
        // For SwiftUI hot reload
        var injectionBundlePath = "/Applications/InjectionIII.app/Contents/Resources"
        #if targetEnvironment(macCatalyst)
        injectionBundlePath = "\(injectionBundlePath)/macOSInjection.bundle"
        #elseif os(iOS)
        injectionBundlePath = "\(injectionBundlePath)/iOSInjection.bundle"
        #elseif os(tvOS)
        injectionBundlePath = "\(injectionBundlePath)/tvOSInjection.bundle"
        #endif
        
        if let bundle = Bundle(path: injectionBundlePath) {
            bundle.load()
            print("💉 InjectionIII loaded successfully")
        } else {
            print("⚠️ InjectionIII not found - hot reload disabled")
            print("ℹ️ Install from: https://apps.apple.com/app/injectioniii/id1380446739")
        }
        #endif
    }
}
#endif