//
//  Mutator.swift
//  Genetic
//
//  Created by Damian Malarczyk on 28.10.2016.
//
//

import Foundation
import Utils


class Mutation {
    
    enum Method {
        case replacement(upperBound: Int), removeal, randomSwap, adjacentSwap, endForEndSwap
        
        static var allBasic: [Mutation.Method] {
            return [.removeal, .randomSwap, .adjacentSwap, .endForEndSwap]
        }
    }
}


