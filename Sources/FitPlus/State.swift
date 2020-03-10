//
//  State.swift
//  FitPlus
//
//  Created by Aaron Anthony on 2020-02-24.
//

import Foundation

enum State
{
    case idle
    case waitingForRequestBody
    case sendingResponse

    mutating func requestReceived() {
        //logs.log("State requestReceived")

        precondition(self == .idle, "Invalid state for request received: \(self)")
        self = .waitingForRequestBody
    }

    mutating func requestComplete() {
        //logs.log("State requestComplete")

        precondition(self == .waitingForRequestBody, "Invalid state for request complete: \(self)")
        self = .sendingResponse
    }

    mutating func responseComplete() {
        precondition(self == .sendingResponse, "Invalid state for response complete: \(self)")
        self = .idle
    }
}
