//
//  iodbc-imports.swift
//  ODBCKit-Swift
//
//  Created by Andrew Satori on 1/23/26.
//

// MARK: - ODBC C Library Bindings

@_silgen_name("SQLAllocHandle")
internal func SQLAllocHandle(
    _ handleType: SQLSMALLINT,
    _ inputHandle: SQLHANDLE?,
    _ outputHandle: UnsafeMutablePointer<SQLHANDLE>
) -> SQLRETURN

@_silgen_name("SQLConnect")
internal func SQLConnect(
    _ connectionHandle: SQLHANDLE?,
    _ serverName: UnsafePointer<SQLCHAR>?,
    _ nameLength1: SQLSMALLINT,
    _ userName: UnsafePointer<SQLCHAR>?,
    _ nameLength2: SQLSMALLINT,
    _ authentication: UnsafePointer<SQLCHAR>?,
    _ nameLength3: SQLSMALLINT
) -> SQLRETURN

@_silgen_name("SQLColAttribute")
func SQLColAttribute(
    _ StatementHandle: SQLHANDLE?,
    _ ColumnNumber: UInt16,
    _ FieldIdentifier: UInt16,
    _ CharacterAttributePtr: UnsafeMutableRawPointer?,
    _ BufferLength: Int16,
    _ StringLengthPtr: UnsafeMutablePointer<Int16>?,
    _ NumericAttributePtr: UnsafeMutablePointer<Int>?
) -> Int16

@_silgen_name("SQLDisconnect")
internal func SQLDisconnect(
    _ connectionHandle: SQLHANDLE?
) -> SQLRETURN

@_silgen_name("SQLDataSources")
internal func SQLDataSources(
    _ environmentHandle: SQLHANDLE?,
    _ direction: SQLSMALLINT,
    _ dataSourceName: UnsafeMutablePointer<CChar>?,
    _ bufferLength1: SQLSMALLINT,
    _ nameLength1: UnsafeMutablePointer<SQLSMALLINT>?,
    _ description: UnsafeMutablePointer<CChar>?,
    _ bufferLength2: SQLSMALLINT,
    _ nameLength2: UnsafeMutablePointer<SQLSMALLINT>?
) -> SQLRETURN

@_silgen_name("SQLDescribeCol")
func SQLDescribeCol(
    _ statementHandle: SQLHANDLE?,
    _ columnNumber: UInt16,
    _ columnName: UnsafeMutablePointer<CChar>?,
    _ bufferLength: Int16,
    _ nameLengthPtr: UnsafeMutablePointer<Int16>?,
    _ dataTypePtr: UnsafeMutablePointer<Int16>?,
    _ columnSizePtr: UnsafeMutablePointer<UInt>?,
    _ decimalDigitsPtr: UnsafeMutablePointer<Int16>?,
    _ nullablePtr: UnsafeMutablePointer<Int16>?
) -> Int16

@_silgen_name("SQLExecDirect")
internal func SQLExecDirect(
    _ statementHandle: SQLHANDLE?,
    _ statementText: UnsafePointer<SQLCHAR>?,
    _ textLength: SQLINTEGER
) -> SQLRETURN

@_silgen_name("SQLError")
internal func SQLError(
    _ environmentHandle: SQLHANDLE?,
    _ connectionHandle: SQLHANDLE?,
    _ statementHandle: SQLHANDLE?,
    _ SQLState: UnsafeMutablePointer<CChar>?,
    _ nativeError: UnsafeMutablePointer<SQLINTEGER>?,
    _ messageText: UnsafeMutablePointer<CChar>?,
    _ bufferLength: SQLSMALLINT,
    _ textLength: UnsafeMutablePointer<SQLSMALLINT>?
) -> SQLRETURN

@_silgen_name("SQLFetch")
internal func SQLFetch(
    _ statementHandle: SQLHANDLE?
) -> SQLRETURN

@_silgen_name("SQLGetData")
internal func SQLGetData(
    _ statementHandle: SQLHANDLE?,
    _ columnNumber: SQLUSMALLINT,
    _ targetType: SQLSMALLINT,
    _ targetValue: UnsafeMutableRawPointer?,
    _ bufferLength: SQLLEN,
    _ strLen_or_Ind: UnsafeMutablePointer<SQLLEN>?
) -> SQLRETURN

@_silgen_name("SQLGetStmtAttr")
internal func SQLGetStmtAttr(
    _ statementHandle: SQLHANDLE?,
    _ attribute: SQLINTEGER,
    _ valuePtr: UnsafeMutableRawPointer?,
    _ bufferLength: SQLINTEGER,
    _ stringLengthPtr: UnsafeMutablePointer<SQLINTEGER>?
) -> SQLRETURN

@_silgen_name("SQLFreeHandle")
internal func SQLFreeHandle(
    _ handleType: SQLSMALLINT,
    _ handle: SQLHANDLE?
) -> SQLRETURN

@_silgen_name("SQLFreeStmt")
internal func SQLFreeStmt(
    _ statementHandle: SQLHANDLE?,
    _ option: SQLUSMALLINT
) -> SQLRETURN

@_silgen_name("SQLGetDiagRec")
func SQLGetDiagRec(
    _ handleType: SQLSMALLINT,
    _ handle: SQLHANDLE?,
    _ recNumber: SQLSMALLINT,
    _ SQLState: UnsafeMutablePointer<CChar>?,
    _ nativeError: UnsafeMutablePointer<SQLINTEGER>?,
    _ messageText: UnsafeMutablePointer<CChar>?,
    _ bufferLength: SQLSMALLINT,
    _ textLength: UnsafeMutablePointer<SQLSMALLINT>?
) -> SQLRETURN

@_silgen_name("SQLNumResultCols")
internal func SQLNumResultCols(
    _ statementHandle: SQLHANDLE?,
    _ columnCount: UnsafeMutablePointer<SQLSMALLINT>?
) -> SQLRETURN

@_silgen_name("SQLRowCount")
internal func SQLRowCount(
    _ statementHandle: SQLHANDLE?,
    _ rowCount: UnsafeMutablePointer<SQLLEN>?
) -> SQLRETURN

@_silgen_name("SQLSetConnectOption")
internal func SQLSetConnectOption(
    _ connectionHandle: SQLHDBC?,
    _ option: SQLUSMALLINT,
    _ value: SQLULEN
) -> SQLRETURN

@_silgen_name("SQLSetEnvAttr")
internal func SQLSetEnvAttr(
    _ environmentHandle: SQLHANDLE?,
    _ attribute: SQLINTEGER,
    _ valuePtr: UnsafePointer<SQLINTEGER>?,
    _ stringLength: SQLINTEGER
) -> SQLRETURN

@_silgen_name("SQLSetPos")
internal func SQLSetPos(
    _ statementHandle: SQLHANDLE?,
    _ rowNumber: SQLSETPOSIROW,
    _ operation: SQLUSMALLINT,
    _ lockType: SQLUSMALLINT
) -> SQLRETURN

@_silgen_name("SQLSetStmtAttr")
internal func SQLSetStmtAttr(
    _ statementHandle: SQLHANDLE?,
    _ attribute: SQLINTEGER,
    _ valuePtr: UnsafeMutableRawPointer?,
    _ stringLength: SQLINTEGER
) -> SQLRETURN













