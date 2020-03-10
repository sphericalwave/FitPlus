//
//  Log.swift
//  CNIOAtomics
//
//  Created by Aaron Anthony on 2020-03-09.
//

import Foundation

class Log
{
    var logs: String
    
    init() {
        self.logs = ""
    }
    
    func log(_ string: String) {
        logs.append(string)
        logs.append("\n")
    }
    
    func print() {
        Swift.print(logs)   //FIXME: Why do i need this?
    }
}
