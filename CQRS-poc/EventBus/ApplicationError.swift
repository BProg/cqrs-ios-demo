import Foundation

public struct ApplicationErrorRecoveryHint: Equatable, Sendable, CustomStringConvertible {
    public let value: String

    public var description: String {
        value
    }

    public var id: String {
        value
    }

    public static let retry = Self("retry")
    public static let freeDeviceStorage = Self("freeDeviceStorage")
    public static let connectToInternet = Self("connectToInternet")
    public static let premiumRequired = Self("premiumRequired")
    public static let authenticationNeeded = Self("authenticationNeeded")
    public static let updateRequired = Self("updateRequired")
    public static let restartApplication = Self("restartApplication")

    public init(_ value: String) {
        self.value = value
    }
}

public struct ApplicationErrorReason: Equatable, Sendable, CustomStringConvertible {
    public let value: String

    public var description: String {
        value
    }

    public var id: String {
        value
    }

    public static let unknown = Self("unknown")
    public static let noInternetConnection = Self("noInternetConnection")
    public static let isForbidden = Self("isForbidden")
    public static let isCancelled = Self("isCancelled")
    public static let deviceStorageFull = Self("deviceStorageFull")
    public static let urlConnection = Self("urlConnection")
    public static let decoding = Self("decoding")

    public init(_ value: String) {
        self.value = value
    }
}

public struct ApplicationErrorOrigin: Equatable, Sendable, CustomStringConvertible {
    public let value: String

    public var description: String {
        value
    }

    public var id: String {
        value
    }

    public static let api = Self("api")
    public static let auth = Self("auth")

    public init(_ value: String) {
        self.value = value
    }
}

public struct ApplicationError: Error, Equatable, Sendable, CustomStringConvertible {
    public let recoveryHint: ApplicationErrorRecoveryHint
    public let reason: ApplicationErrorReason
    public let message: String
    public let origin: ApplicationErrorOrigin
    public let code: Int
    public let file: String
    public let line: UInt
    public let id = UUID().uuidString

    public var description: String {
        var description = "\(file):\(line)"
        if code != 0 {
            description += "; code:\(code)"
        }
        if reason != .unknown {
            description += "; reason:\(reason)"
        }
        if !message.isEmpty {
            description += "; \(message)"
        }
        return description
    }

    public static func == (lhs: ApplicationError, rhs: ApplicationError) -> Bool {
        lhs.recoveryHint == rhs.recoveryHint
            && lhs.reason == rhs.reason
            && lhs.origin == rhs.origin
            && lhs.code == rhs.code
            && lhs.message == rhs.message
    }

    public init(
        recoveryHint: ApplicationErrorRecoveryHint = .retry,
        reason: ApplicationErrorReason = .unknown,
        origin: ApplicationErrorOrigin = .api,
        code: Int = 0,
        file: String = #file,
        line: UInt = #line,
        message: String = ""
    ) {
        self.recoveryHint = recoveryHint
        self.reason = reason
        self.message = message
        self.origin = origin
        self.code = code
        self.file = URL(string: file)?.lastPathComponent ?? file
        self.line = line
    }
}

extension ApplicationError {
    public static func nsError(
        recoveryHint: ApplicationErrorRecoveryHint = .retry,
        origin: ApplicationErrorOrigin,
        nsError: NSError,
        message: String = "",
        file: String = #file,
        line: UInt = #line
    ) -> ApplicationError {
        if let appError = nsError as? ApplicationError { return appError }
        let reason = Self.getReason(nsError: nsError)

        let recoveryHint: ApplicationErrorRecoveryHint = switch reason {
        case .deviceStorageFull: .freeDeviceStorage
        case .noInternetConnection: .connectToInternet
        default: .retry
        }

        // Debug message contains details like pointers, private type,
        // we can keep the message clean if we know the reason.
        // If the reason is unknown - then adding a debug description
        // helps us detect new reasons and add new reasons above
        let debugMessage = switch reason {
        case .unknown: " debug: \(nsError.debugDescription)"
        default: ""
        }

        return ApplicationError(
            recoveryHint: recoveryHint,
            reason: reason,
            origin: origin,
            code: nsError.code,
            file: file,
            line: line,
            message: message + debugMessage
        )
    }

    private static func getReason(nsError: NSError) -> ApplicationErrorReason {
        switch nsError.domain {
        case String(kCFErrorDomainCFNetwork): getURLErrorReason(code: nsError.code)
        case NSURLErrorDomain: getURLErrorReason(code: nsError.code)
        case "CoreMediaErrorDomain": getCoreMediaErrorDomainReason(code: nsError.code)
        default: .unknown
        }
    }

    private static func getURLErrorReason(code: Int) -> ApplicationErrorReason {
        // see file: CFNetworkErrors.h
        switch code {
        case NSURLErrorNotConnectedToInternet: .noInternetConnection
        case NSURLErrorNetworkConnectionLost: .noInternetConnection
        case NSURLErrorDataNotAllowed: .noInternetConnection
        case NSURLErrorCancelled: .isCancelled
        case NSURLErrorNoPermissionsToReadFile: .isForbidden
        case -2000 ... -996: .urlConnection
        default: .unknown
        }
    }

    private static func getCoreMediaErrorDomainReason(code: Int) -> ApplicationErrorReason {
        // Impossible to find any C header file with those codes described
        // debug description of NSError revealed following codes:
        //
        // CoreMediaErrorDomain Code=-16850 "HTTP 504: Gateway Timeout"
        // CoreMediaErrorDomain Code=-16849 "HTTP 503: Service Unavailable"
        // CoreMediaErrorDomain Code=-16848 "HTTP 502: Bad Gateway"
        // CoreMediaErrorDomain Code=-16847 "HTTP 500: Internal Server Error"
        // CoreMediaErrorDomain Code=-16845 "HTTP 400: (unhandled)"
        //
        // CoreMediaErrorDomain Code=-12668 "HTTP 410: Gone"
        // CoreMediaErrorDomain Code=-12660 "HTTP 403: Forbidden"
        switch code {
        case 28: .deviceStorageFull
        case -12660, -16850, -16849, -12668, -16845, -16847, -16848: .urlConnection
        default: .unknown
        }
    }
}
