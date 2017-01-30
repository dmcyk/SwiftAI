//
//  Genetic.swift
//  Genetic
//
//  Created by Damian Malarczyk on 17.11.2016.
//
//

import Foundation
import Accelerate

protocol GeneticIndividual: Indv {
    mutating func mutate(withMethod: Mutation.Method)
    static func crossover(_ dad: Self, _ mum: Self) -> (Self, Self)
    var fitness: Double { get set }
    
}

extension GeneticIndividual {
    func mutated(withMethod method: Mutation.Method) -> Self {
        var cpy = self
        cpy.mutate(withMethod: method)
        return cpy 
    }
}

struct ValueStream<T> {
    var fetchBlock:() -> [T]
    var buff: [T]
    
    init(fetchBlock: @escaping () -> [T]) {
        self.fetchBlock = fetchBlock
        self.buff = []
        fill()
        
    }
    
    mutating private func fill() {
        for _ in 0 ..< 2 {
            buff.append(contentsOf: fetchBlock())
        }
    }
    
    mutating func next() -> T {
        var last = buff.popLast()
        if last == nil {
            fill()
            last = buff.popLast()!
        }
        return last!
    }
}

enum GeneticOptimizationType {
    case min, max
}


class GeneticEvolver<T: GeneticIndividual, K>: EvolutionAlgorithm {
    typealias Member = T
    typealias Input = K
    typealias ComparisonFunction = (Member, Member) -> Bool
    typealias FitnessFunction = (Member, Input) -> Double
    
    var fitnessCounter: Int = 0
    let fitnessOptimization: ComparisonFunction
    let fitnessFunction: FitnessFunction
    let optimization: GeneticOptimizationType
    let mutationProbability: Double
    let crossoverProbability: Double
    let elitism: Int
    var mutationStream: ValueStream<Mutation.Method>
    
    init(maxChromosomeValue: Int, mutationProbability: Double, crossoverProbability: Double, optimization: GeneticOptimizationType, mutationMethods: [Mutation.Method], elitism: Int = 1, fitnessFunction: @escaping FitnessFunction, fitnessOptimization: @escaping ComparisonFunction) {
        self.fitnessOptimization = fitnessOptimization
        self.fitnessFunction = fitnessFunction
        self.mutationProbability = mutationProbability
        self.elitism = elitism
        self.optimization = optimization
        self.crossoverProbability = crossoverProbability

        
        mutationStream = ValueStream(fetchBlock: {
            let random = Int.boxMullerRandom(mutationMethods.count - 1)
            return [mutationMethods[random.0], mutationMethods[random.1]]
        })
        
    }
    
    
    func initializePopulation(withSize size: Int, forInput input: Input, newInstance: () -> Member) -> [Member] {
        var pop = [T]()
        fitnessCounter = 0
        
        for _ in 0 ..< size {
            var individual = newInstance()
            individual.fitness = evaluateFitness(individual, input: input)
            pop.append(individual)
        }
        
        return pop
    }
    
    private func selection(_ individuals: [Member], bestFitness: Double, maxFitness: Double, input: Input, limit: Int) -> [Member] {
        var new: [Member] = []
        
        if case .max = optimization {
            for i in 0 ..< individuals.count {
                var cur = individuals[i]
                if Double.arc4random_uniform(101) / 100 <= cur.fitness / bestFitness {
                    new.append(cur)
                    if new.count == limit {
                        break
                    }
                }
                
            }
        } else {
            
            var scaledMax = maxFitness - bestFitness
            scaledMax = scaledMax > 0 ? scaledMax : 1
            for i in 0 ..< individuals.count {
                var cur = individuals[i]
                if Double.arc4random_uniform(101) / 100 >= (cur.fitness - bestFitness) / scaledMax {
                    new.append(cur)
                    if new.count == limit {
                        break
                    }
                    
                }
            }
        }
        
        return new
    }
    

    
    private func crossover(fromIndividuals parents: [Member], upTo: Int, input: Input) -> [Member] {
        var extended: [Member] = Array<Member>(parents)
        var indx = 0
        var best: [Member] = []
        best.reserveCapacity(4)
        while extended.count < upTo {
            
            let dadIndx = indx
            indx += 1
            
            let mumIndx: Int
            if indx < parents.count {
                mumIndx = indx
                
            } else {
                mumIndx = 0
                indx = 0
            }
            
            // kinda repetetive but assuming two parents produce two children there will always be two values,
            // so it could be better to evade array's overhead use tuples instead and repeat some code
            let dad = parents[dadIndx]
            let mum = parents[mumIndx]
            best.append(dad)
            best.append(mum)
            
            
            if Double.arc4random_uniform(101) / 100 <= crossoverProbability {
                var res = Member.crossover(dad, mum)
                res.0.fitness = evaluateFitness(res.0, input: input)
                res.1.fitness = evaluateFitness(res.1, input: input)
                
                if res.0.fitness >= 0 {
                    best.insert(res.0, at: 0)
                }
                if res.1.fitness >= 0 {
                    best.insert(res.1, at: 0)
                }
            }
            
            for indx in 0 ..< 2 {
                if extended.count < upTo {
                    extended.append(best[indx])
                }
            }
            best.removeAll(keepingCapacity: true)
        }
        return extended
    }
    
    private func mutate(individuals: inout [Member], input: Input) {
        
        for x in 0 ..< individuals.count {
            if Double.arc4random_uniform(101) / 100 <= mutationProbability {

                let method = mutationStream.next()
                
                individuals[x].mutate(withMethod: method)
                individuals[x].fitness = evaluateFitness(individuals[x], input: input)
            }
            
        }
    }
    
    internal func evaluateFitness(_ member: Member, input: Input) -> Double {
        fitnessCounter += 1
        return fitnessFunction(member, input)
    }
    
    internal func evolve(forInput input: Input, currentPopulation: [Member], currentBest: Member, maxFitness: Double) -> (EvolutionResult<Member>, maxFitness: Double) {
        
        
        let stride = MemoryLayout<Member>.stride / MemoryLayout<Double>.stride
        var elite: [Member] = []
        
        if elitism > 1 {
            var cp = currentPopulation
            var _elite: [Int] = []
            while _elite.count < elitism {
                var _index: vDSP_Length = 0
                var val: Double = 0
                
                withUnsafePointer(to: &cp[0].fitness) {
                    vDSP_minvD($0, stride, &val, vDSP_Length(cp.count))
                    vDSP_minviD($0, stride, &val, &_index, vDSP_Length(cp.count))
                    
                }
                
                let index = Int(_index) / stride
                var new = true
                for i in _elite {
                    if i == index {
                        new = false
                        break
                    }
                }
                
                if new {
                    _elite.append(index)
                    elite.append(cp[index])
                    cp[index].fitness = DBL_MAX
                } else {
                    break
                }
                
                
            }
            
        } else {
            elite.append(currentBest)
        }
        
        var newIndividuals = selection(currentPopulation, bestFitness: currentBest.fitness, maxFitness: maxFitness, input: input, limit: currentPopulation.count - elitism)
        newIndividuals = crossover(fromIndividuals: newIndividuals, upTo: currentPopulation.count - 1, input: input)
        mutate(individuals: &newIndividuals, input: input)
        
        for i in elite {
            newIndividuals.append(i)
        }
        
        
        var max: Double = 0
        var bestIndex: vDSP_Length = 0
        withUnsafeMutablePointer(to: &newIndividuals[0].fitness) { (ptrFit: UnsafeMutablePointer<Double>) in
            let length =  vDSP_Length(newIndividuals.count)
            vDSP_maxvD(ptrFit, stride, &max, length)
            var min: Double = 0
            vDSP_minviD(ptrFit, stride, &min, &bestIndex, length)
            
        }
            
        
        let best = newIndividuals[Int(bestIndex) / stride]
        
        return (EvolutionResult(newPopulation: newIndividuals, best: best), maxFitness: max)
    }
    
    
}
