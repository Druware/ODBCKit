//
//  ODBCIntrospection.swift
//  ODBCKit-Swift
//
//  Created by Andrew Satori on 1/24/26.
//

public final class ODBCIntrospection {
    var connection : ODBCConnection
    
    public init(_ connection: ODBCConnection) {
        self.connection = connection
    }
    
    /*
    // returns a list of all ODBC drivers known to the driver manager
    - (NSArray *)drivers
    {
        NSMutableArray *driverList = [[NSMutableArray alloc] init];
        
        SQLSMALLINT iDescLen;
        char szDesc[SQL_MAX_DSN_LENGTH];
        SQLSMALLINT iAttrLen;
        char szAttr[SQL_MAX_DSN_LENGTH];
        iAttrLen = SQL_MAX_DSN_LENGTH;
        iDescLen = SQL_MAX_DSN_LENGTH;
        
        SQLINTEGER nResult = SQLDrivers(henv, SQL_FETCH_FIRST, (SQLCHAR *)&szDesc, iDescLen, &iDescLen,
                                            (SQLCHAR *)&szAttr, iAttrLen, &iAttrLen);
        while (!SQL_SUCCEEDED(nResult))
        {
            NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
            
            NSString *name = [NSString stringWithCString:(char *)&szDesc encoding:defaultEncoding];
            [dict setValue:name forKey:@"description"];
            
            NSString *val =[NSString stringWithCString:(char *)&szAttr encoding:defaultEncoding];
            [dict setValue:val forKey:@"attributes"];
            
            [driverList addObject:dict];
        
            iAttrLen = SQL_MAX_DSN_LENGTH;
            iDescLen = SQL_MAX_DSN_LENGTH;
            nResult = SQLDrivers(henv, SQL_FETCH_NEXT, (SQLCHAR *)&szDesc, iDescLen, &iDescLen,
                                 (SQLCHAR *)&szAttr, iAttrLen, &iAttrLen);
        }
        
        return (NSArray *)driverList;
    }
    
    // looks through the datasources list for the current DSN and returns its driver name
    - (NSString *)driver
    {
        int i;
        NSArray *arr = [self datasources];
        for (i = 0; i < [arr count]; i++)
        {
            if ([dsn isEqualToString:[[arr objectAtIndex:i] valueForKey:@"name"]])
            {
                return [[arr objectAtIndex:i] valueForKey:@"description"];
            }
        }
        return nil;
    } */
    
    

    
    // MARK: - Schema Queries
    public func datasources() -> [String] {
        /*var results: [String] = []
        var nameBuffer = [CChar](repeating: 0, count: SQL_MAX_DSN_LENGTH)
        var descBuffer = [CChar](repeating: 0, count: SQL_MAX_MESSAGE_LENGTH)
        var bufferLength: SQLSMALLINT = 0
        
        var fetchResult = SQLDataSources(self.environmentHandle, SQL_FETCH_FIRST, &nameBuffer, SQLSMALLINT(nameBuffer.count), &bufferLength, &descBuffer, SQLSMALLINT(descBuffer.count), &bufferLength)
        
        while fetchResult == SQL_SUCCESS || fetchResult == SQL_SUCCESS_WITH_INFO {
            let name = String(cString: nameBuffer)
            results.append(name)
            fetchResult = SQLDataSources(self.environmentHandle, SQL_FETCH_NEXT, &nameBuffer, SQLSMALLINT(nameBuffer.count), &bufferLength, &descBuffer, SQLSMALLINT(descBuffer.count), &bufferLength)
        }
        
        return results
         */
        return []
    }
    
}
