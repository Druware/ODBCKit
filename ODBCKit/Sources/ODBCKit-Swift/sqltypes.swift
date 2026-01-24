//
//  sqltypes.swift
//
//  ODBC typedefs
//
//  The iODBC driver manager.
//
//  Converted to Swift by DruSatori, 2026
//
//  Copyright (C) 1995 by Ke Jin <kejin@empress.com>
//  Copyright (C) 1996-2013 by OpenLink Software <iodbc@openlinksw.com>
//  All Rights Reserved.
//
//  This software is released under the terms of either of the following licenses:
//
//      - GNU Library General Public License (see LICENSE.LGPL)
//      - The BSD License (see LICENSE.BSD).
//

import Foundation


#if canImport(UIKit)
import UIKit
#endif

// Environment-specific definitions
public typealias EXPORT = Void

public typealias SQL_API = Void

// API declaration data types
public typealias SQLCHAR = UInt8
public typealias SQLSMALLINT = Int16
public typealias SQLUSMALLINT = UInt16
public typealias SQLINTEGER = Int32
public typealias SQLUINTEGER = UInt32
public typealias SQLPOINTER = UnsafeMutableRawPointer?

// Optional ODBC 3.0+ types
public typealias SQLSCHAR = Int8
public typealias SQLDATE = UInt8
public typealias SQLDECIMAL = UInt8
public typealias SQLNUMERIC = UInt8
public typealias SQLDOUBLE = Double
public typealias SQLFLOAT = Double
public typealias SQLREAL = Float
public typealias SQLTIME = UInt8
public typealias SQLTIMESTAMP = UInt8
public typealias SQLVARCHAR = UInt8

// Win64 datatypes
#if arch(x86_64) || os(Windows)
public typealias SQLLEN = Int64
public typealias SQLULEN = UInt64
public typealias SQLSETPOSIROW = UInt64
#else
public typealias SQLLEN = Int
public typealias SQLULEN = UInt
public typealias SQLSETPOSIROW = UInt16
#endif

// Backward compatibility
public typealias SQLROWCOUNT = SQLULEN
public typealias SQLROWSETSIZE = SQLULEN
public typealias SQLTRANSID = SQLULEN
public typealias SQLROWOFFSET = SQLLEN

// Generic pointer types
public typealias PTR = UnsafeMutableRawPointer?
public typealias SQLHANDLE = UnsafeMutableRawPointer

// Handles
public typealias HENV = UnsafeMutableRawPointer?
public typealias HDBC = UnsafeMutableRawPointer?
public typealias HSTMT = UnsafeMutableRawPointer?

public typealias SQLHENV = SQLHANDLE
public typealias SQLHDBC = SQLHANDLE
public typealias SQLHSTMT = SQLHANDLE
public typealias SQLHDESC = SQLHANDLE

// Window Handle
#if os(Windows)
public typealias SQLHWND = HWND
#elseif os(macOS)
import AppKit
public typealias SQLHWND = NSWindow
#else
public typealias SQLHWND = UnsafeMutableRawPointer?
#endif

// SQL portable types for C
public typealias UCHAR = UInt8
public typealias SCHAR = Int8
public typealias SWORD = Int16
public typealias UWORD = UInt16
public typealias SDWORD = Int32
public typealias UDWORD = UInt32
public typealias SSHORT = Int16
public typealias USHORT = UInt16
public typealias SLONG = Int32
public typealias ULONG = UInt32
public typealias SFLOAT = Float
public typealias SDOUBLE = Double
public typealias LDOUBLE = Double

// Return type for functions
public typealias RETCODE = Int16
public typealias SQLRETURN = SQLSMALLINT

// SQL portable types for C - DATA, TIME, TIMESTAMP, and BOOKMARK
public typealias BOOKMARK = SQLULEN

public struct DATE_STRUCT {
    public var year: SQLSMALLINT
    public var month: SQLUSMALLINT
    public var day: SQLUSMALLINT
}

public typealias SQL_DATE_STRUCT = DATE_STRUCT

public struct TIME_STRUCT {
    public var hour: SQLUSMALLINT
    public var minute: SQLUSMALLINT
    public var second: SQLUSMALLINT
}

public typealias SQL_TIME_STRUCT = TIME_STRUCT

public struct TIMESTAMP_STRUCT {
    public var year: SQLSMALLINT
    public var month: SQLUSMALLINT
    public var day: SQLUSMALLINT
    public var hour: SQLSMALLINT
    public var minute: SQLSMALLINT
    public var second: SQLSMALLINT
    public var fraction: SQLUINTEGER
}

public typealias SQL_TIMESTAMP_STRUCT = TIMESTAMP_STRUCT

// Enumeration for DATETIME_INTERVAL_SUBCODE values
public enum SQLINTERVAL: Int {
    case SQL_IS_YEAR = 1
    case SQL_IS_MONTH
    case SQL_IS_DAY
    case SQL_IS_HOUR
    case SQL_IS_MINUTE
    case SQL_IS_SECOND
    case SQL_IS_YEAR_TO_MONTH
    case SQL_IS_DAY_TO_HOUR
    case SQL_IS_DAY_TO_MINUTE
    case SQL_IS_DAY_TO_SECOND
    case SQL_IS_HOUR_TO_MINUTE
    case SQL_IS_HOUR_TO_SECOND
    case SQL_IS_MINUTE_TO_SECOND
}

public struct SQL_YEAR_MONTH_STRUCT {
    public var year: SQLUINTEGER
    public var month: SQLUINTEGER
}

public struct SQL_DAY_SECOND_STRUCT {
    public var day: SQLUINTEGER
    public var hour: SQLUINTEGER
    public var minute: SQLUINTEGER
    public var second: SQLUINTEGER
    public var fraction: SQLUINTEGER
}

public struct SQL_INTERVAL_STRUCT {
    public var interval_type: SQLINTERVAL
    public var interval_sign: SQLSMALLINT
    public var intval: SQL_YEAR_MONTH_STRUCT
}

// ODBC C types for SQL_C_SBIGINT and SQL_C_UBIGINT
public typealias SQLBIGINT = Int64
public typealias SQLUBIGINT = UInt64

// Internal representation of numeric data type
public let SQL_MAX_NUMERIC_LEN = 16
public struct SQL_NUMERIC_STRUCT {
    public var precision: SQLCHAR
    public var scale: SQLSCHAR
    public var sign: SQLCHAR
    public var val: [SQLCHAR]
    
    public init() {
        precision = 0
        scale = 0
        sign = 0
        val = [SQLCHAR](repeating: 0, count: SQL_MAX_NUMERIC_LEN)
    }
}

// GUID type for SQLGUID
#if canImport(Foundation)
import Foundation

public typealias SQLGUID = UUID
#else
public struct SQLGUID {
    public var Data1: UInt32
    public var Data2: UInt16
    public var Data3: UInt16
    public var Data4: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)
}
#endif

// Wide character and TCHAR definitions
#if os(Windows)
public typealias SQLWCHAR = UInt16
#else
public typealias SQLWCHAR = UnicodeScalar
#endif

public typealias SQLTCHAR = String
