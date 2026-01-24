//
//  ODBCApi.swift
//  ODBCKit-Swift
//
//  Created by Andrew Satori on 1/23/26.
//
import Foundation

public enum ODBCError: Error {
    case runtimeError(String)
}

public struct ODBC {
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
    
    // TODO: Add a getAllErrors() that wraps the SQLError behavior
}
