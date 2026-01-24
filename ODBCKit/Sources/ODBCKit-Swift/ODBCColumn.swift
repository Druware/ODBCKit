//
//  ODBCColumn.swift
//  CaseClaims
//
//  Converted to Swift on 1/24/26.
//  Original created by Andy Satori on 7/13/06.
//  Copyright 2006-2010 Druware Software Designs. All rights reserved.
//

/* License *********************************************************************
 
 Copyright (c) 2005-2010, Druware Software Designs
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

public class ODBCColumn {
    
    // MARK: - Private Properties
    
    private var odbcConn: SQLHANDLE
    private var odbcDbc: SQLHANDLE
    private var odbcStmt: SQLHANDLE
    
    public var name: String?
    public var index: Int32
    public var type: UInt8
    public var size: Int
    public var offset: Int16
    
    public var defaultEncoding: String.Encoding
    
    public var isNullable: Bool
    public var isUnsigned: Bool
    public var isAutoIncrement: Bool
    
    // MARK: - Initialization
    
    init?(connection henv: SQLHANDLE,
          database hdbc: SQLHANDLE,
          statement hstmt: SQLHANDLE,
          index atIndex: Int32,
          encoding: String.Encoding) {
        
        let iBufLen = 256
        var szBuf = [CChar](repeating: 0, count: iBufLen)
        
        var iLength: UInt = 0
        var iNameLen: Int16 = 0
        var iType: Int16 = 0
        var iDec: Int16 = 0
        var iNullable: Int16 = 0
        
        self.odbcConn = henv
        self.odbcDbc = hdbc
        self.odbcStmt = hstmt
        self.index = atIndex
        
        self.defaultEncoding = encoding
        self.name = nil
        self.type = 0
        self.size = 0
        self.offset = 0
        self.isNullable = false
        self.isUnsigned = false
        self.isAutoIncrement = false
                
        let result = SQLDescribeCol(
                odbcStmt,
                UInt16(atIndex),
                &szBuf,
                Int16(iBufLen),
                &iNameLen,
                &iType,
                &iLength,
                &iDec,
                &iNullable
            )
        
        if SQL_SUCCEEDED(result) {
            // Truncate at null termination
            let nameLength = szBuf.firstIndex(of: 0) ?? szBuf.count
            let utf8Bytes = szBuf.prefix(nameLength).map { UInt8(bitPattern: $0) }
            self.name = String(decoding: utf8Bytes, as: UTF8.self)
            self.type = UInt8(iType)
            
            self.size = Int(iLength)
            if iType != SQL_VARCHAR && (iType < 0 || iType > 8) {
                self.size = -1
            }
            
            self.offset = iDec
            self.isNullable = (iNullable == SQL_NULLABLE)
            
            // Get the extended attributes
            let idx = UInt16(atIndex)
            var numericAttribute: Int = 0
            
            // Check for auto-increment
            numericAttribute = 0
            if SQL_SUCCEEDED(SQLColAttribute(
                odbcStmt,
                idx,
                UInt16(SQL_DESC_AUTO_UNIQUE_VALUE),
                nil,
                0,
                nil,
                &numericAttribute
            )) {
                self.isAutoIncrement = (numericAttribute == SQL_TRUE)
            }
            
            // Check for unsigned
            numericAttribute = 0
            if SQL_SUCCEEDED(SQLColAttribute(
                odbcStmt,
                idx,
                UInt16(SQL_DESC_UNSIGNED),
                nil,
                0,
                nil,
                &numericAttribute
            )) {
                self.isUnsigned = (numericAttribute == SQL_TRUE)
            }
            
            // Would like to check the keys, to do that, this needs to check the
            // primary keys based upon the associated table name
            // (chain lookup SQLColAttribute and SQLPrimaryKeys)
        }
    }
    
}

