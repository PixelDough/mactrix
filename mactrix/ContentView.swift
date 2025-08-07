//
//  ContentView.swift
//  mactrix
//
//  Created by Annie Worrell on 8/6/25.
//

import SwiftUI
import KeychainAccess
import MatrixRustSDK

struct ContentView: View {
    @State var matrixState: MatrixState = MatrixState()
    @State var selectedRoomId: String?

    @State var currentRoom: Room?

    let applicationID = "dev.anniesden.mactrix"
    let keychainSessionKey = "WalkthroughUser"

    @State var username: String = ""
    @State var password: String = ""

    @State var avatarUrl: String?

    @State var showVerificationSheet: Bool = false

    enum MenuState {
        case home
        case account
    }

    var body: some View {
        NavigationSplitView(preferredCompactColumn: Binding.constant(.detail)) {
            List {
                if let client = matrixState.client, let roomListener = matrixState.allRoomsListener {
                    @Bindable var roomListener = roomListener
                    NavigationLink(value: MenuState.account) {
                        Label {
                            Text("Account")
                        } icon: {
                            MxcAsyncImage(mxcUrl: avatarUrl ?? "") { image in
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .clipShape(
                                        Circle()
                                    )
                            } placeholder: {
                                ProgressView()
                                    .controlSize(.mini)
                            }
                            .task {
                                do {
                                    if let cached = try await client.cachedAvatarUrl() {
                                        avatarUrl = cached
                                    } else {
                                        avatarUrl = try await client.avatarUrl()
                                    }
                                } catch {
                                    print("Error fetching client avatar url: \(error)")
                                }
                            }
                        }
                    }
                    NavigationLink(value: MenuState.home) {
                        Label("Home", systemImage: "house")
                    }

                    RoomsList(rooms: roomListener.rooms)
                }
            }
            .navigationDestination(for: RoomInfo.self) { roomInfo in
                RoomView(roomInfo: roomInfo)
                    .navigationTitle(roomInfo.displayName ?? roomInfo.rawName ?? "Unknown Room")
            }
            .navigationDestination(for: MenuState.self) { menuState in
                switch menuState {
                case .home:
                    VStack {

                    }
                    .navigationTitle("Home")
                case .account:
                    Button {
                        Task {
                            do {
                                showVerificationSheet = true
                                try await matrixState.verificationStep()
                            } catch {
                                print("Error verifying device: \(error)")
                            }
                        }
                    } label: {
                        Label("Verify Device", systemImage: "lock")
                    }
                    .disabled(matrixState.client?.encryption().verificationState() == .verified)
                    Button {
                        Task {
                            do {
                                if let walkthroughUser = try loadUserFromKeychain() {
                                    try? FileManager.default.removeItem(at: .sessionData(for: walkthroughUser.storeID))
                                    try? FileManager.default.removeItem(at: .sessionCaches(for: walkthroughUser.storeID))
                                    let keychain = Keychain(service: applicationID)
                                    try keychain.removeAll()
                                    try await matrixState.logout()
                                }
                            } catch {
                                print("Error signing out: \(error)")
                            }
                        }
                    } label: {
                        Label("Sign Out", systemImage: "person.circle.fill")
                    }
                    .navigationTitle("Account")
                }
            }
        } content: {

        } detail: {

        }
        .navigationSplitViewStyle(.balanced)
        .sheet(isPresented: Binding.constant(matrixState.client == nil)) {
            Form {
                TextField("Username", text: $username)
                SecureField("Password", text: $password)
                Button {
                    Task {
                        let walkthroughUser = try await matrixState.step1Login(
                            username: username,
                            password: password
                        )
                        try saveUserToKeychain(walkthroughUser)
                        try await matrixState.step2StartSync()
                    }
                } label: {
                    Label("Sign In", systemImage: "person.circle")
                }
                .disabled(matrixState.client != nil)
            }
            .padding()
            .presentationCompactAdaptation(.fullScreenCover)
            .presentationPreventsAppTermination(false)
        }
        .sheet(isPresented: $showVerificationSheet) {
            VerificationView()
                .presentationCompactAdaptation(.fullScreenCover)
        }
        .task {
            // Log in if keychain exists
            if matrixState.client != nil { return }
            do {
                guard let walkthroughUser = try loadUserFromKeychain() else { return }
                try await matrixState.step1Restore(walkthroughUser)
                try await matrixState.step2StartSync()
            } catch {
                print("Error loading user from keychain: \(error)")
            }
        }
        .task(id: selectedRoomId) {
            // Load room from selected room id
            do {
                currentRoom = nil
                if let selectedRoomId {
                    let room = try matrixState.client.getRoom(roomId: selectedRoomId)
                    currentRoom = room
                }
            } catch {
                print("Error getting selected room with id \(selectedRoomId ?? "nil"): \(error)")
            }
        }
        .environment(matrixState)
    }

    func saveUserToKeychain(_ walkthroughUser: WalkthroughUser) throws {
        let keychainData = try JSONEncoder().encode(walkthroughUser)
        let keychain = Keychain(service: applicationID)
        try keychain.set(keychainData, key: keychainSessionKey)
    }

    func loadUserFromKeychain() throws -> WalkthroughUser? {
        let keychain = Keychain(service: applicationID)
        guard let keychainData = try keychain.getData(keychainSessionKey) else { return nil }
        return try JSONDecoder().decode(WalkthroughUser.self, from: keychainData)
    }
}

#Preview {
    ContentView()
}
