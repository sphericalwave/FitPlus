//
//  NioHttpServer.swift
//  NioHttpServerPackageDescription
//
//  Created by Aaron Anthony on 2020-02-21.
//

import NIO
import NIOHTTP1
import Foundation

class HttpHandler: ChannelInboundHandler
{
    public typealias InboundIn = HTTPServerRequestPart
    public typealias OutboundOut = HTTPServerResponsePart
    
    //FIXME: What is the meaning of all these vars?
    var buffer: ByteBuffer! = nil
    var keepAlive = false
    var state = State.idle
    let htdocsPath: String
    var infoSavedRequestHead: HTTPRequestHead?
    var infoSavedBodyBytes: Int = 0
    var continuousCount: Int = 0
    var handler: ((ChannelHandlerContext, HTTPServerRequestPart) -> Void)?
    var handlerFuture: EventLoopFuture<Void>?
    let fileIO: NonBlockingFileIO
    let defaultResponse = "Hello World\r\n"
    let logs: Log
    
    public init(fileIO: NonBlockingFileIO, htdocsPath: String, logs: Log) {
        self.htdocsPath = htdocsPath
        self.fileIO = fileIO
        self.logs = logs
        logs.log("HttpHandler init(fileIO: NonBlockingFileIO, htdocsPath: String, log: Log)")
    }
   
    private func completeResponse(_ context: ChannelHandlerContext, trailers: HTTPHeaders?, promise: EventLoopPromise<Void>?) {
        logs.log("HttpHandler completeResponse")
        self.state.responseComplete()
        let promise = self.keepAlive ? promise : (promise ?? context.eventLoop.makePromise())
        if !self.keepAlive {
            promise!.futureResult.whenComplete { (_: Result<Void, Error>) in context.close(promise: nil) }
        }
        self.handler = nil  //FIXME: How dare you
        context.writeAndFlush(self.wrapOutboundOut(.end(trailers)), promise: promise)
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        logs.log("HttpHandler channelRead")
        let reqPart = self.unwrapInboundIn(data)
        if let handler = self.handler {
            handler(context, reqPart)
            return
        }
        
        switch reqPart {
        case .head(let request):
            self.keepAlive = request.isKeepAlive
            self.state.requestReceived()
            
            var responseHead = httpResponseHead(request: request, status: HTTPResponseStatus.ok)
            self.buffer.clear()
            self.buffer.writeString(self.defaultResponse)
            responseHead.headers.add(name: "content-length", value: "\(self.buffer!.readableBytes)")
            let response = HTTPServerResponsePart.head(responseHead)
            context.write(self.wrapOutboundOut(response), promise: nil)
        case .body:
            break
        case .end:
            self.state.requestComplete()
            let content = HTTPServerResponsePart.body(.byteBuffer(buffer!.slice()))
            context.write(self.wrapOutboundOut(content), promise: nil)
            self.completeResponse(context, trailers: nil, promise: nil)
        }
    }
    
    func channelReadComplete(context: ChannelHandlerContext) {
        logs.log("HttpHandler channelReadComplete")
        context.flush()
    }
    
    func handlerAdded(context: ChannelHandlerContext) {
        logs.log("HttpHandler handlerAdded")
        self.buffer = context.channel.allocator.buffer(capacity: 0)
    }
    
    func userInboundEventTriggered(context: ChannelHandlerContext, event: Any) {
        logs.log("HttpHandler userInboundEventTriggered")
        switch event {
        case let evt as ChannelEvent where evt == ChannelEvent.inputClosed:
            // The remote peer half-closed the channel. At this time, any
            // outstanding response will now get the channel closed, and
            // if we are idle or waiting for a request body to finish we
            // will close the channel immediately.
            switch self.state {
            case .idle, .waitingForRequestBody:
                context.close(promise: nil)
            case .sendingResponse:
                self.keepAlive = false
            }
        default:
            context.fireUserInboundEventTriggered(event)
        }
    }
}
