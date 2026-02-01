# ODBCKit-swift

This is a work in progress of a full port of the ODBCKit from Objective-C to
Swift. It will eventually replace the Objective-C API.

## Dependencies

### Swift Package Manager

*   [ODBCKit](https://www.druware.com/products/ODBCKit)
                
    ### Homebrew
              
    *   [libiodbc](https://formulae.brew.sh/formula/libiodbc)
    
## History

2026-02-01 - Continuing Port and UnitTesting

* Added support for connections using ConnectionStrings not just DSN's
* Moved Datasources list function to static ODBC class
* Moved Drivers list function to static ODBC class
* Added unittests to all of the above
* Added documentation to the ODBC class.
                   
