//
//  File.swift
//  ODBCKit-Swift
//
//  Created by Andrew Satori on 2/1/26.
//

import Foundation

public extension Dictionary {
   var jsonData: Data? {
      return try? JSONSerialization.data(withJSONObject: self, options: [.prettyPrinted])
   }
       
   func toJSONString() -> String? {
      if let jsonData = jsonData {
         let jsonString = String(data: jsonData, encoding: .utf8)
         return jsonString
      }
      return nil
   }
}
