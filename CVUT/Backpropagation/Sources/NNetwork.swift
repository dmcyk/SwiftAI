//
//  NNetwork.swift
//  Task3
//
//  Created by Damian Malarczyk on 03.12.2016.
//
//

import Foundation
import Utils
import Accelerate

protocol NNetwork {
    
    var bias: [[Double]] { get set }
    var weights: [[[Double]]] { get set }
    var numLayers: Int { get set }
    init()
    mutating func postInitSetup()
    
}

internal struct NNetworkSizeStructure {
    var weights: Int
    var neurons: Int
}


extension NNetwork {
    static func random(neurons: [Int], maxValue: Double) -> Self {
        var instance = Self()
        for (i,n) in neurons.suffix(from: 1).enumerated() {
            var b = [Double]()
            var w = [[Double]]()
            
            for _ in 0 ..< n {
                b.append((Double.arc4random_uniform(maxValue) + (Double.arc4random_uniform(101) / 100)) / 10)
                var currentW = [Double]()
                for _ in 0 ..< neurons[i] {
                    currentW.append(Double.arc4random_uniform(maxValue) + (Double.arc4random_uniform(101) / 100) )
                }
                w.append(currentW)
            }
            instance.bias.append(b)
            instance.weights.append(w)
            
        }
        instance.numLayers = neurons.count
        instance.postInitSetup()
        return instance
    }
    
    
    func feedforward(acc: [Double]) -> [Double] {
        var acc = acc
        for i in 0 ..< bias.count - 1 {
            var val = add(dotProduct(weights[i], acc), bias[i])
            for i in (1 ..< val.count).reversed() {
                val[i] = sigmoid(val[i - 1])
            }
            val[0] = 1
            acc = val
        }
        let val = add(dotProduct(weights.last!, acc), bias.last!)
        acc = val
        return acc
    }
    
    func eval(_ testData: [([Double], [Double])], maxError: Double) -> [Bool] {
        return testData.map { current in
            for (i,r) in feedforward(acc: current.0).enumerated() {
                if abs(r - current.1[i]) >= maxError {
                    return false
                }
                return true
            }
            return true
        }
        
    }
    internal var vector: ([Double], sizes: [NNetworkSizeStructure]) {
        var buff: [Double] = []
        var sizes: [NNetworkSizeStructure] = []
        for (layerIndex, layer) in weights.enumerated() {
            for (neuronIndex, neuron) in layer.enumerated() {
                buff.append(contentsOf: neuron)
                buff.append(bias[layerIndex][neuronIndex])
            }
            sizes.append(NNetworkSizeStructure(weights: layer[0].count, neurons: layer.count))
        }
        return (buff, sizes)
    }
    
    internal static func extract(vector: [Double], structure: [NNetworkSizeStructure]) -> ([[Double]], [[[Double]]]) {
        var bias = [[Double]]()
        var indx = 0
        var weights = [[[Double]]]()
        for str in structure {
            var layer: [[Double]] = []
            var biases: [Double] = []
            for _ in 0 ..< str.neurons {
                var neuron: [Double] = []
                for _ in 0 ..< str.weights {
                    neuron.append(vector[indx])
                    indx += 1
                }
                layer.append(neuron)
                biases.append(vector[indx])
                indx += 1
            }
            weights.append(layer)
            bias.append(biases)
        }
        return (bias, weights)
    }
    
    internal init(_ other: NNetIndividual, vector: [Double], structure: [NNetworkSizeStructure]) {
        self.init()
        self.numLayers = other.numLayers
        (self.bias, self.weights) = NNetIndividual.extract(vector: vector, structure: structure)
        postInitSetup()
    }
}


struct NNetIndividual: NNetwork, GeneticIndividual {
    var bias: [[Double]] = []
    var weights: [[[Double]]] = []
    var numLayers: Int = 0
    var fitness: Double = 0
    
    init() {
        
    }
    
    private init(_ other: NNetIndividual, newParameters: [[[Double]]]) {
        self.numLayers = other.numLayers
        self.fitness = -1
        
        for layer in newParameters {
            var layerBiases: [Double] = []
            var newLayer = [[Double]]()
            for var neuron in layer {
                layerBiases.append(neuron.popLast()!)
                newLayer.append(neuron)
                
            }
            bias.append(layerBiases)
            weights.append(newLayer)
        }
    }
    
    static func crossover(_ dad: NNetIndividual, _ mum: NNetIndividual) -> (NNetIndividual, NNetIndividual) {
        let dadVector = dad.vector
        let mumVector = mum.vector
        
        let new = dadVector.0.crossover(with: mumVector.0, pointsCount: 2)
        
        return (NNetIndividual(dad, vector: new.0, structure: dadVector.1), NNetIndividual(dad, vector: new.1, structure: dadVector.1))
    }
    
    mutating func mutate(withMethod method: Mutation.Method) {
        var buff = vector
        switch method {
        case .adjacentSwap:
            adjacentSwap(&buff.0)
        case .endForEndSwap:
            endForEndSwap(&buff.0)
        case .randomSwap:
            randomSwap(&buff.0)
        case .removeal:
            removeal(&buff.0)
        case .replacement(let up):
            replacement(&buff.0, upperBound: up)
        }
        (self.bias, self.weights) = NNetIndividual.extract(vector: buff.0, structure: buff.1)
    }
    
    mutating func postInitSetup() {
        fitness = -1
    }
}

fileprivate func zipBiasesAndWeights(_ val: NNetIndividual) -> [[[Double]]] {
    return zip(val.bias, val.weights).map { biases, weights in
        return zip(biases, weights).map { bias, weight in
            var extended = weight
            extended.append(bias)
            return extended
        }
    }
}

struct GradientNNetwork: NNetwork {
    var bias: [[Double]] = []
    var biasCache: [[Double]] = []
    var weights: [[[Double]]] = []
    var weightsCache: [[[Double]]] = []
    var numLayers: Int = 0
    var fitness: Double = 0
    var momentum = 0.4 {
        didSet {
            mEta = (1 - momentum) * eta

        }
    }
    var eta: Double = 0.7 {
        didSet {
            mEta = (1 - momentum) * eta
        }
    }
    
    private(set) var mEta: Double = 0.1
    private(set) var stuckLocalMinimum = 0
    
    init() {
        
    }
    
    mutating func learn(data: [([Double], [Double])], epochs: Int) -> Double {
        assert(!bias.isEmpty)
        assert(!weights.isEmpty)
        assert(numLayers > 0)

        for _ in 0 ..< epochs {
            update(batch: data)
            fitness = rmse(data.map {
                let rawOut = feedforward(acc: $0.0)[0]
                return (result: rawOut, expected: $0.1[0])
            })
            
        }
        return fitness
    }

    private mutating func update(batch: [([Double], [Double])]) {

        for (input, output) in batch {
            backpropagate(input: input, desired: output)
        }
    }
    
    func feedforwardStep(acc: [Double]) -> [[Double]] {
        var acc = acc
        var accs = [[Double]]()
        for i in 0 ..< bias.count - 1 {
            var val = add(dotProduct(weights[i], acc), bias[i])
            for i in (1 ..< val.count).reversed() {
                val[i] = sigmoid(val[i - 1])
            }
            val[0] = 1
            acc = val
            accs.append(val)
        }
        let val = add(dotProduct(weights.last!, acc), bias.last!)
        
        accs.append(val)
        return accs
    }
    
    
    func feedforward(acc: [Double]) -> [Double] {
        var acc = acc
        for i in 0 ..< bias.count  - 1 {
            var val = add(dotProduct(weights[i], acc), bias[i])
            for i in (1 ..< val.count).reversed() {
                val[i] = sigmoid(val[i - 1])
            }
            val[0] = 1
            acc = val
        }
        let val = add(dotProduct(weights.last!, acc), bias.last!)
        return val
    }
    
    
    private mutating func layerError(_ output: [Double], desired: [Double]) -> [Double] {
        var res = [Double]()
        var increase: Double = 0
        if stuckLocalMinimum > 9 {
            stuckLocalMinimum = 0
            increase += eta
        }
        assert(output.count == desired.count)
        for i in 0 ..< output.count {
            let out = sigmoid(output[i]) + increase
            res.append(sigmoidPrime(out) * (desired[i] - out))
        }
        return res
    }
    private func backpropagateError(_ error: [Double], weights: [[Double]]) -> [Double] {
        var res: [Double] = zeros(weights[0])
        for (crow, row) in weights.enumerated() {
            for (indx, column) in row.enumerated() {
                res[indx] += column * error[crow];
            }
        }
        return res;
    }
    private mutating func backpropagate(input: [Double], desired: [Double]) {
        
        let outputs = feedforwardStep(acc: input)
        var previousError = layerError(outputs.last!, desired: desired)
        let _weightsCache = self.weights
        let _biasCache = self.bias
        for i in (1 ..< weights.count).reversed() {
            let currentWeights = weights[i]
            let previousWeights = weightsCache[i]
            let currentBias = bias[i]
            let previousBias = biasCache[i]
            let offset = add(currentWeights, multiply(substract(currentWeights, previousWeights), momentum))
            let biasOffset = add(currentBias, multiply(substract(currentBias, previousBias), momentum))
            let delta = multiply(previousError, mEta)
            if (abs(sum(delta)) < 0.00001) {
                stuckLocalMinimum += 1;
            }
            self.bias[i] = add(biasOffset, delta)
            self.weights[i] = add(offset, multiplyEach(outputs[i - 1], delta))
            
            previousError = backpropagateError(previousError, weights: currentWeights)
            previousError = multiply(sigmoidPrime(outputs[i - 1]), previousError)
            
        }
        self.weightsCache = _weightsCache
        self.bias = _biasCache
        
    }
    
    mutating func postInitSetup() {
        self.weightsCache = zeros(weights)
        self.biasCache = zeros(bias)
    }
}
