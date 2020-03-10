//
//  main.swift
//  NioHttpServerPackageDescription
//
//  Created by Aaron Anthony on 2020-02-21.
//

import NIO

let logs = Log()
let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
let server = Server(logs: logs, eventLoopGroup: eventLoopGroup)
