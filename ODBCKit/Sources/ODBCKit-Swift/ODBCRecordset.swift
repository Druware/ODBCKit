//
//  ODBCRecordset.swift
//  Convert from TrustWin
//
//  Converted to Swift on 1/24/26.
//  Original created by Andy Satori on 7/7/06.
//  Copyright 2006 Druware Software Designs. All rights reserved.
//

/* License *********************************************************************
 
 Copyright (c) 2005-2009, Druware Software Designs
 All rights reserved.
 
 Redistribution and use in source or binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1. Redistributions in source or binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 2. Neither the name of the Druware Software Designs nor the names of its
 contributors may be used to endorse or promote products derived from this
 software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 *******************************************************************************/

import Foundation
import Cocoa

public class ODBCRecordset {
    
    // MARK: - Private Properties
    
    private var odbcConn: SQLHANDLE?
    private var odbcDbc: SQLHANDLE?
    private var odbcStmt: SQLHANDLE?
    
    public var isEOF: Bool = true
    public var isOpen: Bool = true
    
    public var lastError: String?
    
    // Internal behaviors
    private var cursorsEnabled: Bool = false
    private var usePseudoCursors: Bool = false
    private var currentPosition: UInt = 0
    private var pseudoCursorResults: [ODBCRecord] = []
    
    private var _rowCount: Int = 0
    public var rowCount: Int {
        get {
            // If using pseudoCursors we have a count in memory that is more accurate
            // than rowCount is. Use that instead.
            if cursorsEnabled && usePseudoCursors {
                return pseudoCursorResults.count
            }
            return _rowCount
        }
        set { _rowCount = newValue }
    }
    public var columns: [ODBCColumn] = []
    public var currentRecord: ODBCRecord?
    public var defaultEncoding: String.Encoding
    
    // MARK: - Initialization
    
    init?(connection henv: SQLHANDLE?,
          database hdbc: SQLHANDLE?,
          statement hstmt: SQLHANDLE?,
          enableCursors: Bool,
          encoding: String.Encoding) {
        
        self.isOpen = true
        self.isEOF = true
        
        self.odbcConn = henv
        self.odbcDbc = hdbc
        self.odbcStmt = hstmt
        
        // Set the default to what was passed in
        self.defaultEncoding = encoding
        
        // Does the consumer want cursors?
        self.cursorsEnabled = enableCursors
        
        
        // Does the driver support cursors?
        if cursorsEnabled {
            self.usePseudoCursors = !connectionSupportsCursors()
        }
        
        // Ask the results for the number of rows that were returned
        var rowCount: Int = 0
        if !SQL_SUCCEEDED(SQLRowCount(hstmt, &rowCount)) {
            rowCount = 0
        }
        self.rowCount = rowCount
        
        // And set the current position to the top of the set
        currentPosition = 0
        
        // Cache the column list for faster data access via lookups by name
        // Loop through and get the fields into Field Item Classes
        
        // Ask the statement how many cols are in the results
        var iCols: Int16 = 0
        if !SQL_SUCCEEDED(SQLNumResultCols(hstmt, &iCols)) {
            iCols = 0
        }
        
        // If no columns, we're at EOF
        if iCols == 0 {
            self.isEOF = true
            return
        }
        
        // Now we loop over the columns and cache the data about each one into the columns collection
        for i in 1...Int(iCols) {
            if let column = ODBCColumn(
                connection: odbcConn!,
                database: odbcDbc!,
                statement: odbcStmt!,
                index: Int32(i),
                encoding: defaultEncoding
            ) {
                columns.append(column)
            }
        }
        
        isEOF = false
        
        // If cursors are disabled, create a pseudo cursor and fetch all the rows
        // here and put them into the pseudoCursorResults array
        if cursorsEnabled {
            if usePseudoCursors {
                // Create the recordset array and set the current position to 0
                while !isEOF {
                    currentRecord = nil
                    
                    guard let stmt = odbcStmt else { break }
                    
                    let nResult = SQLFetch(stmt)
                    if !SQL_SUCCEEDED(nResult) {
                        if nResult == SQL_NO_DATA_FOUND {
                            break
                        } else {
                            // logError(nResult, forStatement: odbcStmt)
                            break
                        }
                    }
                    
                    let result = ODBCRecord(
                        connection: odbcConn,
                        database: odbcDbc,
                        statement: odbcStmt,
                        columns: columns,
                        encoding: defaultEncoding
                    )
                    
                    pseudoCursorResults.append(result)
                }
                
                isEOF = false
                currentPosition = 0
                if !pseudoCursorResults.isEmpty {
                    currentRecord = pseudoCursorResults[0]
                }
            }
        } else {
            currentRecord = moveNext()
        }
    }
    
    deinit {
        // Clean up things
        close()
    }
    
    // MARK: - Error Logging
    
    private func logError(_ result: Int16, forStatement stmt: SQLHANDLE?) {
        /*
        var szErrState = [UInt8](repeating: 0, count: Int(SQL_SQLSTATE_SIZE) + 1)
        var szErrText = [UInt8](repeating: 0, count: Int(SQL_MAX_MESSAGE_LENGTH) + 1)
        var szBuffer = [CChar](repeating: 0, count: Int(SQL_SQLSTATE_SIZE + SQL_MAX_MESSAGE_LENGTH) + 1024 + 1)
        var szDispBuffer = [CChar](repeating: 0, count: Int(SQL_SQLSTATE_SIZE + SQL_MAX_MESSAGE_LENGTH) + 1024 + 1)
        
        var wErrMsgLen: Int16 = 0
        var dwErrCode: UInt32 = 0
        var bErrorFound = false
        
        szBuffer[0] = 0
        strcpy(&szDispBuffer, szBuffer)
        
        var nErrResult = SQLError(
            odbcConn,
            odbcDbc,
            stmt,
            &szErrState,
            &dwErrCode,
            &szErrText,
            Int16(SQL_MAX_MESSAGE_LENGTH - 1),
            &wErrMsgLen
        )
        
        while (nErrResult == SQL_SUCCESS || nErrResult == SQL_SUCCESS_WITH_INFO) && dwErrCode != UInt32(SQL_NO_DATA_FOUND) {
            if dwErrCode != 5701 && dwErrCode != 5703 && dwErrCode != 1805 {
                let format = "SQL Error State:%s, Native Error Code: %lX, ODBC Error: %s"
                snprintf(&szBuffer, szBuffer.count, format, szErrState, dwErrCode, szErrText)
                
                let iSize = strlen(szDispBuffer)
                if iSize > 0 && (iSize + strlen(szBuffer) + 1) >= 1024 {
                    break
                }
                if iSize > 0 {
                    strcat(&szDispBuffer, "\n")
                }
                strcat(&szDispBuffer, szBuffer)
                bErrorFound = true
            }
            
            nErrResult = SQLError(
                odbcConn,
                odbcDbc,
                stmt,
                &szErrState,
                &dwErrCode,
                &szErrText,
                Int16(SQL_MAX_MESSAGE_LENGTH - 1),
                &wErrMsgLen
            )
        }
        
        if !bErrorFound {
            return
        }
        
        let errorString = String(cString: szDispBuffer)
        NSLog("%@", errorString)
        */
    }
    
    // MARK: - Helper Methods
    
    private func connectionSupportsCursors() -> Bool {
        guard let stmt = odbcStmt else { return false }
        
        var value: Int = 0
        var cbValue: Int32 = 0
        
        let nResult = SQLGetStmtAttr(
            stmt,
            Int32(SQL_ATTR_CURSOR_SCROLLABLE),
            &value,
            Int32(SQL_IS_INTEGER),
            &cbValue
        )
        
        if nResult != SQL_SUCCESS {
            logError(Int16(nResult), forStatement: stmt)
        }
        
        return value != 0
    }
    
    // MARK: - GenDBRecordset Protocol
    
    func fieldByName(_ fieldName: String) -> ODBCField? {
        return currentRecord?.fieldByName(fieldName)
    }
    
    func fieldByIndex(_ fieldIndex: Int) -> ODBCField? {
        return currentRecord?.fieldByIndex(fieldIndex)
    }
    
    func close() {
        if isOpen {
            if usePseudoCursors {
                pseudoCursorResults.removeAll()
            }
            
            if !usePseudoCursors {
                currentRecord = nil
            }
            
            // Clear columns
            columns.removeAll()
            
            if let stmt = odbcStmt {
                _ = SQLFreeStmt(stmt, UInt16(SQL_CLOSE))
            }
        }
        isOpen = false
    }
    
    

    
    func movePrevious() -> ODBCRecord? {
        if !cursorsEnabled {
            lastError = "Only forward reading allowed"
            return nil
        }
        
        if usePseudoCursors {
            // Use the pseudoCursorArray
            currentPosition -= 1
            guard currentPosition >= 0 && currentPosition < pseudoCursorResults.count else {
                return nil
            }
            currentRecord = pseudoCursorResults[Int(currentPosition)]
            return currentRecord
        } else {
            guard let stmt = odbcStmt else { return nil }
            
            currentPosition -= 1
            let nResult = SQLSetPos(
                stmt,
                SQLSETPOSIROW(currentPosition),
                UInt16(SQL_REFRESH),
                UInt16(SQL_LOCK_NO_CHANGE)
            )
            
            if !SQL_SUCCEEDED(Int16(nResult)) {
                if nResult == SQL_NO_DATA_FOUND {
                    isEOF = true
                } else {
                    logError(Int16(nResult), forStatement: stmt)
                }
            }
            
            let result = ODBCRecord(
                connection: odbcConn,
                database: odbcDbc,
                statement: odbcStmt,
                columns: columns,
                encoding: defaultEncoding
            )
            result.defaultEncoding = defaultEncoding
            
            currentRecord = result
            return currentRecord
        }
    }
    
    func moveNext() -> ODBCRecord? {
        // If we are using pseudoCursors then we simply return the next item in the array
        if usePseudoCursors {
            currentPosition += 1
            if currentPosition >= pseudoCursorResults.count {
                isEOF = true
                return nil
            }
            currentRecord = pseudoCursorResults[Int(currentPosition)]
            return currentRecord
        }
        // Otherwise we're going to use the SQL cursor machinery to do this for us
        else {
            guard let stmt = odbcStmt else { return nil }
            
            currentPosition += 1
            
            // Dispose of any existing currentRecord
            currentRecord = nil
            
            // The open method uses SQLExecute to send the query to the server, but
            // it does not directly return data. One of the variety of SQLFetch
            // statements is used for that...
            let nResult = SQLFetch(stmt)
            if nResult != SQL_SUCCESS {
                if nResult == SQL_NO_DATA_FOUND {
                    isEOF = true
                    return nil
                } else {
                    logError(nResult, forStatement: stmt)
                    return nil
                }
            }
            
            // ... and this code reads the results back out of the statement
            // structure and into our own storage
            let result = ODBCRecord(
                connection: odbcConn,
                database: odbcDbc,
                statement: odbcStmt,
                columns: columns,
                encoding: defaultEncoding
            )
            currentRecord = result
            return currentRecord
        }
    }
    
    func moveFirst() -> ODBCRecord? {
        if usePseudoCursors {
            // Use the pseudoCursorArray
            currentPosition = 0
            if currentPosition >= pseudoCursorResults.count {
                isEOF = true
                return nil
            }
            currentRecord = pseudoCursorResults[Int(currentPosition)]
            return currentRecord
        } else {
            if !cursorsEnabled {
                lastError = "Only forward reading allowed"
                return nil
            }
            
            guard let stmt = odbcStmt else { return nil }
            
            // Dispose any current record
            currentRecord = nil
            
            // Set the position at the top of the records
            currentPosition = 0
            
            let nResult = SQLSetPos(
                stmt,
                1,
                UInt16(SQL_POSITION),
                UInt16(SQL_LOCK_NO_CHANGE)
            )
            
            if !SQL_SUCCEEDED(Int16(nResult)) {
                if nResult == SQL_NO_DATA_FOUND {
                    isEOF = true
                } else {
                    logError(Int16(nResult), forStatement: stmt)
                }
            }
            
            let result = ODBCRecord(
                connection: odbcConn,
                database: odbcDbc,
                statement: odbcStmt,
                columns: columns,
                encoding: defaultEncoding
            )
            result.defaultEncoding = defaultEncoding
            currentRecord = result
            return currentRecord
        }
    }
    
    func moveLast() -> ODBCRecord? {
        if usePseudoCursors {
            // Use the pseudoCursorArray
            currentPosition = UInt(pseudoCursorResults.count - 1)
            if currentPosition >= pseudoCursorResults.count || currentPosition < 0 {
                isEOF = true
                return nil
            }
            currentRecord = pseudoCursorResults[Int(currentPosition)]
            return currentRecord
        } else {
            if !cursorsEnabled {
                lastError = "Only forward reading allowed"
                return nil
            }
            
            guard let stmt = odbcStmt else { return nil }
            
            // Dispose any current record
            currentRecord = nil
            
            // Fetch and set the currentPosition to the last row in the table
            var lastPosition: Int = 0
            let nResult = SQLRowCount(stmt, &lastPosition)
            if !SQL_SUCCEEDED(Int16(nResult)) {
                logError(Int16(nResult), forStatement: stmt)
                return nil
            }
            
            // SQLRowCount returns -1 for Firebird, which is a problem
            if lastPosition <= 0 {
                logError(-1, forStatement: stmt)
                return nil
            }
            
            currentPosition = UInt(lastPosition)
            
            // Now set the cursor position to that row
            let setPosResult = SQLSetPos(
                stmt,
                SQLSETPOSIROW(currentPosition),
                UInt16(SQL_REFRESH),
                UInt16(SQL_LOCK_NO_CHANGE)
            )
            
            if !SQL_SUCCEEDED(Int16(setPosResult)) {
                if setPosResult == SQL_NO_DATA_FOUND {
                    isEOF = true
                } else {
                    logError(Int16(setPosResult), forStatement: stmt)
                }
            }
            
            // Now fetch and store the record at that location, and return it
            let result = ODBCRecord(
                connection: odbcConn,
                database: odbcDbc,
                statement: odbcStmt,
                columns: columns,
                encoding: defaultEncoding
            )
            currentRecord = result
            return currentRecord
        }
    }
        
    func dictionaryFromRecord() -> [String: Any] {
        var dict: [String: Any] = [:]
        
        for i in 0..<columns.count {
            let column = columns[i]
            let columnName = column.name?.lowercased()
            if columnName == nil { continue }
            
            // For each column, add the value for the key
            switch Int16(column.type) {
            case SQL_UNKNOWN_TYPE:
                if let field = fieldByName(columnName!) {
                    dict[columnName!] = field.asData()
                }
                
            case SQL_CHAR, SQL_VARCHAR:
                if let field = fieldByName(columnName!) {
                    dict[columnName!] = field.asString()
                }
                
            case SQL_NUMERIC, SQL_DECIMAL, SQL_INTEGER, SQL_SMALLINT, SQL_FLOAT, SQL_REAL, SQL_DOUBLE:
                if let field = fieldByName(columnName!) {
                    dict[columnName!] = field.asNumber()
                }
                
            case SQL_DATETIME, Int16(SQL_TIMESTAMP):
                if let field = fieldByName(columnName!) {
                    dict[columnName!] = field.asDate()
                }
                
            default:
                if let field = fieldByName(columnName!) {
                    dict[columnName!] = field.asData()
                }
            }
        }
        
        return dict
    }
    
}
