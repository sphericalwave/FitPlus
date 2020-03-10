//
//  File.swift
//  
//
//  Created by Aaron Anthony on 2020-03-10.
//

import NIO

class Server
{
    let logs: Log
    let host = "::1"
    let port = 8888
    let htdocs = "/dev/null/"
    let eventLoopGroup: MultiThreadedEventLoopGroup
    
    init(logs: Log, eventLoopGroup: MultiThreadedEventLoopGroup) {
        logs.log("Server init")
        self.logs = logs
        self.eventLoopGroup = eventLoopGroup
        
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
        
        defer {
            try! eventLoopGroup.syncShutdownGracefully()
            //try! threadPool.syncShutdownGracefully()
            logs.log("Server shutdown gracefully")
            logs.print()
        }
        
        guard let channel = try? socketBootstrap.bind(host: host, port: port).wait() else { fatalError() }
        
        let localAddress: String
        guard let channelLocalAddress = channel.localAddress else {
            fatalError("Address unable to bind. Check socket was not closed & address family understood.")
        }
        localAddress = "\(channelLocalAddress)"
        logs.log("Server started and listening on \(localAddress), htdocs path \(htdocs)")
        try! channel.closeFuture.wait()  // This will never unblock as we don't close the ServerChannel
        logs.log("Server closed")
    }
    
    func childChannelInitializer(channel: Channel) -> EventLoopFuture<Void> {
        logs.log("Server.childChannelInitializer(channel: Channel) -> EventLoopFuture<Void>")
        //FIXME: Encapsulation Violation
        return channel.pipeline.configureHTTPServerPipeline(withErrorHandling: true).flatMap {_ in
            channel.pipeline.addHandler(HttpChannel(htdocsPath: self.htdocs, logs: self.logs))
        }
    }
}
