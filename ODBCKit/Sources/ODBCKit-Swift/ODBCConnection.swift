import Foundation

/// Represents the version of the ODBC API to use for database operations.
///
/// The ODBC version determines which features and behaviors are available when
/// interacting with ODBC drivers. This enumeration allows you to specify whether
/// to use ODBC 2.x or ODBC 3.x standards.
///
/// ## Overview
///
/// ODBC (Open Database Connectivity) has evolved through multiple versions, with
/// each version introducing new features and improvements. The version you choose
/// affects how the ODBC driver manager and drivers interpret your API calls.
///
/// ## Available Versions
///
/// - **ODBC 2.x**: An older version of the ODBC standard. Use this only if you
///   need compatibility with legacy systems or drivers that don't support ODBC 3.x.
///
/// - **ODBC 3.x**: The modern version of the ODBC standard, offering improved
///   features, better error handling, and enhanced standards compliance. This is
///   the recommended version for new applications.
///
/// ## Usage
///
/// The ODBC version is typically set during environment initialization and affects
/// the behavior of all subsequent ODBC operations:
///
/// ```swift
/// let connection = ODBCConnection()
/// // The version is automatically set to .v3 during initialization
/// ```
///
/// ## Version Differences
///
/// Key differences between ODBC 2.x and 3.x include:
/// - Enhanced descriptor handling in 3.x
/// - Improved date/time data type support in 3.x
/// - Better Unicode support in 3.x
/// - More detailed diagnostic information in 3.x
///
/// - Note: Once set for an environment handle, the ODBC version cannot be changed
///   without recreating the environment.
///
/// - SeeAlso: `ODBCConnection.setODBCVersion(_:)` for setting the version during initialization.
public enum ODBCVersion : SQLSMALLINT {
    case v2 = 2 // SQL_OV_ODBC2
    case v3 = 3 // SQL_OV_ODBC3
}

/// Represents a connection to an ODBC database using the ODBC API.
public final class ODBCConnection : @unchecked Sendable /*: GenDBConnection*/ {
    // MARK: - GenDB Properties
    
    public var state : DbConnectionState = .disconnected
    public var userName: String?
    public var password: String?
    
    /// The default encoding for string operations
    public var defaultEncoding: String.Encoding = .utf8

    public var isConnected: Bool { get {
        return self.state == .connected
    } }
    // public var connectionString: String { get set }
    // public var datasourceFilter: String? { get set }

    
    // MARK: - Properties
    private var environmnentVersion: ODBCVersion = .v3
    private var environmentHandle: SQLHENV?
    private var connectionHandle: SQLHDBC?
    public var isEnvironmentValid: Bool = false
    
    public var connectionString: String?
    
    public var lastError: String?
    
    // MARK: - Initialization and Cleanup
    
    public init() {
        self.isEnvironmentValid = self.initializeSQLEnvironment()
    }
    
    deinit {
        self.freeSQLEnvironment()
    }
    
    /// Initializes the ODBC environment handle required for database operations.
    ///
    /// This method allocates an ODBC environment handle and configures it for use with ODBC version 3.
    /// The environment handle is the top-level resource in the ODBC hierarchy and must be successfully
    /// created before any database connections can be established.
    ///
    /// The initialization process performs the following steps:
    /// 1. Allocates a new environment handle using `SQLAllocHandle`
    /// 2. Sets the ODBC version to 3.x (or the specified version)
    /// 3. Stores the handle in the `environmentHandle` property
    ///
    /// - Returns: `true` if the environment was successfully initialized, `false` otherwise.
    ///
    /// - Note: This method is called automatically during the initialization of an `ODBCConnection` instance.
    ///
    /// - Warning: If initialization fails, the `lastError` property is populated with details about the failure.
    ///   The environment handle will not be valid and subsequent connection attempts will fail.
    ///
    /// - SeeAlso: `freeSQLEnvironment()` for cleanup of the allocated resources.
    /// - SeeAlso: `setODBCVersion(_:)` for ODBC version configuration.
    private func initializeSQLEnvironment(_ version: ODBCVersion = .v3) -> Bool {
        // allocate the environment handle
        var hEnv: SQLHANDLE = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<SQLHANDLE>.size, alignment: 1)
        let sqlResult = SQLAllocHandle(SQL_HANDLE_ENV, nil, &hEnv)
        if (!SQL_SUCCEEDED(sqlResult))
        {
            lastError = "Failed to allocate ODBC environment handle."
            return false
        }
        environmentHandle = hEnv
        
        // set the ODBC Version
        if !setODBCVersion(version) {
            return false
        }
            
        return true
    }
    
    /// Sets the ODBC version to be used by the environment handle.
    ///
    /// This method configures the ODBC environment to operate with a specific version of the ODBC API.
    /// The version must be set after allocating the environment handle but before establishing any
    /// database connections. This is a required step in the ODBC initialization sequence.
    ///
    /// - Parameter version: The ODBC version to use. Can be either `.v2` for ODBC 2.x or `.v3` for ODBC 3.x.
    ///
    /// - Returns: `true` if the ODBC version was successfully set, `false` if the operation failed.
    ///
    /// - Note: ODBC 3.x is recommended for most modern applications as it provides enhanced features
    ///   and better standards compliance compared to ODBC 2.x.
    ///
    /// - Warning: If this method fails, the `lastError` property will contain diagnostic information
    ///   about the failure. The environment handle may not be usable for creating connections.
    ///
    /// - SeeAlso: `ODBCVersion` for available version options.
    /// - SeeAlso: `initializeSQLEnvironment()` which calls this method during environment setup.
    private func setODBCVersion(_ version: ODBCVersion) -> Bool {
        let odbcVersion = (version == .v3) ? SQL_OV_ODBC3 : SQL_OV_ODBC2
        let sqlResult = SQLSetEnvAttr(environmentHandle, SQL_ATTR_ODBC_VERSION, UnsafePointer<SQLINTEGER>(bitPattern: Int(odbcVersion)), 0)
        if (!SQL_SUCCEEDED(sqlResult))
        {
            lastError = handleError(type: SQL_HANDLE_ENV, handle: environmentHandle!)
            return false;
        }
        return true
    }
    
    /// Releases the ODBC environment handle and cleans up associated resources.
    ///
    /// This method frees the ODBC environment handle that was allocated during initialization.
    /// It should be called during cleanup to prevent resource leaks. The method checks if an
    /// environment handle exists before attempting to free it, and sets the handle to `nil`
    /// after freeing to prevent double-free errors.
    ///
    /// - Note: This method is called automatically in the `deinit` of `ODBCConnection`.
    /// - Warning: After calling this method, the environment handle becomes invalid and cannot be reused.
    private func freeSQLEnvironment() {
        if let env = self.environmentHandle {
            _ = SQLFreeHandle(SQL_HANDLE_ENV, env)
            self.environmentHandle = nil
        }
    }
    
    // MARK: - Diagnostics
    
    /// Retrieves diagnostic information from the ODBC driver when an error or warning occurs.
    ///
    /// This method queries the ODBC driver for detailed error information associated with a specific
    /// handle. It uses the `SQLGetDiagRec` function to extract diagnostic records and formats them
    /// into a human-readable error message.
    ///
    /// ## Diagnostic Information
    ///
    /// The method retrieves the following diagnostic details:
    /// - **SQL State**: A five-character SQLSTATE code indicating the type of error
    /// - **Native Error Code**: A driver-specific error code number
    /// - **Error Message**: A descriptive text message explaining the error
    ///
    /// ## Parameters
    ///
    /// - Parameter type: The type of handle being diagnosed. Must be one of:
    ///   - `SQL_HANDLE_ENV` for environment handles
    ///   - `SQL_HANDLE_DBC` for connection handles
    ///   - `SQL_HANDLE_STMT` for statement handles
    ///   - `SQL_HANDLE_DESC` for descriptor handles
    ///
    /// - Parameter handle: The ODBC handle from which to retrieve diagnostic information.
    ///   This should be the handle that was involved in the operation that failed.
    ///
    /// - Parameter forStatement: An optional statement handle to use for additional diagnostic
    ///   context. This parameter is currently unused but reserved for future extensions.
    ///   Defaults to `nil`.
    ///
    /// ## Return Value
    ///
    /// Returns a formatted string containing the diagnostic information in the following format:
    /// ```
    /// "SQL Error State: <SQLSTATE>, Native Error Code: <code>, ODBC Error: <message>"
    /// ```
    ///
    /// If the diagnostic record cannot be retrieved, returns:
    /// ```
    /// "Failed to retrieve diagnostic message."
    /// ```
    ///
    /// ## Example
    ///
    /// ```swift
    /// let connection = ODBCConnection()
    /// // ... attempt a connection that fails ...
    ///
    /// let errorMessage = connection.handleError(
    ///     type: SQL_HANDLE_DBC,
    ///     handle: connectionHandle
    /// )
    /// print(errorMessage)
    /// // Prints: "SQL Error State: 08001, Native Error Code: 2003, ODBC Error: Can't connect to MySQL server"
    /// ```
    ///
    /// ## Implementation Details
    ///
    /// The method allocates temporary buffers for:
    /// - A 6-byte buffer for the SQLSTATE (5 characters plus null terminator)
    /// - A buffer sized to `SQL_MAX_MESSAGE_LENGTH` for the error message text
    /// - Storage for the native error code and text length
    ///
    /// These buffers are automatically deallocated when the method returns.
    ///
    /// ## Thread Safety
    ///
    /// This method is not thread-safe. It should only be called on the same thread that
    /// performed the ODBC operation that generated the error.
    ///
    /// - Note: This method only retrieves the first diagnostic record. If multiple errors
    ///   occurred, subsequent records are not retrieved.
    ///
    /// - Warning: The error message is printed to the console using `Swift.print()` in
    ///   addition to being returned. This may produce duplicate output in some logging
    ///   configurations.
    ///
    /// - SeeAlso: `SQLGetDiagRec` for the underlying ODBC function.
    /// - SeeAlso: `SQL_MAX_MESSAGE_LENGTH` for the maximum error message size.
    private func handleError(type: SQLSMALLINT, handle: SQLHANDLE, forStatement statement: SQLHANDLE? = nil) -> String {
        let sqlState = UnsafeMutablePointer<CChar>.allocate(capacity: 6)
        let errorMessage = UnsafeMutablePointer<CChar>.allocate(capacity: SQL_MAX_MESSAGE_LENGTH)
        let nativeError: UnsafeMutablePointer<SQLINTEGER> = .allocate(capacity: 1)
        let textLength: UnsafeMutablePointer<SQLSMALLINT> = .allocate(capacity: 1)
        
        let result = SQLGetDiagRec(type,
                                   handle,
                                   1,
                                   sqlState,
                                   nativeError,
                                   errorMessage,
                                   SQLSMALLINT(SQL_MAX_MESSAGE_LENGTH),
                                   textLength)
        if result == SQL_SUCCESS {
            let errorState = String(utf8String: sqlState)
            let errorString = String(utf8String: errorMessage)
            Swift.print("SQL Error State: \(errorState ?? "unknown"), Native Error Code: \(nativeError), ODBC Error: \(errorString ?? "unknown")")
            return "SQL Error State: \(errorState ?? "unknown"), Native Error Code: \(nativeError), ODBC Error: \(errorString ?? "unknown")"
        } else {
            return "Failed to retrieve diagnostic message."
        }
    }
    
    // MARK: - GenDb Methods
    
    // TODO: rebuild the following to do an Async request, and then wrap the
    //       async version in a Task for a sync version.  As an additional
    //       option, implement a version that does a call back.
    
    /// Establishes a connection to an ODBC data source.
    ///
    /// This method creates a connection to the ODBC data source specified by the `dsn` property,
    /// using the credentials stored in `userName` and `password`. The connection process involves
    /// allocating a connection handle, configuring connection options, and establishing the actual
    /// database connection.
    ///
    /// ## Connection Process
    ///
    /// The method performs the following steps:
    /// 1. Validates that the environment handle is properly initialized
    /// 2. Allocates a new connection handle from the environment
    /// 3. Configures connection options (such as cursor usage)
    /// 4. Attempts to connect to the data source using the provided credentials
    /// 5. Updates the connection state based on the result
    ///
    /// ## Prerequisites
    ///
    /// Before calling this method, you must set the following properties:
    /// - `connectionString`: The data source name to connect to
    /// - `userName`: (Optional) The username for authentication
    /// - `password`: (Optional) The password for authentication
    ///
    /// ## State Management
    ///
    /// The method updates the `state` property throughout the connection process:
    /// - Sets to `.connecting` when the connection attempt begins
    /// - Sets to `.connected` on successful connection
    /// - Sets to `.disconnected` if any step fails
    ///
    /// ## Error Handling
    ///
    /// If the connection fails at any stage, the `lastError` property is populated with
    /// diagnostic information describing the failure. Common failure scenarios include:
    /// - Invalid or uninitialized environment handle
    /// - Failure to allocate a connection handle
    /// - Failure to set connection options
    /// - Authentication failures or data source unavailability
    ///
    /// ## Example
    ///
    /// ```swift
    /// let connection = ODBCConnection()
    /// connection.connectionString = "MyDataSource"
    /// connection.userName = "admin"
    /// connection.password = "secret"
    ///
    /// if connection.connect() {
    ///     print("Connected successfully")
    /// } else {
    ///     print("Connection failed: \(connection.lastError ?? "Unknown error")")
    /// }
    /// ```
    ///
    /// - Returns: `true` if the connection was established successfully, `false` otherwise.
    ///
    /// - Note: This method is synchronous and will block until the connection attempt completes.
    ///
    /// - Warning: Ensure that `close()` is called when the connection is no longer needed to
    ///   properly release database resources.
    ///
    /// - SeeAlso: `close()` for disconnecting and cleaning up the connection.
    /// - SeeAlso: `isConnected` to check the current connection status.
    /// - SeeAlso: `state` for the current connection state.
    public func connect() -> Bool {
        if (environmentHandle == nil) {
            lastError = "ODBC environment handle is not valid."
            return false
        }
        
        // get a connection handle
        self.state = .connecting
        
        var hConn: SQLHANDLE = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<SQLHANDLE>.size, alignment: 1)
        let allocResult = SQLAllocHandle(SQL_HANDLE_DBC, environmentHandle, &hConn)
        if (!SQL_SUCCEEDED(allocResult))
        {
            lastError = handleError(type: SQL_HANDLE_ENV, handle: environmentHandle!)
            state = .disconnected
            return false
        }
        connectionHandle = hConn
        
        // with the connection handle created, set the default options
    
        let nResult = SQLSetConnectOption(connectionHandle,
                                          SQLUSMALLINT(SQL_ODBC_CURSORS),
                                          SQLULEN(SQL_CUR_USE_IF_NEEDED));
        if (nResult != SQL_SUCCESS && nResult != SQL_SUCCESS_WITH_INFO) {
            lastError = handleError(type: SQL_HANDLE_DBC, handle: connectionHandle!)
            state = .disconnected
            return false
        }
        
        // now we try to establish the connection
        
        if (connectionString == nil) {
            lastError = "Connection String cannot be nil"
            state = .disconnected
            return false
        }
        
        var connectResult : SQLRETURN = SQL_ERROR
        
        if (connectionString!.contains("river="))
        {
            var iBufLen: SQLSMALLINT = 1024
            var outConnectionString: [CChar] = [CChar](repeating: 0, count: 1024)
            var connectionBytes = Array(connectionString!.utf8CString)
            connectResult = connectionBytes.withUnsafeMutableBufferPointer { buffer in
                buffer.baseAddress!.withMemoryRebound(to: SQLCHAR.self, capacity: buffer.count) { sqlcharPtr in
                    SQLDriverConnect(
                        connectionHandle!,
                        nil,
                        sqlcharPtr,
                        SQLSMALLINT(connectionString!.utf8.count),
                        &outConnectionString,
                        iBufLen,
                        &iBufLen,
                        SQLUSMALLINT(SQL_DRIVER_NOPROMPT))
                }
            }
        } else {
            let dsnString = connectionString ?? ""
            let userNameString = userName ?? ""
            let passwordString = password ?? ""
            
            connectResult = dsnString.withCString { dsnPtr in
                userNameString.withCString { userPtr in
                    passwordString.withCString { passPtr in
                        SQLConnect(connectionHandle,
                                   UnsafeRawPointer(dsnPtr).assumingMemoryBound(to: SQLCHAR.self),
                                   SQLSMALLINT(dsnString.utf8.count),
                                   UnsafeRawPointer(userPtr).assumingMemoryBound(to: SQLCHAR.self),
                                   SQLSMALLINT(userNameString.utf8.count),
                                   UnsafeRawPointer(passPtr).assumingMemoryBound(to: SQLCHAR.self),
                                   SQLSMALLINT(passwordString.utf8.count))
                    }
                }
            }
        }
        
        if (connectResult != SQL_SUCCESS && connectResult != SQL_SUCCESS_WITH_INFO) {
            lastError = handleError(type: SQL_HANDLE_DBC, handle: connectionHandle!)
            state = .disconnected
            return false
        }
    
        self.state = .connected
        return true
    }
    
    /// Asynchronously establishes a connection to an ODBC data source.
    ///
    /// This is an async version of `connect()` that performs the connection operation
    /// without blocking the calling thread. The connection is performed on a background
    /// task to avoid blocking the main thread or other important work.
    ///
    /// - Returns: `true` if the connection was established successfully, `false` otherwise.
    /// - Throws: Never throws, but returns `false` on failure with details in `lastError`.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let connection = ODBCConnection()
    /// connection.connectionString = "MyDataSource"
    /// connection.userName = "admin"
    /// connection.password = "secret"
    ///
    /// let success = await connection.connectAsync()
    /// if success {
    ///     print("Connected successfully")
    /// } else {
    ///     print("Connection failed: \(connection.lastError ?? "Unknown error")")
    /// }
    /// ```
    ///
    /// - SeeAlso: `connect()` for the synchronous version.
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func connectAsync() async -> Bool {
        // Perform the connection on a background thread since ODBC operations may block
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: false)
                    return
                }
                let result = self.connect()
                continuation.resume(returning: result)
            }
        }
    }
    
    /// Closes the active ODBC database connection and releases associated resources.
    ///
    /// This method disconnects from the currently connected ODBC data source and frees
    /// the connection handle that was allocated during the `connect()` operation. After
    /// calling this method, the connection state is set to `.disconnected` and the
    /// connection handle becomes invalid.
    ///
    /// ## Cleanup Process
    ///
    /// The method performs the following steps:
    /// 1. Verifies that a connection handle exists and the connection is active
    /// 2. Calls `SQLDisconnect` to terminate the database connection
    /// 3. Calls `SQLFreeHandle` to release the connection handle
    /// 4. Sets the connection handle to `nil` to prevent reuse
    /// 5. Updates the connection state to `.disconnected`
    ///
    /// ## Idempotency
    ///
    /// This method is safe to call multiple times. If there is no active connection or
    /// the connection handle is `nil`, the method returns without performing any operations.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let connection = ODBCConnection()
    /// connection.connectionString = "MyDataSource"
    /// connection.userName = "admin"
    /// connection.password = "secret"
    ///
    /// if connection.connect() {
    ///     // Perform database operations...
    ///     
    ///     // Clean up when finished
    ///     connection.close()
    /// }
    /// ```
    ///
    /// - Note: This method should be called when you are finished with a connection to
    ///   ensure that database resources are properly released. Failure to close connections
    ///   may lead to resource leaks.
    ///
    /// - Important: Any active statements or result sets associated with this connection
    ///   should be closed before calling this method to avoid potential resource issues.
    ///
    /// - SeeAlso: `connect()` for establishing a database connection.
    /// - SeeAlso: `isConnected` to check if a connection is currently active.
    /// - SeeAlso: `state` for the current connection state.
    public func close() {
        if let connection = self.connectionHandle, self.isConnected {
            _ = SQLDisconnect(connection)
            _ = SQLFreeHandle(SQL_HANDLE_DBC, connection)
            self.connectionHandle = nil
            self.state = .disconnected
        }
    }
    
    /// Executes a SQL command that does not return a result set.
    ///
    /// This method is designed for executing SQL statements that modify data or database structure,
    /// such as INSERT, UPDATE, DELETE, CREATE TABLE, or ALTER TABLE statements. It executes the
    /// command synchronously and returns the number of rows affected by the operation.
    ///
    /// ## Usage
    ///
    /// Use this method when you need to:
    /// - Insert, update, or delete records in a database
    /// - Create, alter, or drop database objects (tables, indexes, etc.)
    /// - Execute any SQL command that doesn't return a result set
    ///
    /// ## Execution Process
    ///
    /// The method performs the following steps:
    /// 1. Sets the connection state to `.busy`
    /// 2. Allocates a new statement handle
    /// 3. Executes the SQL command using `SQLExecDirect`
    /// 4. Retrieves the number of affected rows using `SQLRowCount`
    /// 5. Frees the statement handle
    /// 6. Restores the connection state to `.connected`
    ///
    /// ## Parameters
    ///
    /// - Parameter sql: The SQL command to execute. This should be a complete, valid SQL statement
    ///   in the syntax expected by the connected database. The command must not be a query that
    ///   returns a result set (use `open(_:)` for queries).
    ///
    /// ## Return Value
    ///
    /// Returns the number of rows affected by the SQL command. The specific meaning depends on
    /// the type of command:
    /// - For INSERT: The number of rows inserted
    /// - For UPDATE: The number of rows updated
    /// - For DELETE: The number of rows deleted
    /// - For DDL statements (CREATE, ALTER, DROP): Typically returns -1 or 0
    /// - On error: Returns 0 and sets the `lastError` property
    ///
    /// ## Error Handling
    ///
    /// If an error occurs during execution, the method:
    /// - Sets the `lastError` property with diagnostic information
    /// - Frees the statement handle to prevent resource leaks
    /// - Restores the connection state to `.connected`
    /// - Returns 0 to indicate failure
    ///
    /// Always check the `lastError` property after receiving a return value of 0 to determine
    /// if an error occurred or if the command legitimately affected zero rows.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let connection = ODBCConnection()
    /// connection.connectionString = "MyDataSource"
    /// connection.userName = "admin"
    /// connection.password = "secret"
    ///
    /// if connection.connect() {
    ///     // Insert a new record
    ///     let rowCount = connection.execCommand("INSERT INTO users (name, email) VALUES ('John', 'john@example.com')")
    ///     if rowCount > 0 {
    ///         print("Inserted \(rowCount) row(s)")
    ///     } else if let error = connection.lastError {
    ///         print("Error: \(error)")
    ///     }
    ///     
    ///     // Update existing records
    ///     let updated = connection.execCommand("UPDATE users SET active = 1 WHERE last_login > '2024-01-01'")
    ///     print("Updated \(updated) user(s)")
    ///     
    ///     connection.close()
    /// }
    /// ```
    ///
    /// ## State Management
    ///
    /// During execution, the connection state changes as follows:
    /// - Before execution: Must be `.connected`
    /// - During execution: Changed to `.busy`
    /// - After execution: Restored to `.connected` (regardless of success or failure)
    ///
    /// ## Thread Safety
    ///
    /// This method is not thread-safe. Do not call this method concurrently from multiple threads
    /// using the same connection instance. If you need concurrent database operations, create
    /// separate connection instances for each thread.
    ///
    /// - Note: For queries that return result sets (SELECT statements), use the `open(_:)` method instead.
    ///
    /// - Important: This method executes the SQL command synchronously and will block the calling
    ///   thread until the operation completes. For long-running commands, consider using an async
    ///   wrapper or executing on a background thread.
    ///
    /// - Warning: SQL injection vulnerabilities are possible if user input is directly concatenated
    ///   into the SQL string. Always validate and sanitize user input, or use parameterized queries
    ///   when available.
    ///
    /// - SeeAlso: `open(_:)` for executing queries that return result sets.
    /// - SeeAlso: `lastError` for retrieving detailed error information.
    /// - SeeAlso: `state` for monitoring the connection state during execution.
    public func execCommand(_ sql: String) -> Int
    {
        state = .busy
        var hStmt : SQLHANDLE = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<SQLHANDLE>.size, alignment: 1)
        var lRowCount: SQLLEN = 0
                
        let rc1: SQLRETURN = SQLAllocHandle(SQL_HANDLE_STMT, self.connectionHandle!, &hStmt)
        if (rc1 != SQL_SUCCESS && rc1 != SQL_SUCCESS_WITH_INFO) {
            lastError = handleError(type: SQL_HANDLE_STMT, handle: hStmt)
            _ = SQLFreeStmt(hStmt, SQLUSMALLINT(SQL_CLOSE));
            state = .connected
            return 0
        }
        
        let rc2: SQLRETURN = sql.withCString { sqlPtr in
            return SQLExecDirect(hStmt,
                          UnsafeRawPointer(sqlPtr).assumingMemoryBound(to: SQLCHAR.self),
                          SQLINTEGER(strlen(sql)))
        }
        if (rc2 != SQL_SUCCESS && rc2 != SQL_SUCCESS_WITH_INFO) {
            lastError = handleError(type: SQL_HANDLE_STMT, handle: hStmt)
            _ = SQLFreeStmt(hStmt, SQLUSMALLINT(SQL_CLOSE));
            state = .connected
            return 0
        }

        lRowCount = -1;
        _ = SQLRowCount(hStmt, &lRowCount);
        _ = SQLFreeStmt(hStmt, SQLUSMALLINT(SQL_CLOSE));
        state = .connected
        return lRowCount
    }
    
    /// Asynchronously executes a SQL command that does not return a result set.
    ///
    /// This is an async version of `execCommand(_:)` that performs the command execution
    /// without blocking the calling thread. The execution is performed on a background
    /// task to avoid blocking the main thread or other important work.
    ///
    /// ## Usage
    ///
    /// Use this method when you need to:
    /// - Execute INSERT, UPDATE, or DELETE statements asynchronously
    /// - Create, alter, or drop database objects without blocking
    /// - Perform any non-query SQL command in an async context
    ///
    /// ## Parameters
    ///
    /// - Parameter sql: The SQL command to execute. This should be a complete, valid SQL statement
    ///   in the syntax expected by the connected database. The command must not be a query that
    ///   returns a result set.
    ///
    /// ## Return Value
    ///
    /// Returns the number of rows affected by the SQL command:
    /// - For INSERT: The number of rows inserted
    /// - For UPDATE: The number of rows updated
    /// - For DELETE: The number of rows deleted
    /// - For DDL statements (CREATE, ALTER, DROP): Typically returns -1 or 0
    /// - On error: Returns 0 and sets the `lastError` property
    ///
    /// ## Error Handling
    ///
    /// If an error occurs during execution, the method returns 0 and sets the `lastError` property
    /// with diagnostic information. Always check `lastError` after receiving a return value of 0
    /// to distinguish between errors and commands that legitimately affected zero rows.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let connection = ODBCConnection()
    /// connection.connectionString = "MyDataSource"
    /// connection.userName = "admin"
    /// connection.password = "secret"
    ///
    /// if await connection.connectAsync() {
    ///     // Insert a new record asynchronously
    ///     let rowCount = await connection.execCommandAsync("INSERT INTO users (name, email) VALUES ('John', 'john@example.com')")
    ///     if rowCount > 0 {
    ///         print("Inserted \(rowCount) row(s)")
    ///     } else if let error = connection.lastError {
    ///         print("Error: \(error)")
    ///     }
    ///
    ///     // Update existing records asynchronously
    ///     let updated = await connection.execCommandAsync("UPDATE users SET active = 1 WHERE last_login > '2024-01-01'")
    ///     print("Updated \(updated) user(s)")
    ///
    ///     connection.close()
    /// }
    /// ```
    ///
    /// ## State Management
    ///
    /// During execution, the connection state changes as follows:
    /// - Before execution: Must be `.connected`
    /// - During execution: Changed to `.busy`
    /// - After execution: Restored to `.connected` (regardless of success or failure)
    ///
    /// ## Thread Safety
    ///
    /// This method executes the underlying ODBC operation on a background thread, making it
    /// safe to call from the main thread without blocking the UI. However, do not call this
    /// method concurrently from multiple tasks using the same connection instance.
    ///
    /// - Returns: The number of rows affected by the command, or 0 on error.
    ///
    /// - Note: For queries that return result sets (SELECT statements), you should implement
    ///   an async version of the `open(_:)` method instead.
    ///
    /// - Important: The underlying ODBC operation is inherently synchronous, so this method
    ///   offloads the work to a background thread to provide async behavior.
    ///
    /// - Warning: SQL injection vulnerabilities are possible if user input is directly concatenated
    ///   into the SQL string. Always validate and sanitize user input, or use parameterized queries
    ///   when available.
    ///
    /// - SeeAlso: `execCommand(_:)` for the synchronous version.
    /// - SeeAlso: `connectAsync()` for establishing an async connection.
    /// - SeeAlso: `lastError` for retrieving detailed error information.
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func execCommandAsync(_ sql: String) async -> Int {
        // Perform the command execution on a background thread since ODBC operations may block
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: 0)
                    return
                }
                let result = self.execCommand(sql)
                continuation.resume(returning: result)
            }
        }
    }
    
    // TODO: Add Support for Connection String usage
    
    public func open(_ sql: String) -> ODBCRecordset? {
        // get teh statement handle
        state = .busy
        var hStmt : SQLHANDLE = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<SQLHANDLE>.size, alignment: 1)
                
        let rc1: SQLRETURN = SQLAllocHandle(SQL_HANDLE_STMT, self.connectionHandle!, &hStmt)
        if (rc1 != SQL_SUCCESS && rc1 != SQL_SUCCESS_WITH_INFO) {
            lastError = handleError(type: SQL_HANDLE_STMT, handle: hStmt)
            _ = SQLFreeStmt(hStmt, SQLUSMALLINT(SQL_CLOSE));
            state = .connected
            return nil
        }
        
        // run the sql statement
        let rc2: SQLRETURN = sql.withCString { sqlPtr in
            return SQLExecDirect(hStmt,
                          UnsafeRawPointer(sqlPtr).assumingMemoryBound(to: SQLCHAR.self),
                          SQLINTEGER(strlen(sql)))
        }
        if (rc2 != SQL_SUCCESS && rc2 != SQL_SUCCESS_WITH_INFO) {
            lastError = handleError(type: SQL_HANDLE_STMT, handle: hStmt)
            _ = SQLFreeStmt(hStmt, SQLUSMALLINT(SQL_CLOSE));
            state = .connected
            return nil
        }
        
        // process the results
        let cbRowArraySize : UnsafeMutablePointer<SQLINTEGER> = .allocate(capacity: 1)

        let nResult = SQLSetStmtAttr(hStmt,
                                     SQLINTEGER(SQL_ROWSET_SIZE),
                                     cbRowArraySize,
                                     0);
        if ((nResult != SQL_SUCCESS) && (nResult != SQL_SUCCESS_WITH_INFO)) {
            // logError(nResult, forStatement:hStmt)
            return nil
        }
        
        let recordset = ODBCRecordset(connection: environmentHandle,
                                      database: connectionHandle,
                                      statement: hStmt,
                                      enableCursors: false,
                                      encoding: defaultEncoding)
        
        _ = SQLFreeStmt(hStmt, SQLUSMALLINT(SQL_CLOSE));
        state = .connected
        return recordset
    }

    
    // MARK: - System Queries
    

    

}
