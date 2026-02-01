//
//  ODBCApi.swift
//  ODBCKit-Swift
//
//  Created by Andrew Satori on 1/23/26.
//
import Foundation

/// Represents errors that can occur during ODBC operations.
public enum ODBCError: Error {
    /// A runtime error occurred with an associated error message.
    case runtimeError(String)
}

/// Represents an ODBC driver with its name and attributes.
public struct ODBCDriver {
    /// The name/description of the ODBC driver.
    public var name: String
    
    /// The attributes string containing driver configuration details.
    /// Attributes are typically null-separated key-value pairs.
    public var attributes: String
}

/// A utility structure providing static methods for interacting with ODBC (Open Database Connectivity).
///
/// This structure provides high-level access to ODBC functionality including:
/// - Retrieving error information from ODBC handles
/// - Enumerating available data sources
/// - Enumerating installed ODBC drivers
public struct ODBC {
    /// Retrieves diagnostic error information from an ODBC handle.
    ///
    /// This method queries the ODBC diagnostic records to obtain detailed error information
    /// including SQL state, native error code, and descriptive error message.
    ///
    /// - Parameters:
    ///   - handleType: The type of handle being queried (e.g., `SQL_HANDLE_ENV`, `SQL_HANDLE_DBC`, `SQL_HANDLE_STMT`).
    ///   - handle: The ODBC handle from which to retrieve diagnostic information.
    ///   - forStatement: An optional statement handle for context (currently unused).
    ///
    /// - Returns: A formatted string containing the SQL state, native error code, and error message.
    ///            Returns a generic failure message if diagnostic information cannot be retrieved.
    static func getError(_ handleType: SQLSMALLINT, _ handle: SQLHANDLE, _ forStatement: SQLHANDLE?) -> String {
        let sqlState = UnsafeMutablePointer<CChar>.allocate(capacity: 6)
        let errorMessage = UnsafeMutablePointer<CChar>.allocate(capacity: SQL_MAX_MESSAGE_LENGTH)
        let nativeError: UnsafeMutablePointer<SQLINTEGER> = .allocate(capacity: 1)
        let textLength: UnsafeMutablePointer<SQLSMALLINT> = .allocate(capacity: 1)
        
        let result = SQLGetDiagRec(handleType,
                                   handle, 1,
                                   sqlState, nativeError,
                                   errorMessage,
                                   SQLSMALLINT(SQL_MAX_MESSAGE_LENGTH),
                                   textLength)
        if result == SQL_SUCCESS {
            let errorState = String(utf8String: sqlState)
            let errorString = String(utf8String: errorMessage)
            return "SQL Error State: \(errorState ?? "unknown"), Native Error Code: \(nativeError), ODBC Error: \(errorString ?? "unknown")"
        } else {
            return "Failed to retrieve diagnostic message."
        }
    }
    
    /// Retrieves a list of available ODBC data source names (DSNs).
    ///
    /// This method enumerates all configured ODBC data sources on the system, including both
    /// user DSNs and system DSNs. It allocates an ODBC environment handle, sets the ODBC version
    /// to 3.x, and iterates through all available data sources.
    ///
    /// - Returns: An array of data source names. Returns an empty array if the environment
    ///            cannot be allocated or if no data sources are available.
    ///
    /// - Note: This method properly allocates and deallocates ODBC handles, ensuring no resource leaks.
    static func datasources() -> [String] {
        var environmentHandle: SQLHENV?
        
        // allocate the environment handle
        var hEnv: SQLHANDLE = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<SQLHANDLE>.size, alignment: 1)
        var sqlResult = SQLAllocHandle(SQL_HANDLE_ENV, nil, &hEnv)
        if (!SQL_SUCCEEDED(sqlResult))
        {
            return []
        }
        environmentHandle = hEnv
        
        // set the ODBC Version
        let odbcVersion = SQL_OV_ODBC3
        sqlResult = SQLSetEnvAttr(environmentHandle, SQL_ATTR_ODBC_VERSION, UnsafePointer<SQLINTEGER>(bitPattern: Int(odbcVersion)), 0)
        if (!SQL_SUCCEEDED(sqlResult))
        {
            return []
        }

        // get the driver list
        
        var results: [String] = []
        let nameBuffer = UnsafeMutablePointer<CChar>.allocate(capacity: SQL_MAX_DSN_LENGTH + 1)
        let descBuffer = UnsafeMutablePointer<CChar>.allocate(capacity: SQL_MAX_MESSAGE_LENGTH + 1)
        var nameLength: SQLSMALLINT = 0
        var descLength: SQLSMALLINT = 0
        
        var fetchResult = SQLDataSources(environmentHandle,
                                         SQL_FETCH_FIRST,
                                         nameBuffer,
                                         SQLSMALLINT(SQL_MAX_DSN_LENGTH),
                                         &nameLength,
                                         descBuffer,
                                         SQLSMALLINT(SQL_MAX_MESSAGE_LENGTH),
                                         &descLength)
        
        while fetchResult == SQL_SUCCESS || fetchResult == SQL_SUCCESS_WITH_INFO {
            let name = String(utf8String: nameBuffer)
            results.append(name ?? "")
            fetchResult = SQLDataSources(environmentHandle,
                                         SQL_FETCH_NEXT,
                                         nameBuffer,
                                         SQLSMALLINT(SQL_MAX_DSN_LENGTH),
                                         &nameLength,
                                         descBuffer,
                                         SQLSMALLINT(SQL_MAX_MESSAGE_LENGTH),
                                         &descLength)        }
        
        // free the environment
        if let env = environmentHandle {
            _ = SQLFreeHandle(SQL_HANDLE_ENV, env)
            environmentHandle = nil
        }
        
        // return the results
        return results
    }
    
    /// Retrieves a list of installed ODBC drivers on the system.
    ///
    /// This method enumerates all ODBC drivers registered with the ODBC Driver Manager.
    /// For each driver, it retrieves the driver description (name) and associated attributes.
    ///
    /// - Returns: An array of `ODBCDriver` structures containing driver names and attributes.
    ///            Returns an empty array if the environment cannot be allocated or if no drivers are installed.
    ///
    /// - Note: Driver attributes are returned as a string that may contain null-separated key-value pairs
    ///         representing driver capabilities and configuration options.
    static func drivers() -> [ODBCDriver] {
        var environmentHandle: SQLHENV?
        
        // allocate the environment handle
        var hEnv: SQLHANDLE = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<SQLHANDLE>.size, alignment: 1)
        var sqlResult = SQLAllocHandle(SQL_HANDLE_ENV, nil, &hEnv)
        if (!SQL_SUCCEEDED(sqlResult))
        {
            return []
        }
        environmentHandle = hEnv
        
        // set the ODBC Version
        let odbcVersion = SQL_OV_ODBC3
        sqlResult = SQLSetEnvAttr(environmentHandle, SQL_ATTR_ODBC_VERSION, UnsafePointer<SQLINTEGER>(bitPattern: Int(odbcVersion)), 0)
        if (!SQL_SUCCEEDED(sqlResult))
        {
            return []
        }

        // get the driver list
        var results: [ODBCDriver] = []
        
        // Buffers for description and attributes
        var desc = [SQLCHAR](repeating: 0, count: 256)
        var attrs = [SQLCHAR](repeating: 0, count: 512)
        var outDescLen: SQLSMALLINT = 0
        var outAttrsLen: SQLSMALLINT = 0

        // First fetch
        var rc = SQLDrivers(
            environmentHandle!,
            SQLUSMALLINT(SQL_FETCH_FIRST),
            &desc,
            SQLSMALLINT(desc.count),
            &outDescLen,
            &attrs,
            SQLSMALLINT(attrs.count),
            &outAttrsLen
        )
        
        while rc == 0 /* SQL_SUCCESS */ || rc == 1 /* SQL_SUCCESS_WITH_INFO */ {
            // Convert C unsigned char buffer to Swift String
            let descStr = desc.withUnsafeBufferPointer { buf -> String in
                let len = Int(outDescLen)
                return String(bytes: buf.prefix(len).map { UInt8($0) }, encoding: .utf8) ?? ""
            }
            let attrsStr = attrs.withUnsafeBufferPointer { buf -> String in
                let len = Int(outAttrsLen)
                return String(bytes: buf.prefix(len).map { UInt8($0) }, encoding: .utf8) ?? ""
            }

            let driver: ODBCDriver = ODBCDriver(name: "\(descStr)", attributes: "\(attrsStr)")
            results.append(driver)

            // Next fetch
            outDescLen = 0
            outAttrsLen = 0
            desc.withUnsafeMutableBufferPointer { buf in buf.initialize(repeating: 0) }
            attrs.withUnsafeMutableBufferPointer { buf in buf.initialize(repeating: 0) }

            rc = SQLDrivers(
                environmentHandle!,
                SQLUSMALLINT(SQL_FETCH_NEXT),
                &desc,
                SQLSMALLINT(desc.count),
                &outDescLen,
                &attrs,
                SQLSMALLINT(attrs.count),
                &outAttrsLen
            )
        }

        
        // free the environment
        if let env = environmentHandle {
            _ = SQLFreeHandle(SQL_HANDLE_ENV, env)
            environmentHandle = nil
        }
        
        // return the results
        return results
    }
    
}
