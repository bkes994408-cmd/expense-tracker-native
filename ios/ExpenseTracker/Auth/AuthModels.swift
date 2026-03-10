import Foundation

struct AuthUser: Equatable {
    let id: UUID
    let email: String
    let displayName: String
}

enum AuthMode: Hashable {
    case login
    case register
}

enum SecurityLogRedactor {
    static func maskEmail(_ email: String) -> String {
        let parts = email.split(separator: "@", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return "***" }
        let local = parts[0]
        let domain = parts[1]
        let prefix = local.prefix(1)
        return "\(prefix)***@\(domain)"
    }

    static func maskToken(_ token: String) -> String {
        guard token.count > 6 else { return "***" }
        let prefix = token.prefix(3)
        let suffix = token.suffix(3)
        return "\(prefix)***\(suffix)"
    }

    static func redact(_ message: String, email: String? = nil, token: String? = nil) -> String {
        var output = message
        if let email, !email.isEmpty {
            output = output.replacingOccurrences(of: email, with: maskEmail(email))
        }
        if let token, !token.isEmpty {
            output = output.replacingOccurrences(of: token, with: maskToken(token))
        }
        return output
    }
}
