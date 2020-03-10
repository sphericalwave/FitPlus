//
//  main.swift
//  NioHttpServerPackageDescription
//
//  Created by Aaron Anthony on 2020-02-21.
//

import NIO

let logs = Log()
let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
let threadPool = NIOThreadPool(numberOfThreads: 6)
//threadPool.start()
let fileIO = NonBlockingFileIO(threadPool: threadPool)
let server = Server(logs: logs, eventLoopGroup: eventLoopGroup, fileIO: fileIO)
