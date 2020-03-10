//
//  BindTo.swift
//  FitPlus
//
//  Created by Aaron Anthony on 2020-03-10.
//

import Foundation

enum BindTo //FIXME: Naming
{
    case ip(host: String, port: Int)
    case unixDomainSocket(path: String)
    case stdio
}
