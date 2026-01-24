//
//  ODBCField.swift
//
//  Created by Andy Satori on 7/13/06.
//  Copyright 2006-2011 Druware Software Designs. All rights reserved.
//

/* License *********************************************************************
 
 Copyright (c) 2006-2026, Druware Software Designs
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

public class ODBCField {
    private var odbcConn: UnsafeMutableRawPointer?
    private var odbcDbc: UnsafeMutableRawPointer?
    private var odbcStmt: UnsafeMutableRawPointer?
    
    private var data: Data?
    private var column: ODBCColumn?
    public var defaultEncoding: String.Encoding = .utf8
    
    init?(connection hEnv: UnsafeMutableRawPointer?,
          database hDbc: UnsafeMutableRawPointer?,
          statement hStmt: UnsafeMutableRawPointer?,
          column: ODBCColumn,
          encoding: String.Encoding) {
        self.odbcConn = hEnv
        self.odbcDbc = hDbc
        self.odbcStmt = hStmt
        self.column = column
        self.defaultEncoding = encoding
        
        let columnSize = column.size
        guard columnSize != 0 else {
            return nil
        }
        
        var bufferSize = columnSize
        let columnType = Int16(column.type)
        if columnType == SQL_VARCHAR || columnType == SQL_CHAR {
            bufferSize = columnSize * 2
        }
        
        if columnSize == -1 {
            bufferSize = 32767 // Fallback size if SQLGetData fails for size
        }
        
        let buffer = UnsafeMutablePointer<Int8>.allocate(capacity: bufferSize + 1)
        defer { buffer.deallocate() }
        
        var length: Int = 0
        let resultCode = SQLGetData(hStmt, SQLUSMALLINT(column.index), SQL_C_CHAR, buffer, bufferSize, &length)
        guard SQL_SUCCEEDED(resultCode) else {
            // Swift.print(ODBC.getError(SQL_HANDLE_STMT, ))
            // logError(resultCode, statement: hStmt)
            return nil
        }
        
        if length > 0 {
            self.data = Data(bytes: buffer, count: length)
        }
    }
    
    deinit {
        data = nil // Explicitly nil out
    }
    
    func asString() -> String? {
        guard let data = data, !data.isEmpty else { return nil }
        return String(data: data, encoding: defaultEncoding)
    }
    
    func asString(encoding: String.Encoding) -> String? {
        guard let data = data, !data.isEmpty else { return nil }
        return String(data: data, encoding: encoding)
    }
    
    func asNumber() -> NSNumber? {
        guard let string = asString(),
              let floatValue = Float(string) else { return nil }
        return NSNumber(value: floatValue)
    }
    
    func asShort() -> Int16 {
        guard let string = asString(),
              let floatValue = Float(string) else { return 0 }
        return Int16(floatValue)
    }
    
    func asLong() -> Int {
        guard let string = asString(),
              let floatValue = Float(string) else { return 0 }
        return Int(floatValue)
    }
    
    func asDate() -> Date? {
        guard let string = asString() else { return nil }
        let value = string.contains(".") ? String(string.prefix(while: { $0 != "." })) + " +0000" : string + " +0000"
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        return formatter.date(from: value)
    }
    
    func asDate(withGMTOffset gmtOffset: String) -> Date? {
        guard let string = asString() else { return nil }
        let value = string.contains(".") ?
            String(string.prefix(while: { $0 != "." })) + " " + gmtOffset :
            string + " " + gmtOffset
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        return formatter.date(from: value)
    }
    
    func asData() -> Data? {
        guard let data = data, !data.isEmpty else { return nil }
        return data
    }
    
    func isNull() -> Bool {
        return data == nil
    }
    

    
}
