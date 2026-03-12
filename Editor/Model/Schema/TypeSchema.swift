//
//  TypeSchema.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SwiftData
import System

/*
 Models for testing standard Swift value types and collection types.
 
 Note:
 - `Int128` and `UInt128` is not supported by `Schema`.
 - `Character` does not conform to `Codable`.
 */

struct TypeSchema: VersionedSchema {
    static var models: [any PersistentModel.Type] {
        [
            SupportedScalarType.self,
            SupportedOptionalScalarType.self,
            SupportedCollectionType.self,
            SupportedOptionalCollectionType.self
        ]
    }
    
    static var versionIdentifier: Schema.Version {
        .init(0, 0, 0)
    }
}

@Model final class SupportedScalarType {
    @Attribute(.unique) var id: String
    @Attribute var bool: Bool
    @Attribute var integer: Int
    @Attribute var integer8: Int8
    @Attribute var integer16: Int16
    @Attribute var integer32: Int32
    @Attribute var integer64: Int64
    @Attribute var unsignedInteger: UInt
    @Attribute var unsignedInteger8: UInt8
    @Attribute var unsignedInteger16: UInt16
    @Attribute var unsignedInteger32: UInt32
    @Attribute var unsignedInteger64: UInt64
    @Attribute var float: Float
    @Attribute var double: Double
    @Attribute var date: Date
    @Attribute var string: String
    @Attribute var filePath: FilePath
    @Attribute var url: URL
    @Attribute var uuid: UUID
    @Attribute var data: Data
    
    required init(
        id: String = "value-type",
        bool: Bool = Bool.random(),
        integer: Int = .random(in: .min ... .max),
        integer8: Int8 = .random(in: .min ... .max),
        integer16: Int16 = .random(in: .min ... .max),
        integer32: Int32 = .random(in: .min ... .max),
        integer64: Int64 = .random(in: .min ... .max),
        unsignedInteger: UInt = .random(in: 0 ... .init(clamping: Int64.max)),
        unsignedInteger8: UInt8 = .random(in: .min ... .max),
        unsignedInteger16: UInt16 = .random(in: .min ... .max),
        unsignedInteger32: UInt32 = .random(in: .min ... .max),
        unsignedInteger64: UInt64 = .random(in: 0 ... .init(Int64.max)),
        float: Float = .random(in: -1_000_000...1_000_000),
        double: Double = .random(in: -1_000_000...1_000_000),
        date: Date = .now,
        string: String = "Hello",
        filePath: FilePath = .init(NSTemporaryDirectory()),
        url: URL = .temporaryDirectory,
        uuid: UUID = .init(),
        data: Data = .init()
    ) {
        self.id = id
        self.bool = bool
        self.integer = integer
        self.integer8 = integer8
        self.integer16 = integer16
        self.integer32 = integer32
        self.integer64 = integer64
        self.unsignedInteger = unsignedInteger
        self.unsignedInteger8 = unsignedInteger8
        self.unsignedInteger16 = unsignedInteger16
        self.unsignedInteger32 = unsignedInteger32
        self.unsignedInteger64 = unsignedInteger64
        self.float = float
        self.double = double
        self.date = date
        self.string = string
        self.filePath = filePath
        self.url = url
        self.uuid = uuid
        self.data = data
    }
}

@Model final class SupportedOptionalScalarType {
    @Attribute(.unique) var id: String
    @Attribute var bool: Bool?
    @Attribute var integer: Int?
    @Attribute var integer8: Int8?
    @Attribute var integer16: Int16?
    @Attribute var integer32: Int32?
    @Attribute var integer64: Int64?
    @Attribute var unsignedInteger: UInt?
    @Attribute var unsignedInteger8: UInt8?
    @Attribute var unsignedInteger16: UInt16?
    @Attribute var unsignedInteger32: UInt32?
    @Attribute var unsignedInteger64: UInt64?
    @Attribute var float: Float?
    @Attribute var double: Double?
    @Attribute var date: Date?
    @Attribute var string: String?
    @Attribute var filePath: FilePath?
    @Attribute var url: URL?
    @Attribute var uuid: UUID?
    @Attribute var data: Data?
    
    required init(
        id: String = "optional-value-type",
        bool: Bool? = Bool.random()
        ? nil : Bool.random(),
        integer: Int? = Bool.random()
        ? nil : .random(in: .min ... .max),
        integer8: Int8? = Bool.random()
        ? nil : .random(in: .min ... .max),
        integer16: Int16? = Bool.random()
        ? nil : .random(in: .min ... .max),
        integer32: Int32? = Bool.random()
        ? nil : .random(in: .min ... .max),
        integer64: Int64? = Bool.random()
        ? nil : .random(in: .min ... .max),
        unsignedInteger: UInt? = Bool.random()
        ? nil : .random(in: 0 ... .init(clamping: Int64.max)),
        unsignedInteger8: UInt8? = Bool.random()
        ? nil : .random(in: .min ... .max),
        unsignedInteger16: UInt16? = Bool.random()
        ? nil : .random(in: .min ... .max),
        unsignedInteger32: UInt32? = Bool.random()
        ? nil : .random(in: .min ... .max),
        unsignedInteger64: UInt64? = Bool.random()
        ? nil : .random(in: 0 ... .init(Int64.max)),
        float: Float? = Bool.random()
        ? nil : .random(in: -1_000_000...1_000_000),
        double: Double? = Bool.random()
        ? nil : .random(in: -1_000_000...1_000_000),
        date: Date? = Bool.random()
        ? nil : .now,
        string: String? = Bool.random()
        ? nil : "Hello",
        filePath: FilePath? = Bool.random()
        ? nil : .init(NSTemporaryDirectory()),
        url: URL? = Bool.random()
        ? nil : .temporaryDirectory,
        uuid: UUID? = Bool.random()
        ? nil : .init(),
        data: Data? = Bool.random()
        ? nil : .init()
    ) {
        self.id = id
        self.bool = bool
        self.integer = integer
        self.integer8 = integer8
        self.integer16 = integer16
        self.integer32 = integer32
        self.integer64 = integer64
        self.unsignedInteger = unsignedInteger
        self.unsignedInteger8 = unsignedInteger8
        self.unsignedInteger16 = unsignedInteger16
        self.unsignedInteger32 = unsignedInteger32
        self.unsignedInteger64 = unsignedInteger64
        self.float = float
        self.double = double
        self.date = date
        self.string = string
        self.filePath = filePath
        self.url = url
        self.uuid = uuid
        self.data = data
    }
}

@Model final class SupportedCollectionType {
    @Attribute(.unique) var id: String
    @Attribute var boolArray: [Bool] = []
    @Attribute var integerArray: [Int] = []
    @Attribute var integer8Array: [Int8] = []
    @Attribute var integer16Array: [Int16] = []
    @Attribute var integer32Array: [Int32] = []
    @Attribute var integer64Array: [Int64] = []
    @Attribute var unsignedIntegerArray: [UInt] = []
    @Attribute var unsignedInteger8Array: [UInt8] = []
    @Attribute var unsignedInteger16Array: [UInt16] = []
    @Attribute var unsignedInteger32Array: [UInt32] = []
    @Attribute var unsignedInteger64Array: [UInt64] = []
    @Attribute var floatArray: [Float] = []
    @Attribute var doubleArray: [Double] = []
    @Attribute var dateArray: [Date] = []
    @Attribute var stringArray: [String] = []
    @Attribute var filePathArray: [FilePath] = []
    @Attribute var urlArray: [URL] = []
    @Attribute var uuidArray: [UUID] = []
    @Attribute var dataArray: [Data] = []
    @Attribute var boolSet: Set<Bool> = []
    @Attribute var integerSet: Set<Int> = []
    @Attribute var integer8Set: Set<Int8> = []
    @Attribute var integer16Set: Set<Int16> = []
    @Attribute var integer32Set: Set<Int32> = []
    @Attribute var integer64Set: Set<Int64> = []
    @Attribute var unsignedIntegerSet: Set<UInt> = []
    @Attribute var unsignedInteger8Set: Set<UInt8> = []
    @Attribute var unsignedInteger16Set: Set<UInt16> = []
    @Attribute var unsignedInteger32Set: Set<UInt32> = []
    @Attribute var unsignedInteger64Set: Set<UInt64> = []
    @Attribute var floatSet: Set<Float> = []
    @Attribute var doubleSet: Set<Double> = []
    @Attribute var dateSet: Set<Date> = []
    @Attribute var stringSet: Set<String> = []
    @Attribute var filePathSet: Set<FilePath> = []
    @Attribute var urlSet: Set<URL> = []
    @Attribute var uuidSet: Set<UUID> = []
    @Attribute var dataSet: Set<Data> = []
    @Attribute var boolDictionary: [String: Bool] = [:]
    @Attribute var integerDictionary: [String: Int] = [:]
    @Attribute var integer8Dictionary: [String: Int8] = [:]
    @Attribute var integer16Dictionary: [String: Int16] = [:]
    @Attribute var integer32Dictionary: [String: Int32] = [:]
    @Attribute var integer64Dictionary: [String: Int64] = [:]
    @Attribute var unsignedIntegerDictionary: [String: UInt] = [:]
    @Attribute var unsignedInteger8Dictionary: [String: UInt8] = [:]
    @Attribute var unsignedInteger16Dictionary: [String: UInt16] = [:]
    @Attribute var unsignedInteger32Dictionary: [String: UInt32] = [:]
    @Attribute var unsignedInteger64Dictionary: [String: UInt64] = [:]
    @Attribute var floatDictionary: [String: Float] = [:]
    @Attribute var doubleDictionary: [String: Double] = [:]
    @Attribute var dateDictionary: [String: Date] = [:]
    @Attribute var stringDictionary: [String: String] = [:]
    @Attribute var filePathDictionary: [String: FilePath] = [:]
    @Attribute var urlDictionary: [String: URL] = [:]
    @Attribute var uuidDictionary: [String: UUID] = [:]
    @Attribute var dataDictionary: [String: Data] = [:]
    
    required init(
        id: String = "collection-type",
        boolArray: [Bool] = [],
        integerArray: [Int] = [],
        integer8Array: [Int8] = [],
        integer16Array: [Int16] = [],
        integer32Array: [Int32] = [],
        integer64Array: [Int64] = [],
        unsignedIntegerArray: [UInt] = [],
        unsignedInteger8Array: [UInt8] = [],
        unsignedInteger16Array: [UInt16] = [],
        unsignedInteger32Array: [UInt32] = [],
        unsignedInteger64Array: [UInt64] = [],
        floatArray: [Float] = [],
        doubleArray: [Double] = [],
        dateArray: [Date] = [],
        stringArray: [String] = [],
        filePathArray: [FilePath] = [],
        urlArray: [URL] = [],
        uuidArray: [UUID] = [],
        dataArray: [Data] = [],
        boolSet: Set<Bool> = [],
        integerSet: Set<Int> = [],
        integer8Set: Set<Int8> = [],
        integer16Set: Set<Int16> = [],
        integer32Set: Set<Int32> = [],
        integer64Set: Set<Int64> = [],
        unsignedIntegerSet: Set<UInt> = [],
        unsignedInteger8Set: Set<UInt8> = [],
        unsignedInteger16Set: Set<UInt16> = [],
        unsignedInteger32Set: Set<UInt32> = [],
        unsignedInteger64Set: Set<UInt64> = [],
        floatSet: Set<Float> = [],
        doubleSet: Set<Double> = [],
        dateSet: Set<Date> = [],
        stringSet: Set<String> = [],
        filePathSet: Set<FilePath> = [],
        urlSet: Set<URL> = [],
        uuidSet: Set<UUID> = [],
        dataSet: Set<Data> = [],
        boolDictionary: [String: Bool] = [:],
        integerDictionary: [String: Int] = [:],
        integer8Dictionary: [String: Int8] = [:],
        integer16Dictionary: [String: Int16] = [:],
        integer32Dictionary: [String: Int32] = [:],
        integer64Dictionary: [String: Int64] = [:],
        unsignedIntegerDictionary: [String: UInt] = [:],
        unsignedInteger8Dictionary: [String: UInt8] = [:],
        unsignedInteger16Dictionary: [String: UInt16] = [:],
        unsignedInteger32Dictionary: [String: UInt32] = [:],
        unsignedInteger64Dictionary: [String: UInt64] = [:],
        floatDictionary: [String: Float] = [:],
        doubleDictionary: [String: Double] = [:],
        dateDictionary: [String: Date] = [:],
        stringDictionary: [String: String] = [:],
        filePathDictionary: [String: FilePath] = [:],
        urlDictionary: [String: URL] = [:],
        uuidDictionary: [String: UUID] = [:],
        dataDictionary: [String: Data] = [:]
    ) {
        self.id = id
        self.boolArray = boolArray
        self.integerArray = integerArray
        self.integer8Array = integer8Array
        self.integer16Array = integer16Array
        self.integer32Array = integer32Array
        self.integer64Array = integer64Array
        self.unsignedIntegerArray = unsignedIntegerArray
        self.unsignedInteger8Array = unsignedInteger8Array
        self.unsignedInteger16Array = unsignedInteger16Array
        self.unsignedInteger32Array = unsignedInteger32Array
        self.unsignedInteger64Array = unsignedInteger64Array
        self.floatArray = floatArray
        self.doubleArray = doubleArray
        self.dateArray = dateArray
        self.stringArray = stringArray
        self.filePathArray = filePathArray
        self.urlArray = urlArray
        self.uuidArray = uuidArray
        self.dataArray = dataArray
        self.boolSet = boolSet
        self.integerSet = integerSet
        self.integer8Set = integer8Set
        self.integer16Set = integer16Set
        self.integer32Set = integer32Set
        self.integer64Set = integer64Set
        self.unsignedIntegerSet = unsignedIntegerSet
        self.unsignedInteger8Set = unsignedInteger8Set
        self.unsignedInteger16Set = unsignedInteger16Set
        self.unsignedInteger32Set = unsignedInteger32Set
        self.unsignedInteger64Set = unsignedInteger64Set
        self.floatSet = floatSet
        self.doubleSet = doubleSet
        self.dateSet = dateSet
        self.stringSet = stringSet
        self.filePathSet = filePathSet
        self.urlSet = urlSet
        self.uuidSet = uuidSet
        self.dataSet = dataSet
        self.boolDictionary = boolDictionary
        self.integerDictionary = integerDictionary
        self.integer8Dictionary = integer8Dictionary
        self.integer16Dictionary = integer16Dictionary
        self.integer32Dictionary = integer32Dictionary
        self.integer64Dictionary = integer64Dictionary
        self.unsignedIntegerDictionary = unsignedIntegerDictionary
        self.unsignedInteger8Dictionary = unsignedInteger8Dictionary
        self.unsignedInteger16Dictionary = unsignedInteger16Dictionary
        self.unsignedInteger32Dictionary = unsignedInteger32Dictionary
        self.unsignedInteger64Dictionary = unsignedInteger64Dictionary
        self.floatDictionary = floatDictionary
        self.doubleDictionary = doubleDictionary
        self.dateDictionary = dateDictionary
        self.stringDictionary = stringDictionary
        self.filePathDictionary = filePathDictionary
        self.urlDictionary = urlDictionary
        self.uuidDictionary = uuidDictionary
        self.dataDictionary = dataDictionary
    }
}

@Model final class SupportedOptionalCollectionType {
    @Attribute(.unique) var id: String
    @Attribute var boolArray: [Bool]?
    @Attribute var integerArray: [Int]?
    @Attribute var integer8Array: [Int8]?
    @Attribute var integer16Array: [Int16]?
    @Attribute var integer32Array: [Int32]?
    @Attribute var integer64Array: [Int64]?
    @Attribute var unsignedIntegerArray: [UInt]?
    @Attribute var unsignedInteger8Array: [UInt8]?
    @Attribute var unsignedInteger16Array: [UInt16]?
    @Attribute var unsignedInteger32Array: [UInt32]?
    @Attribute var unsignedInteger64Array: [UInt64]?
    @Attribute var floatArray: [Float]?
    @Attribute var doubleArray: [Double]?
    @Attribute var dateArray: [Date]?
    @Attribute var stringArray: [String]?
    @Attribute var filePathArray: [FilePath]?
    @Attribute var urlArray: [URL]?
    @Attribute var uuidArray: [UUID]?
    @Attribute var dataArray: [Data]?
    @Attribute var boolSet: Set<Bool>?
    @Attribute var integerSet: Set<Int>?
    @Attribute var integer8Set: Set<Int8>?
    @Attribute var integer16Set: Set<Int16>?
    @Attribute var integer32Set: Set<Int32>?
    @Attribute var integer64Set: Set<Int64>?
    @Attribute var unsignedIntegerSet: Set<UInt>?
    @Attribute var unsignedInteger8Set: Set<UInt8>?
    @Attribute var unsignedInteger16Set: Set<UInt16>?
    @Attribute var unsignedInteger32Set: Set<UInt32>?
    @Attribute var unsignedInteger64Set: Set<UInt64>?
    @Attribute var floatSet: Set<Float>?
    @Attribute var doubleSet: Set<Double>?
    @Attribute var dateSet: Set<Date>?
    @Attribute var stringSet: Set<String>?
    @Attribute var filePathSet: Set<FilePath>?
    @Attribute var urlSet: Set<URL>?
    @Attribute var uuidSet: Set<UUID>?
    @Attribute var dataSet: Set<Data>?
    @Attribute var boolDictionary: [String: Bool]?
    @Attribute var integerDictionary: [String: Int]?
    @Attribute var integer8Dictionary: [String: Int8]?
    @Attribute var integer16Dictionary: [String: Int16]?
    @Attribute var integer32Dictionary: [String: Int32]?
    @Attribute var integer64Dictionary: [String: Int64]?
    @Attribute var unsignedIntegerDictionary: [String: UInt]?
    @Attribute var unsignedInteger8Dictionary: [String: UInt8]?
    @Attribute var unsignedInteger16Dictionary: [String: UInt16]?
    @Attribute var unsignedInteger32Dictionary: [String: UInt32]?
    @Attribute var unsignedInteger64Dictionary: [String: UInt64]?
    @Attribute var floatDictionary: [String: Float]?
    @Attribute var doubleDictionary: [String: Double]?
    @Attribute var dateDictionary: [String: Date]?
    @Attribute var stringDictionary: [String: String]?
    @Attribute var filePathDictionary: [String: FilePath]?
    @Attribute var urlDictionary: [String: URL]?
    @Attribute var uuidDictionary: [String: UUID]?
    @Attribute var dataDictionary: [String: Data]?
    
    required init(
        id: String = "optional-collection-type",
        boolArray: [Bool]? = Bool.random() ? nil : [],
        integerArray: [Int]? = Bool.random() ? nil : [],
        integer8Array: [Int8]? = Bool.random() ? nil : [],
        integer16Array: [Int16]? = Bool.random() ? nil : [],
        integer32Array: [Int32]? = Bool.random() ? nil : [],
        integer64Array: [Int64]? = Bool.random() ? nil : [],
        unsignedIntegerArray: [UInt]? = Bool.random() ? nil : [],
        unsignedInteger8Array: [UInt8]? = Bool.random() ? nil : [],
        unsignedInteger16Array: [UInt16]? = Bool.random() ? nil : [],
        unsignedInteger32Array: [UInt32]? = Bool.random() ? nil : [],
        unsignedInteger64Array: [UInt64]? = Bool.random() ? nil : [],
        floatArray: [Float]? = Bool.random() ? nil : [],
        doubleArray: [Double]? = Bool.random() ? nil : [],
        dateArray: [Date]? = Bool.random() ? nil : [],
        stringArray: [String]? = Bool.random() ? nil : [],
        filePathArray: [FilePath]? = Bool.random() ? nil : [],
        urlArray: [URL]? = Bool.random() ? nil : [],
        uuidArray: [UUID]? = Bool.random() ? nil : [],
        dataArray: [Data]? = Bool.random() ? nil : [],
        boolSet: Set<Bool>? = Bool.random() ? nil : [],
        integerSet: Set<Int>? = Bool.random() ? nil : [],
        integer8Set: Set<Int8>? = Bool.random() ? nil : [],
        integer16Set: Set<Int16>? = Bool.random() ? nil : [],
        integer32Set: Set<Int32>? = Bool.random() ? nil : [],
        integer64Set: Set<Int64>? = Bool.random() ? nil : [],
        unsignedIntegerSet: Set<UInt>? = Bool.random() ? nil : [],
        unsignedInteger8Set: Set<UInt8>? = Bool.random() ? nil : [],
        unsignedInteger16Set: Set<UInt16>? = Bool.random() ? nil : [],
        unsignedInteger32Set: Set<UInt32>? = Bool.random() ? nil : [],
        unsignedInteger64Set: Set<UInt64>? = Bool.random() ? nil : [],
        floatSet: Set<Float>? = Bool.random() ? nil : [],
        doubleSet: Set<Double>? = Bool.random() ? nil : [],
        dateSet: Set<Date>? = Bool.random() ? nil : [],
        stringSet: Set<String>? = Bool.random() ? nil : [],
        filePathSet: Set<FilePath>? = Bool.random() ? nil : [],
        urlSet: Set<URL>? = Bool.random() ? nil : [],
        uuidSet: Set<UUID>? = Bool.random() ? nil : [],
        dataSet: Set<Data>? = Bool.random() ? nil : [],
        boolDictionary: [String: Bool]? = Bool.random() ? nil : [:],
        integerDictionary: [String: Int]? = Bool.random() ? nil : [:],
        integer8Dictionary: [String: Int8]? = Bool.random() ? nil : [:],
        integer16Dictionary: [String: Int16]? = Bool.random() ? nil : [:],
        integer32Dictionary: [String: Int32]? = Bool.random() ? nil : [:],
        integer64Dictionary: [String: Int64]? = Bool.random() ? nil : [:],
        unsignedIntegerDictionary: [String: UInt]? = Bool.random() ? nil : [:],
        unsignedInteger8Dictionary: [String: UInt8]? = Bool.random() ? nil : [:],
        unsignedInteger16Dictionary: [String: UInt16]? = Bool.random() ? nil : [:],
        unsignedInteger32Dictionary: [String: UInt32]? = Bool.random() ? nil : [:],
        unsignedInteger64Dictionary: [String: UInt64]? = Bool.random() ? nil : [:],
        floatDictionary: [String: Float]? = Bool.random() ? nil : [:],
        doubleDictionary: [String: Double]? = Bool.random() ? nil : [:],
        dateDictionary: [String: Date]? = Bool.random() ? nil : [:],
        stringDictionary: [String: String]? = Bool.random() ? nil : [:],
        filePathDictionary: [String: FilePath]? = Bool.random() ? nil : [:],
        urlDictionary: [String: URL]? = Bool.random() ? nil : [:],
        uuidDictionary: [String: UUID]? = Bool.random() ? nil : [:],
        dataDictionary: [String: Data]? = Bool.random() ? nil : [:]
    ) {
        self.id = id
        self.boolArray = boolArray
        self.integerArray = integerArray
        self.integer8Array = integer8Array
        self.integer16Array = integer16Array
        self.integer32Array = integer32Array
        self.integer64Array = integer64Array
        self.unsignedIntegerArray = unsignedIntegerArray
        self.unsignedInteger8Array = unsignedInteger8Array
        self.unsignedInteger16Array = unsignedInteger16Array
        self.unsignedInteger32Array = unsignedInteger32Array
        self.unsignedInteger64Array = unsignedInteger64Array
        self.floatArray = floatArray
        self.doubleArray = doubleArray
        self.dateArray = dateArray
        self.stringArray = stringArray
        self.filePathArray = filePathArray
        self.urlArray = urlArray
        self.uuidArray = uuidArray
        self.dataArray = dataArray
        self.boolSet = boolSet
        self.integerSet = integerSet
        self.integer8Set = integer8Set
        self.integer16Set = integer16Set
        self.integer32Set = integer32Set
        self.integer64Set = integer64Set
        self.unsignedIntegerSet = unsignedIntegerSet
        self.unsignedInteger8Set = unsignedInteger8Set
        self.unsignedInteger16Set = unsignedInteger16Set
        self.unsignedInteger32Set = unsignedInteger32Set
        self.unsignedInteger64Set = unsignedInteger64Set
        self.floatSet = floatSet
        self.doubleSet = doubleSet
        self.dateSet = dateSet
        self.stringSet = stringSet
        self.filePathSet = filePathSet
        self.urlSet = urlSet
        self.uuidSet = uuidSet
        self.dataSet = dataSet
        self.boolDictionary = boolDictionary
        self.integerDictionary = integerDictionary
        self.integer8Dictionary = integer8Dictionary
        self.integer16Dictionary = integer16Dictionary
        self.integer32Dictionary = integer32Dictionary
        self.integer64Dictionary = integer64Dictionary
        self.unsignedIntegerDictionary = unsignedIntegerDictionary
        self.unsignedInteger8Dictionary = unsignedInteger8Dictionary
        self.unsignedInteger16Dictionary = unsignedInteger16Dictionary
        self.unsignedInteger32Dictionary = unsignedInteger32Dictionary
        self.unsignedInteger64Dictionary = unsignedInteger64Dictionary
        self.floatDictionary = floatDictionary
        self.doubleDictionary = doubleDictionary
        self.dateDictionary = dateDictionary
        self.stringDictionary = stringDictionary
        self.filePathDictionary = filePathDictionary
        self.urlDictionary = urlDictionary
        self.uuidDictionary = uuidDictionary
        self.dataDictionary = dataDictionary
    }
}
