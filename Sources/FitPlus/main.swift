//
//  main.swift
//  NioHttpServerPackageDescription
//
//  Created by Aaron Anthony on 2020-02-21.
//

import NIO

let log = Log()
let defaultHost = "::1"
let defaultPort = 8888
let htdocs = "/dev/null/"
let bindTarget = BindTo.ip(host: defaultHost, port: defaultPort)
var allowHalfClosure = true
let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
let threadPool = NIOThreadPool(numberOfThreads: 6)
threadPool.start()

log.log("main.swift func wo object childChannelInitializer(channel: Channel) -> EventLoopFuture<Void> ")
//TODO: uses fileIO who uses it?
func childChannelInitializer(channel: Channel) -> EventLoopFuture<Void> {
    return channel.pipeline.configureHTTPServerPipeline(withErrorHandling: true).flatMap {_ in
        channel.pipeline.addHandler(HttpHandler(fileIO: fileIO, htdocsPath: htdocs, log: log))
    }
}

//The purpose of Bootstrap objects is to streamline the creation of channels.

let fileIO = NonBlockingFileIO(threadPool: threadPool)
let socketBootstrap = ServerBootstrap(group: eventLoopGroup)
    // Specify backlog and enable SO_REUSEADDR for the server itself
    .serverChannelOption(ChannelOptions.backlog, value: 256)
    .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
    
    // Set the handlers that are applied to the accepted Channels
    .childChannelInitializer(childChannelInitializer(channel:))
    
    // Enable SO_REUSEADDR for the accepted Channels
    .childChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
    .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 1)
    .childChannelOption(ChannelOptions.allowRemoteHalfClosure, value: allowHalfClosure)
let pipeBootstrap = NIOPipeBootstrap(group: eventLoopGroup)
    // Set the handlers that are applied to the accepted Channels
    .channelInitializer(childChannelInitializer(channel:))
    
    .channelOption(ChannelOptions.maxMessagesPerRead, value: 1)
    .channelOption(ChannelOptions.allowRemoteHalfClosure, value: allowHalfClosure)

defer {
    try! eventLoopGroup.syncShutdownGracefully()
    try! threadPool.syncShutdownGracefully()
    log.print()
}

print("htdocs = \(htdocs)")

let channel = try { () -> Channel in
    switch bindTarget {
    case .ip(let host, let port):
        return try socketBootstrap.bind(host: host, port: port).wait()
    case .unixDomainSocket(let path):
        return try socketBootstrap.bind(unixDomainSocketPath: path).wait()
    case .stdio:
        return try pipeBootstrap.withPipes(inputDescriptor: STDIN_FILENO, outputDescriptor: STDOUT_FILENO).wait()
    }
    }()

let localAddress: String
if case .stdio = bindTarget {
    localAddress = "STDIO"
} else {
    guard let channelLocalAddress = channel.localAddress else {
        fatalError("Address was unable to bind. Please check that the socket was not closed or that the address family was understood.")
    }
    localAddress = "\(channelLocalAddress)"
}
print("Server started and listening on \(localAddress), htdocs path \(htdocs)")

// This will never unblock as we don't close the ServerChannel
try channel.closeFuture.wait()

print("Server closed")

log.print()
