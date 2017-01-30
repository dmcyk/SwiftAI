//
//  Mutator.swift
//  Genetic
//
//  Created by Damian Malarczyk on 28.10.2016.
//
//

import Foundation
import Utils


class Mutator {
    
    enum Method {
        case replacement(upperBound: Int), removeal, randomSwap, adjacentSwap, endForEndSwap
        
        func mutation() -> (Individual) -> Individual {
            switch self {
            case .replacement(let upperBound):
                return Mutator.replacement(upperBound: upperBound)
            case .removeal:
                return Mutator.removeal()
            case .randomSwap:
                return Mutator.randomSwap()
            case .adjacentSwap:
                return Mutator.adjacentSwap()
            case .endForEndSwap:
                return Mutator.endForEndSwap()
            }
        }
    }
    
    static func replacement(upperBound: Int) -> (Individual) -> Individual {
        return { input in
            var cpy = input
            let newValue: Double = Int.arc4random_uniform_d(upperBound - 1) + Double.arc4random_uniform(101) / 100
            
            let atIndex = Int.arc4random_uniform(cpy.chromosome.count)
            cpy.chromosome[atIndex] = newValue
            return cpy
        }
    }
    
    static func removeal() -> (Individual) -> Individual {
        return { input in
            var cpy = input
            let atIndex = Int.arc4random_uniform(cpy.chromosome.count)
            cpy.chromosome[atIndex] = 0
            return cpy
        }
    }
    
    static func randomSwap() -> (Individual) -> Individual {
        return { input in
            var cpy = input
            
            let upperBound = input.chromosome.count
            let left = Int.arc4random_uniform(upperBound)
            var right = Int.arc4random_uniform(upperBound)
            if left == right {
                right = left > 0 ? left - 1 : left + 1
            }
            let current = input.chromosome
            let p = current[left]
            cpy.chromosome[left] = cpy.chromosome[right]
            cpy.chromosome[right] = p
            return cpy
        }
    }
    
    static func adjacentSwap() -> (Individual) -> Individual  {
        return { input in
            var cpy = input
            
            let left = Int.arc4random_uniform(input.chromosome.count)
            let right: Int
            if left < input.chromosome.count - 1 {
                right = left + 1
            } else {
                right = left - 1
            }
            let current = input.chromosome
            let p = current[left]
            cpy.chromosome[left] = cpy.chromosome[right]
            cpy.chromosome[right] = p
            return cpy
        }
    }
    
    static func endForEndSwap() -> (Individual) -> Individual  {
        return { input in
            var cpy = input
            
            let swapPoint = input.chromosome.count / 2
            let swapEnd = input.chromosome.count % 2 == 0 ? input.chromosome.count : input.chromosome.count - 1
            let firstHalf = cpy.chromosome[0 ..< swapPoint]
            cpy.chromosome[0 ..< swapPoint] = cpy.chromosome[swapPoint ..< swapEnd]
            cpy.chromosome[swapPoint ..< swapEnd] = firstHalf
            return cpy
        }
    }
    
    
}


