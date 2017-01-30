//
//  main.swift
//  Genetic
//
//  Created by Damian Malarczyk on 28.10.2016.
//
//


import Foundation
import Utils
import Console
import CoreGraphics

class PSOParameters: Command {
    var name: String = "psoparameters"
    
    var parameters: [CommandParameter] = [
        .argument(Argument("source", expectedValue: .string, description: "Path to source file")),
        .option(Option("sourceId", description: "Source identifier - necessary when using PSO cache, if not given found parameters will just be printed", mode: .value(expected: .string, default: nil))),
        .option(Option("cache", description: "Path to folder with PSO parameteres cache, if not given parameters will just be printed", mode: .value(expected: .string, default: nil))),
        .argument(Argument("size", expectedValue: .int, description: "Size of populations", default: 100)),
        .argument(Argument("iterations", expectedValue: .int, description: "Amount of algorithms generations/iterations", default: 100)),
        .argument(Argument("position", expectedValue: .int, description: "Maximum value that individuals may have", default: 500)),
        .argument(Argument("repeats", expectedValue: .int, description: "Amount of algorithms repetitions to improve results accuray", default: 5))

    ]
    
    func run(data: CommandData) throws {
        let src = try data.argumentValue("source").stringValue()
        let srcId = try data.optionValue("sourceId")?.stringValue()
        let input =  try forestFiresInput(sourcePath: src)
        let _cache = try data.optionValue("cache")?.stringValue()
        let size = try data.argumentValue("size").intValue()
        let iterations = try data.argumentValue("iterations").intValue()
        let position = try  data.argumentValue("position").intValue()
        let repeats = try data.argumentValue("repeats").intValue()
        
        print("\nRunning with configuration: \n\tsource: \(src)\n\tsize: \(size)\n\titerations: \(iterations)\n\tposition: \(position)\n\trepeats \(repeats)")
        if _cache != nil && srcId != nil {
            print("\tcache: \(_cache!)\n\tsourceId: \(srcId!)")
        }
        var results: [Double] = [0, 0, 0]
        for i in 0 ..< repeats {
            zip(results, ParticleNetworkEvolver.calculateBest(input: input, size: size, iterations: iterations, min: 0.01, max: 0.99, increment: 0.3, maxPositionValue: position)).enumerated().forEach {
                results[$0.offset] = $0.element.0 + $0.element.1
            }
            print("Progres: \(i + 1)/\(repeats)")
        }
        results = results.map {
            $0 / Double(repeats)
        }
        let params = ParticleNetworkEvolver.Parameters.init(omega: results[0], delta1: results[1], delta2: results[2])
        
        if let cache = _cache, let id = srcId {
            let entry = ParticleNetworkEvolver.Cache.Entry.init(inputId: id, size: size, iterations: iterations, maxPositionValue: position)
            try ParticleNetworkEvolver.Cache(path: cache).cache(parameters: params, entry: entry)
        } else {
            print()
            dump(params)
            print()
        }
        print("Finished with success\n")


    }
}

class Generate: Command {
    var name: String = "generate"
    
    enum Error: Swift.Error {
        case noCacheNorParameters
        case noCacheEntryFound
        case incorrectParameters
        case populationInitializationError
        case missingSourceId
    }
    
    
    var parameters: [CommandParameter] = [
        .argument(Argument("source", expectedValue: .string, description: "Path to source file")),
        .argument(Argument("size", expectedValue: .int, description: "Size of populations")),
        .argument(Argument("result", expectedValue: .string, description: "Path to folder for storing measurements")),
        .option(Option("sourceId",  description: "Source identifier - necessary when using PSO cache", mode: .value(expected: .string, default: nil))),
        .option(Option("cache", description: "Path to folder with PSO parameteres cache", mode: .value(expected: .string, default: nil))),
        .option(Option("parameters", description: "PSO parameters array - 3 values", mode: .value(expected: .array(.double), default: nil))),
        .option(Option("position", description: "Maximum value that individuals may have", mode: .value(expected: .int, default: .int(100)))),
        .option(Option("repeats", description: "Amount of algorithms repetitions to improve results accuray", mode: .value(expected: .int, default: .int(5)))),
        .option(Option("pso", mode: .flag)),
        .option(Option("genetic", mode: .flag)),
        .option(Option("backpropagation", mode: .flag)),
        .argument(Argument("seconds", expectedValue: .array(.double))),
        .argument(Argument("eta", expectedValue: .double, default: 0.5)),
        .argument(Argument("momentum", expectedValue: .double, default: 0.5))
    ]
    
    struct DataGenerator {
        var population: GenericPopulation
        var name: String
        struct Entry {
            var elements: [Double]
        }
        var entries: [Double: Entry]
    }
    
    func run(data: CommandData) throws {
        let _cache = try data.optionValue("cache")?.stringValue()
        let rawParameters = try data.optionValue("parameters")?.arrayValue().map {
            try $0.doubleValue()
        }
        let srcId = try data.optionValue("sourceId")?.stringValue()
        let src = try data.argumentValue("source").stringValue()
        let input =  try forestFiresInput(sourcePath: src)
        let size = try data.argumentValue("size").intValue()
        let backprop = try data.flag("backpropagation")
        let eta = try data.argumentValue("eta").doubleValue()
        let momentum = try data.argumentValue("momentum").doubleValue()
        var max: Double = Double(Int.min)
        var min = Double(Int.max)
        for i in input {
            if i.expectedResult < min {
                min = i.expectedResult
                
            }
            if i.expectedResult > max {
                max = i.expectedResult
            }
        }
        
        let seconds = try data.argumentValue("seconds").arrayValue().map {
            try $0.doubleValue()
        }
        .sorted(by: >)

        let position = try  data.optionValue("position")!.intValue()
        
        let pso = try data.flag("pso")
        let genetic = try data.flag("genetic")
        let resultFolder = try URL(fileURLWithPath: data.argumentValue("result").stringValue())
        
        let repeats = try data.optionValue("repeats")!.intValue()
        let mutation: [Mutation.Method] = Mutation.Method.allBasic + [.replacement(upperBound: position)]

        
        print("\nRunning with configuration: \n\tsource: \(src)\n\tsize: \(size)\n\tposition: \(position)\n\trepeats: \(repeats)\n\teta: \(eta)")
        print("\tresultFolder: \(resultFolder.path)")
        
        print("\talgorithms: ", separator: "", terminator: "")
        [("PSO", pso), ("Genetic", genetic), ("Backpropagation", backprop)].forEach {
            if $0.1 {
                print("\($0.0) ", separator: "", terminator: "")
            }
        }
        print()
        
        var parameters: ParticleNetworkEvolver.Parameters!
        
        
        if pso {
            if let rawParams = rawParameters {
                guard rawParams.count == 3 else {
                    throw Error.incorrectParameters
                }
                parameters = ParticleNetworkEvolver.Parameters(omega: rawParams[0], delta1: rawParams[1], delta2: rawParams[2])
            } else {
                
                guard let cache = _cache else {
                    throw Error.noCacheNorParameters
                }
                
                guard let id = srcId else {
                    throw Error.missingSourceId
                }
                let entry = ParticleNetworkEvolver.Cache.Entry(inputId: id, size: size, iterations: 1, maxPositionValue: position)
                parameters = try ParticleNetworkEvolver.Cache(path: cache).parameters(forEntry: entry, rounding: true)
                
                if parameters == nil {
                    throw Error.noCacheEntryFound
                }
                
            }
            if let nonOptional = parameters {
                dump(nonOptional)
            }
        }
        
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        
        var populations: [DataGenerator] = []
        
        var emptyEntries: [Double: DataGenerator.Entry] = [:]
        
        for sec in seconds {
            emptyEntries[sec] = DataGenerator.Entry(elements: [])
        }
        if parameters != nil {
            let particle = ParticleNetworkEvolver(parameters: parameters, fitnessFunction: { (member, input) -> Double in
                let cmp = input.map { current -> (Double, Double) in
                    let feed = member.feedforward(acc: current.gene)[0]
                    return (feed, current.expectedResult)
                }
                return rmse(cmp)
            }) { (lhs, rhs) -> Bool in
                return lhs.fitness < rhs.fitness
            }
            
            
            let population = Population(withInput: input, size: size, evolutionAlgorithm: particle) {
                return ParticleNNetIndividual.random(neurons: [input[0].gene.count, 8, 6, 1], maxValue: Double(position))
            }
            populations.append(DataGenerator(population: population!, name: "PSO", entries: emptyEntries))
        }
        
        if genetic {
            guard let population = Population<GeneticEvolver<NNetIndividual, [InputData]>>(withInput: input, size: size, evolutionAlgorithm: GeneticEvolver.init(maxChromosomeValue: position, mutationProbability: 0.6, crossoverProbability: 0.6, optimization: .min, mutationMethods: mutation, fitnessFunction: { (member, input) -> Double in
                let cmp = input.map { current -> (Double, Double) in
                    let feed = member.feedforward(acc: current.gene)[0]
                    return (feed, current.expectedResult)
                }
                return rmse(cmp)
                
            }, fitnessOptimization: <), newInstanceFunction: { return NNetIndividual.random(neurons: [input[0].gene.count, 8, 6, 1] , maxValue: Double(position)) } ) else {
                throw Error.populationInitializationError
            }
            populations.append(DataGenerator(population: population, name: "Genetic", entries: emptyEntries))
        }
        
        if backprop {
            populations.append(DataGenerator(population: GradientPopulation(neurons: [input[0].gene.count, 8, 6, 1], maxValue: Double(position), epochs: 20, momentum: momentum, eta: eta, input: InputData.raw(input)), name: "Backpropagation", entries: emptyEntries))
        }
        
        DispatchQueue.concurrentPerform(iterations: populations.count) { i in
            var population = populations[i]
            
            for _ in 0 ..< repeats {
                var currentSeconds = seconds
                
                population.population.initializePopulation(withSize: size)
                let startTime = Date()
                while let currentSec = currentSeconds.popLast() {
                    
                    while Date().timeIntervalSince(startTime) <= currentSec {
                        _ = population.population.evolve()
                    }
                    population.entries[currentSec]!.elements.append(population.population.best)
                }

            }
            
            let target = resultFolder.appendingPathComponent(population.name)
            
            var content = ""
            for entry in population.entries {
                content += "\(entry.key);"
                let value = entry.value.elements.reduce(0) {
                    $0.0 + $0.1
                } / Double(entry.value.elements.count)

                content += "\(value)\n"
            }
            try! content.write(toFile: target.path, atomically: true, encoding: .utf8)
            
        }
        print("Finished")
    }
}

do {
    try Console(arguments: CommandLine.arguments,
                commands: [
                    Generate(),
                    PSOParameters()
                ]
        )
        .run()
} catch {
    dump(error)
}



