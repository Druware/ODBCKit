//
//  main.swift
//  odbcquery
//
//  Created by Andrew Satori on 2/1/26.
//

import Foundation
import ArgumentParser
import ODBCKit_Swift

struct ODBCQueryTool: ParsableCommand {
    @Option(name: .shortAndLong, help: "Connection String")
    var connectionString: String? = nil // optional
    
    @Option(name: .shortAndLong, help: "Datasource Name")
    var dsn: String? = nil // optional
    
    @Option(name: .shortAndLong, help: "User Name")
    var user: String? = nil // optional
    
    @Option(name: .shortAndLong, help: "Password")
    var password: String? = nil // optional
    
    @Option(name: .shortAndLong, help: "SQL File")
    var file: String? = nil // optional
    
    @Option(name: .shortAndLong, help: "SQL Command")
    var sql: String? = nil // optional
    
    @Option(name: .shortAndLong, help: "Verbose")
    var verbose: Bool = false
    
    private func sanityCheck() -> Bool {
        // look through the options to ensure that what we have in the options
        // are indeed sane forthe operation of this tool.
        
        // require either a sql command or sql file
        if (self.file == nil && self.sql == nil) {
            print("Must supply either a SQL file or a SQL command")
            return false
        }
        
        // require either a dsn or connection
        if (self.dsn == nil && self.connectionString == nil) {
            print("Must supply either a DSN or a Connection String")
            return false
        }
        
        // if a dsn is provided, the user and password are required
        if (self.dsn != nil && (self.user == nil || self.password == nil)) {
            print("When providing a DSN, both the User and Password are required")
            return false
        }
        
        return true
    }
    
    public func run() throws {
        // ensure that our start parameters are sane and usable
        if (!sanityCheck()) {
            if (verbose) {
                print ("Exiting")
            }
            return
        }
        
        // Startup
        if (self.verbose) {
            print("odbcquerytool")
            print("starting...")
        }
        
        // Set up the connection and go.
        let connection = ODBCConnection()
        if (!connection.isEnvironmentValid) {
            print("ODBC Envrionment failed to initialize")
            return
        }
        
        // connection properties
        if (self.dsn != nil) {
            connection.connectionString = self.dsn!
            connection.userName = self.user!
            connection.password = self.password!
        } else {
            connection.connectionString = self.connectionString!
        }
        if (!connection.connect()) {
            print("Failed to open the connection: \(connection.lastError ?? "")")
            return
        }
        
        // execute the command
        var sqlString : String = self.sql ?? ""
        
        // if the the file parameter exists, load the file instead
        if let filePath = self.file {
            do {
                sqlString = try String(contentsOfFile: filePath, encoding: .utf8)
                if (self.verbose) {
                    print("Loaded SQL from file: \(filePath)")
                }
            } catch {
                print("Failed to read SQL file '\(filePath)': \(error.localizedDescription)")
                connection.close()
                return
            }
        }
        
        // run the query, return the results
        let rs = connection.open(sqlString)
        if (!(rs?.isOpen ?? false)) {
            print("Failed to execute SQL: \(connection.lastError ?? "")")
            return
        }
        
        _ = rs?.moveFirst()
        print(rs!.dictionaryFromRecord())

        while ((rs!.moveNext()) != nil) {
            print(rs!.dictionaryFromRecord())
        }

        // close the connection and free the environment
        connection.close()
    }
}

ODBCQueryTool.main()

