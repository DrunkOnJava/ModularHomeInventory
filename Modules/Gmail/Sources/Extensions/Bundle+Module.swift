import Foundation

#if !SWIFT_PACKAGE
extension Bundle {
    static var module: Bundle {
        return Bundle(for: GmailModule.self)
    }
}
#endif
