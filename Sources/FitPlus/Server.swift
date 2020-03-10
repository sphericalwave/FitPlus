//
//  File.swift
//  
//
//  Created by Aaron Anthony on 2020-03-10.
//

import NIO

class Server
{
    let log: Log
    let defaultHost = "::1"
    let defaultPort = 8888
    let htdocs = "/dev/null/"
    //let bindTarget = BindTo.ip(host: defaultHost, port: defaultPort)
    //var allowHalfClosure = true
    let eventLoopGroup: MultiThreadedEventLoopGroup
    let fileIO: NonBlockingFileIO

    
    init(log: Log, eventLoopGroup: MultiThreadedEventLoopGroup, fileIO: NonBlockingFileIO) {
        self.log = log
        self.eventLoopGroup = eventLoopGroup
        self.fileIO = fileIO
        //threadPool.start()
        
        let socketBootstrap = ServerBootstrap(group: eventLoopGroup)
            // Specify backlog and enable SO_REUSEADDR for the server itself
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            
            // Set the handlers that are applied to the accepted Channels
            .childChannelInitializer(childChannelInitializer(channel:))
            
            // Enable SO_REUSEADDR for the accepted Channels
            .childChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 1)
            .childChannelOption(ChannelOptions.allowRemoteHalfClosure, value: true)
        
//        let pipeBootstrap = NIOPipeBootstrap(group: eventLoopGroup)
//            // Set the handlers that are applied to the accepted Channels
//            .channelInitializer(childChannelInitializer(channel:))
//
//            .channelOption(ChannelOptions.maxMessagesPerRead, value: 1)
//            .channelOption(ChannelOptions.allowRemoteHalfClosure, value: true)
        
        defer {
            try! eventLoopGroup.syncShutdownGracefully()
            //try! threadPool.syncShutdownGracefully()
            log.print()
        }
        
//        let channel = try { () -> Channel in
//            return try socketBootstrap.bind(host: defaultHost, port: defaultPort).wait()
//            }()
        
        guard let channel = try? socketBootstrap.bind(host: defaultHost, port: defaultPort).wait() else { fatalError() }
        
        let localAddress: String
        guard let channelLocalAddress = channel.localAddress else {
            fatalError("Address unable to bind. Check socket was not closed & address family understood.")
        }
        localAddress = "\(channelLocalAddress)"
        print("Server started and listening on \(localAddress), htdocs path \(htdocs)")
        
        log.print()
        try! channel.closeFuture.wait()  // This will never unblock as we don't close the ServerChannel
        
        print("Server closed")
    }
    
    //log.log("main.swift func wo object childChannelInitializer(channel: Channel) -> EventLoopFuture<Void> ")
    //TODO: uses fileIO who uses it?
    func childChannelInitializer(channel: Channel) -> EventLoopFuture<Void> {
        return channel.pipeline.configureHTTPServerPipeline(withErrorHandling: true).flatMap {_ in
            channel.pipeline.addHandler(HttpHandler(fileIO: self.fileIO, htdocsPath: self.htdocs, log: self.log))
        }
    }
}
