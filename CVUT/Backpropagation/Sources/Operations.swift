//
//  Operations.swift
//  Task3
//
//  Created by Damian Malarczyk on 03.01.2017.
//
//

import Foundation
import Accelerate

func sigmoid(_ val: Double) -> Double {
    return 1 / (1 + exp(-val))
}

func sigmoid(_ val: [Double]) -> [Double] {
    
    return val.map { sigmoid($0) }
}

func sigmoidPrime(_ val: Double) -> Double {
    return val * (1 - val)
}
func sigmoidPrime(_ val: [Double]) -> [Double] {
    return val.map { sigmoidPrime($0) }
}

func dotProduct(_ arr: [Double], _ arr2: [Double]) -> Double {
    var res: Double = 0
    
    assert(arr.count == arr2.count)
    
    vDSP_dotprD(arr, 1, arr2, 1, &res, vDSP_Length(arr.count))
    
    return res
}

func dotProduct(_ arr: [[Double]], _ arr2: [Double]) -> [Double] {
    var res = [Double]()
    for a in arr {
        res.append(dotProduct(a, arr2))
    }
    return res
}



func add(_ arr: Array<Double>, _ arr2: Array<Double>) -> Array<Double> {
    assert(arr.count == arr2.count)
    
    var vsresult = [Double](repeating: 0, count: arr.count)
    vDSP_vaddD(arr, 1, arr2, 1, &vsresult, 1, vDSP_Length(arr.count))
    return vsresult
}

func add(_ arr: Array<Array<Double>>, _ arr2: Array<Array<Double>>) -> Array<Array<Double>> {
    assert(arr.count == arr2.count)
    let res: Array<Array<Double>> = zip(arr,arr2).map { (l, r) -> [Double] in
        return add(l, r)
    }
    return res
}

func add(_ arr: Array<Double>, _ scalar: Double) -> Array<Double> {
    var element = scalar
    var buff = [Double].init(repeating: 0, count: arr.count)
    vDSP_vsaddD(arr, 1, &element, &buff, 1, vDSP_Length(arr.count))
    return buff
}

func add(_ arr: Array<Array<Double>>, _ scalar: Double) -> Array<Array<Double>> {
    var arr = arr
    arr = arr.map { cur in
        add(cur, scalar)
    }
    
    return arr
}

func add(_ arr: Array<Array<Double>>, _ arr2: Array<Double>) -> Array<Array<Double>> {
    let arr = arr.map { lhs -> Array<Double> in
        assert(lhs.count == arr2.count)
        return add(lhs, arr2)
    }
    return arr
}

func substract(_ arr: Array<Double>, _ scalar: Double) -> Array<Double> {
    return add(arr, -scalar)
}

func substract(_ scalar: Double, _ arr: Array<Double>) -> Array<Double> {
    return arr.map {
        scalar - $0
    }
}

func substract(_ arr: Array<Double>, _ arr2: Array<Double>) -> Array<Double> {
    assert(arr.count == arr2.count)
    var vsresult = [Double](repeating: 0, count: arr.count)
    vDSP_vsubD(arr, 1, arr2, 1, &vsresult, 1, vDSP_Length(arr.count))
    return vsresult
}
func substract(_ arr: Array<Array<Double>>, _ arr2: Array<Array<Double>>) -> Array<Array<Double>> {
    assert(arr.count == arr2.count)
    
    let res: Array<Array<Double>> = zip(arr,arr2).map { (l, r) -> [Double] in
        return substract(l, r)
    }
    return res
}



func multiply(_ arr: Array<Double>, _ arr2: Array<Double>) -> Array<Double> {
    assert(arr.count == arr2.count)
    var buff = [Double].init(repeating: 0, count: arr.count)
    vDSP_vmulD(arr, 1, arr2, 1, &buff, 1, vDSP_Length(arr.count))
    return buff
}

func multiply(_ arr: Array<Array<Double>>, _ arr2: Array<Double>) -> Array<Array<Double>> {
    let arr = arr.map { lhs -> Array<Double> in
        assert(lhs.count == arr2.count)
        return multiply(lhs, arr2)
    }
    return arr
}


func zeros(_ shape: [Double]) -> [Double] {
    return Array<Double>(repeating: 0, count: shape.count)
}

func zeros(_ shape: [[Double]]) -> [[Double]] {
    var res = [[Double]]()
    for s in shape {
        res.append(zeros(s))
    }
    return res
}

func zeros(_ shape: [[[Double]]]) -> [[[Double]]] {
    var res = [[[Double]]]()
    for s in shape {
        res.append(zeros(s))
    }
    return res
}



func multiplyEach(_ arr: Array<Double>, _ arr2: Array<Double>) -> Array<Array<Double>> {
    var res: Array<Array<Double>> = []
    for a in arr2 {
        res.append(multiply(arr, a))
    }
    return res
}

func sum(_ arr: Array<Double>) -> Double {
    var res: Double = 0
    vDSP_sveD(arr, 1, &res, vDSP_Length(arr.count))
    return res
}

func multiply(_ arr: Array<Double>, _ element: Double) -> Array<Double> {
    var element = element
    var buff = [Double].init(repeating: 0, count: arr.count)
    vDSP_vsmulD(arr, 1, &element, &buff, 1, vDSP_Length(arr.count))
    return buff
}
func multiply(_ arr: Array<Array<Double>>, _ element: Double) -> Array<Array<Double>> {
    return arr.map { a in
        return multiply(a, element)
        
    }
}

func transpose(_ arr: Array<Array<Double>>) -> Array<Array<Double>> {
    var res = [[Double]]()
    for _ in 0 ..< arr[0].count {
        res.append(Array<Double>.init(repeating: 0, count: arr.count))
    }
    for (rowNumber, row) in arr.enumerated() {
        for (columnNumber, column) in row.enumerated() {
            res[columnNumber][rowNumber] = column
        }
    }
    return res
}


extension Array {
    func batch(withSize size: Int) -> [[Element]] {
        var start = self.startIndex
        
        var res: [[Element]] = []
        while start + size < endIndex {
            res.append(Array(self[start..<(start + size)]))
            start += size
        }
        
        res.append(Array(self[start ..< endIndex]))
        return res
        
    }
}
extension MutableCollection where Indices.Iterator.Element == Index {
    /// Shuffles the contents of this collection.
    mutating func shuffle() {
        let c = count
        guard c > 1 else { return }
        
        for (firstUnshuffled , unshuffledCount) in zip(indices, stride(from: c, to: 1, by: -1)) {
            let d: IndexDistance = numericCast(arc4random_uniform(numericCast(unshuffledCount)))
            guard d != 0 else { continue }
            let i = index(firstUnshuffled, offsetBy: d)
            swap(&self[firstUnshuffled], &self[i])
        }
    }
}

extension Sequence {
    /// Returns an array with the contents of this sequence, shuffled.
    func shuffled() -> [Iterator.Element] {
        var result = Array(self)
        result.shuffle()
        return result
    }
}
