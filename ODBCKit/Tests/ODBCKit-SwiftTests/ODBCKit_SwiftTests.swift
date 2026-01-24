import Testing
@testable import ODBCKit_Swift

/// Tests synchronous ODBC database connection using a DSN (Data Source Name).
///
/// This test verifies the complete connection lifecycle for an ODBC connection:
/// 1. Validates that the ODBC environment is properly initialized
/// 2. Configures connection parameters (DSN, username, and password)
/// 3. Establishes a connection to the database
/// 4. Closes the connection and verifies disconnection
///
/// The test uses a DSN named "TrusteeSQLDB" with SQL Server authentication.
///
/// - Throws: An error if any of the connection assertions fail
@Test func testODBCConnectionWithDsn() async throws {
    // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    let connection = ODBCConnection()
    #expect(connection.isEnvironmentValid)
    Swift.print(connection.lastError ?? "No Error")
    
    // set the parameters
    connection.connectionString = "TrusteeSQLDB"
    #expect(connection.connectionString == "TrusteeSQLDB")
    connection.userName = "sa"
    #expect(connection.userName == "sa")
    connection.password = "Just4Dev@"
    #expect(connection.password == "Just4Dev@")
    
    // try the connection
    #expect(connection.connect() == true)
    Swift.print(connection.lastError ?? "No Error")
    
    // close the connection
    connection.close()
    #expect(connection.isConnected == false)
}

/// Tests asynchronous ODBC database connection using a DSN (Data Source Name).
///
/// This test verifies the complete asynchronous connection lifecycle for an ODBC connection:
/// 1. Validates that the ODBC environment is properly initialized
/// 2. Configures connection parameters (DSN, username, and password)
/// 3. Establishes a connection to the database asynchronously using `connectAsync()`
/// 4. Closes the connection and verifies disconnection
///
/// The test uses a DSN named "TrusteeSQLDB" with SQL Server authentication.
/// Unlike `testODBCConnectionWithDsn()`, this test uses the asynchronous connection
/// method which is suitable for Swift Concurrency contexts.
///
/// - Throws: An error if any of the connection assertions fail
@Test func testODBCConnectionWithDsnAsync() async throws {
    // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    let connection = ODBCConnection()
    #expect(connection.isEnvironmentValid)
    Swift.print(connection.lastError ?? "No Error")
    
    // set the parameters
    connection.connectionString = "TrusteeSQLDB"
    #expect(connection.connectionString == "TrusteeSQLDB")
    connection.userName = "sa"
    #expect(connection.userName == "sa")
    connection.password = "Just4Dev@"
    #expect(connection.password == "Just4Dev@")
    
    // try the connection
    #expect(await connection.connectAsync())
    Swift.print(connection.lastError ?? "No Error")
    
    // close the connection
    connection.close()
    #expect(connection.isConnected == false)
}

/// Tests ODBC command execution capabilities for DDL and DML operations.
///
/// This test verifies the ability to execute SQL commands through an ODBC connection:
/// 1. Establishes an asynchronous connection to the database
/// 2. Executes a CREATE TABLE statement and validates the return value (-1 for DDL)
/// 3. Executes an INSERT statement and validates the affected row count (1)
/// 4. Executes a DROP TABLE statement and validates the return value (-1 for DDL)
/// 5. Closes the connection and verifies disconnection
///
/// The test demonstrates that `execCommand()` returns:
/// - `-1` for DDL operations (CREATE, DROP) that don't return row counts
/// - The number of affected rows for DML operations (INSERT, UPDATE, DELETE)
///
/// The test uses a temporary table named "execCommandTest" to ensure isolation.
///
/// - Throws: An error if any of the SQL execution or connection assertions fail
@Test func testODBCConnectionExecCommand() async throws {
    // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    let connection = ODBCConnection()
    #expect(connection.isEnvironmentValid)
    Swift.print(connection.lastError ?? "No Error")
    
    // set the parameters
    connection.connectionString = "TrusteeSQLDB"
    #expect(connection.connectionString == "TrusteeSQLDB")
    connection.userName = "sa"
    #expect(connection.userName == "sa")
    connection.password = "Just4Dev@"
    #expect(connection.password == "Just4Dev@")
    
    // try the connection
    #expect(await connection.connectAsync())
    Swift.print(connection.lastError ?? "No Error")
    
    // try the sql
    let createCount = connection.execCommand("create table execCommandTest ( id varchar(10) null )")
    #expect (createCount == -1)
    let insertCount = connection.execCommand("insert into execCommandTest ( id ) values ( 'testing' )")
    #expect (insertCount == 1)
    let dropCount = connection.execCommand("drop table execCommandTest")
    #expect (dropCount == -1)
    
    // close the connection
    connection.close()
    #expect(connection.isConnected == false)
}

@Test func testODBCConnectionOpen() async throws {
    // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    let connection = ODBCConnection()
    #expect(connection.isEnvironmentValid)
    Swift.print(connection.lastError ?? "No Error")
    
    // set the parameters
    connection.connectionString = "TrusteeSQLDB"
    #expect(connection.connectionString == "TrusteeSQLDB")
    connection.userName = "sa"
    #expect(connection.userName == "sa")
    connection.password = "Just4Dev@"
    #expect(connection.password == "Just4Dev@")
    
    // try the connection
    #expect(await connection.connectAsync())
    Swift.print(connection.lastError ?? "No Error")
    
    // try the sql
    let createCount = connection.execCommand("create table execCommandTest ( id varchar(10) null )")
    #expect (createCount == -1)
    let insertCount = connection.execCommand("insert into execCommandTest ( id ) values ( 'testing' )")
    #expect (insertCount == 1)
    let rs = connection.open("select * from execCommandTest")
    #expect (rs != nil)
    _ = rs?.moveFirst()
    #expect(rs?.fieldByIndex(0)?.asString() == "testing")
    
    let dropCount = connection.execCommand("drop table execCommandTest")
    #expect (dropCount == -1)
    
    // close the connection
    connection.close()
    #expect(connection.isConnected == false)
}
