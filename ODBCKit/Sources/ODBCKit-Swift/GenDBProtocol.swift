import Foundation

public enum DbConnectionState : Int8 {
    case disconnected = 0
    case connecting = 1
    case connected = 2
    case busy = 3
}

/*
// MARK: - GenDBField Protocol

/// Protocol for accessing field data in a database result set
public protocol GenDBField {
    func asString() -> String?
    func asString(encoding: String.Encoding) -> String?
    func asNumber() -> NSNumber?
    func asShort() -> Int16
    func asLong() -> Int64
    func asDate() -> Date?
    func asDate(gmtOffset: String) -> Date?
    func asData() -> Data?
    func isNull() -> Bool

    /// The default encoding for string operations
    var defaultEncoding: String.Encoding { get set }
}

// MARK: - GenDBRecord Protocol

/// Protocol for a single record (or row) in a result set
public protocol GenDBRecord {
    func fieldByIndex(_ fieldIndex: Int) -> GenDBField?
    func fieldByName(_ name: String) -> GenDBField?

    /// The default encoding for string operations
    var defaultEncoding: String.Encoding { get set }
}

// MARK: - GenDBColumn Protocol

/// Protocol for metadata about columns in a result set
public protocol GenDBColumn {
    var name: String { get }
    var index: Int { get }
    var type: Int { get }
    var size: Int { get }
    var offset: Int { get }
}

// MARK: - GenDBRecordset Protocol

/// Protocol for accessing a set of records (rows) returned from a query
public protocol GenDBRecordset {
    func fieldByIndex(_ fieldIndex: Int) -> GenDBField?
    func fieldByName(_ fieldName: String) -> GenDBField?
    func close()

    var columns: [GenDBColumn] { get }
    var rowCount: Int { get }

    func moveFirst() -> GenDBRecord?
    func movePrevious() -> GenDBRecord?
    func moveNext() -> GenDBRecord?
    func moveLast() -> GenDBRecord?

    var isEOF: Bool { get }
    var lastError: String? { get }

    /// Converts the current record into a dictionary
    func dictionaryFromRecord() -> [String: Any]

    /// The default encoding for string operations
    var defaultEncoding: String.Encoding { get set }
}
*/
// MARK: - GenDBConnection Protocol

/// Protocol for managing connections to a database
public protocol GenDBConnection: AnyObject {
    /// Connection status
    var state : DbConnectionState { get }
    var userName: String { get set }
    var password: String { get set }
    var enableCursors: Bool { get set }

    var isConnected: Bool { get }
    var connectionString: String { get set }
    var datasourceFilter: String? { get set }
    
    /// The default encoding for string operations
    var defaultEncoding: String.Encoding { get set }

    /// Connection management
    func close() -> Bool
    func connect() -> Bool
    func connectAsync()
    
    /// Command execution
    @discardableResult func execCommand(_ sql: String) -> Int
    func execCommandAsync(_ sql: String)

    /// Opening resultsets
    // func open(_ sql: String) -> GenDBRecordset?
    func openAsync(_ sql: String)

    /// Error reporting
    var lastError: String? { get }

    /// Cloning
    func clone() -> GenDBConnection
}

// MARK: - Notifications

/// Notifications for database actions
public enum GenDBConnectionNotifications {
    public static let connectionDidComplete = Notification.Name("GenDBConnectionDidCompleteNotification")
    public static let commandDidComplete = Notification.Name("GenDBCommandDidCompleteNotification")
}

