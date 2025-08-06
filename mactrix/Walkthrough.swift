import ArgumentParser
import Foundation
import KeychainAccess
import MatrixRustSDK

@Observable
class Walkthrough {
    
}

// MARK: - @main

let applicationID = "dev.anniesden.mactrix"
let keychainSessionKey = "WalkthroughUser"
//
////@main
//struct WalkthroughCommand {
//    static let configuration = CommandConfiguration(abstract: "A basic example of using Matrix Rust SDK in Swift.")
//    
//    func run() async throws {
//        let walkthrough = Walkthrough()
//        
//        if let walkthroughUser = try loadUserFromKeychain() {
//            try await walkthrough.step1Restore(walkthroughUser)
//        } else {
//            let walkthroughUser = try await walkthrough.step1Login()
//            try saveUserToKeychain(walkthroughUser)
//        }
//        
//        try await walkthrough.step2StartSync()
//        try await walkthrough.step3LoadRoomTimeline()
//        try await walkthrough.step4SendMessage()
//        
//        // Don't exit immediately otherwise the message won't be sent (the await only suspends until the event is queued).
//        _ = readLine()
//    }
//    
//    func saveUserToKeychain(_ walkthroughUser: WalkthroughUser) throws {
//        let keychainData = try JSONEncoder().encode(walkthroughUser)
//        let keychain = Keychain(service: applicationID)
//        try keychain.set(keychainData, key: keychainSessionKey)
//    }
//    
//    func loadUserFromKeychain() throws -> WalkthroughUser? {
//        let keychain = Keychain(service: applicationID)
//        guard let keychainData = try keychain.getData(keychainSessionKey) else { return nil }
//        return try JSONDecoder().decode(WalkthroughUser.self, from: keychainData)
//    }
//    
//    private func reset() throws {
//        if let walkthroughUser = try loadUserFromKeychain() {
//            try? FileManager.default.removeItem(at: .sessionData(for: walkthroughUser.storeID))
//            try? FileManager.default.removeItem(at: .sessionCaches(for: walkthroughUser.storeID))
//            let keychain = Keychain(service: applicationID)
//            try keychain.removeAll()
//        }
//    }
//}

struct WalkthroughUser: Codable {
    let accessToken: String
    let refreshToken: String?
    let userID: String
    let deviceID: String
    let homeserverURL: String
    let oidcData: String?
    let storeID: String
    
    init(session: Session, storeID: String) {
        self.accessToken = session.accessToken
        self.refreshToken = session.refreshToken
        self.userID = session.userId
        self.deviceID = session.deviceId
        self.homeserverURL = session.homeserverUrl
        self.oidcData = session.oidcData
        self.storeID = storeID
    }
    
    var session: Session {
        Session(accessToken: accessToken,
                refreshToken: refreshToken,
                userId: userID,
                deviceId: deviceID,
                homeserverUrl: homeserverURL,
                oidcData: oidcData,
                slidingSyncVersion: .native)
        
    }
}

extension URL {
    static func sessionData(for sessionID: String) -> URL {
        applicationSupportDirectory
            .appending(component: applicationID)
            .appending(component: sessionID)
    }
    
    static func sessionCaches(for sessionID: String) -> URL {
        cachesDirectory
            .appending(component: applicationID)
            .appending(component: sessionID)
    }
}
