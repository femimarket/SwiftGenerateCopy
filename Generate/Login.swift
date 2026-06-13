//
//  Login.swift
//  Generate
//
//  Created by u on 11/06/2026.
//

import SwiftUI
import AuthenticationServices
import Api
//
///// Sign in with Apple sheet. Drives the auth handshake, persists the
///// resulting identity JWT to `UserDefaults["idToken"]`, and installs it
///// as the bearer on `ApiAPIConfiguration.shared` so all generated routes
///// authorize automatically. Calls `onComplete()` on success.
//struct LoginView: View {
//    let onComplete: () -> Void
//
//    var body: some View {
//        ZStack {
//            Color.black.ignoresSafeArea()
//            VStack(spacing: 28) {
//                Spacer()
//                Text("Generate")
//                    .font(.largeTitle.bold())
//                    .foregroundStyle(.white)
//                Text("Sign in to continue")
//                    .font(.subheadline)
//                    .foregroundStyle(.white.opacity(0.6))
//                Spacer()
//                SignInWithAppleButton(.signIn) { request in
//                    request.requestedScopes = [.email]
//                } onCompletion: { result in
//                    handle(result)
//                }
//                .signInWithAppleButtonStyle(.white)
//                .frame(height: 50)
//                .padding(.horizontal, 40)
//                .padding(.bottom, 60)
//            }
//        }
//    }
//
//    private func handle(_ result: Result<ASAuthorization, Error>) {
//        guard
//            case .success(let auth) = result,
//            let credential = auth.credential as? ASAuthorizationAppleIDCredential,
//            let tokenData = credential.identityToken,
//            let token = String(data: tokenData, encoding: .utf8)
//        else { return }
//        AppAuth.save(token: token)
//        onComplete()
//    }
//}
//
//extension AppAuth {
//    /// Persist the JWT and install it as the bearer on the Api configuration.
//    /// Single write path for the token — all API calls pick it up from here.
//    static func save(token: String) {
//        UserDefaults.standard.set(token, forKey: "idToken")
//        ApiAPIConfiguration.shared.customHeaders["Authorization"] = "Bearer \(token)"
//    }
//
//    /// True when the persisted JWT exists and its `exp` claim is still in the
//    /// future. Used at launch to decide between re-authorizing the saved
//    /// session and showing the Sign-in screen.
//    static func hasValidToken() -> Bool {
//        guard let token = UserDefaults.standard.string(forKey: "idToken"),
//              let exp = jwtExp(token)
//        else { return false }
//        return Date().timeIntervalSince1970 < TimeInterval(exp)
//    }
//
//    /// Re-install the persisted token as the API bearer. Called at launch
//    /// when `hasValidToken()` returns true so the in-memory `ApiAPIConfiguration`
//    /// matches the on-disk session.
//    static func installSavedBearer() {
//        guard let token = UserDefaults.standard.string(forKey: "idToken") else { return }
//        ApiAPIConfiguration.shared.customHeaders["Authorization"] = "Bearer \(token)"
//    }
//}
//
///// Decode a JWT's `exp` claim without verifying the signature. Mirror of the
///// `jwtSub` helper used elsewhere — same base64url-with-padding handling.
//private func jwtExp(_ token: String) -> Int? {
//    let parts = token.split(separator: ".")
//    guard parts.count >= 2 else { return nil }
//    var payload = String(parts[1])
//        .replacingOccurrences(of: "-", with: "+")
//        .replacingOccurrences(of: "_", with: "/")
//    let pad = (4 - payload.count % 4) % 4
//    payload.append(String(repeating: "=", count: pad))
//    guard
//        let data = Data(base64Encoded: payload),
//        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
//        let exp = json["exp"] as? Int
//    else { return nil }
//    return exp
//}
