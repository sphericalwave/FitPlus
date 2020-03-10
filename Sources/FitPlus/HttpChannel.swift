//
//  HttpChannel.swift
//  FitPlus
//
//  Created by Aaron Anthony on 2020-02-21.
//

import NIO
import NIOHTTP1

class HttpChannel: ChannelInboundHandler    //FIXME: HttpChannel?
{
    public typealias InboundIn = HTTPServerRequestPart
    public typealias OutboundOut = HTTPServerResponsePart
    
    var buffer: ByteBuffer! = nil               //FIXME: Nil
    var keepAlive = false                       //FIXME: Be Immutable
    var state = State.idle                      //FIXME: Be Immutable
    let htdocsPath: String
    var infoSavedRequestHead: HTTPRequestHead?  //FIXME: Be Immutable
    var infoSavedBodyBytes: Int = 0             //FIXME: Be Immutable
    var continuousCount: Int = 0                //FIXME: Be Immutable
    var handler: ((ChannelHandlerContext, HTTPServerRequestPart) -> Void)?   //FIXME: Be Immutable
    var handlerFuture: EventLoopFuture<Void>?   //FIXME: Be Immutable
    let logs: Log
    
    public init(htdocsPath: String, logs: Log) {
        self.htdocsPath = htdocsPath
        self.logs = logs
        logs.log("HttpHandler init(htdocsPath: String, log: Log)")
    }
    
    func handlerAdded(context: ChannelHandlerContext) {
        logs.log("HttpHandler handlerAdded")
        self.buffer = context.channel.allocator.buffer(capacity: 0) //FIXME: Encapsulation Violation
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        logs.log("HttpHandler channelRead")
        let reqPart = self.unwrapInboundIn(data)
        if let handler = self.handler {
            handler(context, reqPart)
            return
        }
        switch reqPart {
        case .head(let request):      //FIXME: JC, what is going on here
            self.keepAlive = request.isKeepAlive
            self.state.requestReceived()
            var responseHead = httpResponseHead(request: request, status: HTTPResponseStatus.ok)
            self.buffer.clear()
            self.buffer.writeString("Greetings Earthling!")
            responseHead.headers.add(name: "content-length", value: "\(self.buffer!.readableBytes)") //FIXME: Encapsulation Violation
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
   
    private func completeResponse(_ context: ChannelHandlerContext, trailers: HTTPHeaders?, promise: EventLoopPromise<Void>?) {
        logs.log("HttpHandler completeResponse")
        self.state.responseComplete()
        let promise = self.keepAlive ? promise : (promise ?? context.eventLoop.makePromise())
        if !self.keepAlive {
            promise!.futureResult.whenComplete { (_: Result<Void, Error>) in context.close(promise: nil) } //FIXME: Encapsulation Violation
        }
        self.handler = nil  //FIXME: How dare you
        context.writeAndFlush(self.wrapOutboundOut(.end(trailers)), promise: promise)
    }
    
    func channelReadComplete(context: ChannelHandlerContext) {
        logs.log("HttpHandler channelReadComplete")
        context.flush()
    }
}
