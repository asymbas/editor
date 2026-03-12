//
//  MigrationSchema.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SwiftData

enum MigrationSchema {
    #if true // MIGRATION_SCHEMA_USE_V2
    typealias Active = MigrationSchemaV2
    #else
    typealias Active = MigrationSchemaV1
    #endif
}

enum MigrationAuxiliarySchema {
    #if MIGRATION_AUXILIARY_SCHEMA_USE_V2
    typealias Active = MigrationAuxiliarySchemaV2
    #else
    typealias Active = MigrationAuxiliarySchemaV1
    #endif
}

enum MigrationSchemaShared {
    struct Money: Codable, Hashable, Sendable {
        var currencyCode: String
        var minorUnits: Int64
        
        init(currencyCode: String = "USD", minorUnits: Int64) {
            self.currencyCode = currencyCode
            self.minorUnits = minorUnits
        }
    }
    
    struct Audit: Codable, Hashable, Sendable {
        var createdAt: Date
        var updatedAt: Date
        var revision: Int
        
        init(
            createdAt: Date = .now,
            updatedAt: Date = .now,
            revision: Int = 0
        ) {
            self.createdAt = createdAt
            self.updatedAt = updatedAt
            self.revision = revision
        }
    }
    
    struct Dimensions: Codable, Hashable, Sendable {
        var widthMM: Int
        var heightMM: Int
        var depthMM: Int
        
        init(widthMM: Int, heightMM: Int, depthMM: Int) {
            self.widthMM = widthMM
            self.heightMM = heightMM
            self.depthMM = depthMM
        }
    }
}

struct MigrationSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { .init(1, 0, 0) }
    
    static var models: [any PersistentModel.Type] {
        [
            Entity.Customer.self,
            Entity.CustomerProfile.self,
            Entity.Address.self,
            Entity.Product.self,
            //            Entity.DigitalProduct.self,
            //            Entity.PhysicalProduct.self,
            Entity.Category.self,
            Entity.Order.self,
            Entity.LineItem.self,
            Entity.Payment.self,
            Entity.Shipment.self,
            Entity.SupportCase.self,
            Entity.SupportAttachment.self
        ]
    }
    
    enum Entity {
        @Model final class Customer {
            #Unique<Customer>([\.id], [\.email])
            #Index<Customer>([\.id, \.email])
            
            @Attribute(.unique, .preserveValueOnDeletion) var id: String
            @Attribute(.preserveValueOnDeletion) var email: String
            @Attribute var audit: MigrationSchemaShared.Audit
            @Attribute var displayName: String
            @Attribute var flags: Set<Flag>
            @Attribute var preferences: [String: String]
            
            @Relationship(
                deleteRule: .cascade,
                inverse: \Entity.CustomerProfile.customer
            ) var profile: CustomerProfile?
            
            @Relationship(
                deleteRule: .nullify,
                inverse: \Entity.Order.customer
            ) var orders: [Order] = []
            
            @Relationship(
                deleteRule: .nullify,
                inverse: \Entity.SupportCase.requester
            ) var cases: [SupportCase] = []
            
            @Relationship(
                deleteRule: .cascade,
                minimumModelCount: 0,
                maximumModelCount: 1
            ) var shippingAddress: Address?
            
            init(
                id: String = UUID().uuidString,
                email: String,
                audit: MigrationSchemaShared.Audit = .init(),
                displayName: String,
                flags: Set<Flag> = [.active],
                preferences: [String: String] = [:],
                profile: CustomerProfile? = nil,
                shippingAddress: Address? = nil
            ) {
                self.id = id
                self.email = email
                self.audit = audit
                self.displayName = displayName
                self.flags = flags
                self.preferences = preferences
                self.profile = profile
                self.shippingAddress = shippingAddress
            }
            
            struct Flag: Codable, Hashable, RawRepresentable, Sendable {
                static let active: Self = .init(rawValue: 1)
                static let vip: Self = .init(rawValue: 2)
                static let suspended: Self = .init(rawValue: 4)
                let rawValue: UInt8
                
                init(rawValue: UInt8) { self.rawValue = rawValue }
            }
        }
        
        @Model final class CustomerProfile {
            #Unique<CustomerProfile>([\.id])
            #Index<CustomerProfile>([\.loyaltyPoints])
            
            @Attribute(.unique, .preserveValueOnDeletion) var id: String
            @Attribute var nickname: String?
            @Attribute var loyaltyPoints: Int
            @Attribute(.externalStorage) var avatarData: Data?
            
            @Relationship(.unique)
            var customer: Customer
            
            init(
                id: String = UUID().uuidString,
                nickname: String? = nil,
                loyaltyPoints: Int = 0,
                avatarData: Data? = nil,
                customer: Customer
            ) {
                self.id = id
                self.nickname = nickname
                self.loyaltyPoints = loyaltyPoints
                self.avatarData = avatarData
                self.customer = customer
            }
        }
        
        @Model final class Address {
            #Unique<Address>([\.id])
            #Index<Address>([\.postalCode, \.countryCode])
            
            @Attribute(.unique, .preserveValueOnDeletion) var id: String
            @Attribute var line1: String
            @Attribute var line2: String?
            @Attribute var city: String
            @Attribute var region: String
            @Attribute var postalCode: String
            @Attribute var countryCode: String
            
            init(
                id: String = UUID().uuidString,
                line1: String,
                line2: String? = nil,
                city: String,
                region: String,
                postalCode: String,
                countryCode: String
            ) {
                self.id = id
                self.line1 = line1
                self.line2 = line2
                self.city = city
                self.region = region
                self.postalCode = postalCode
                self.countryCode = countryCode
            }
        }
        
        @Model class Product {
            #Unique<Product>([\.sku])
            #Index<Product>([\.sku, \.title])
            
            @Attribute(.unique, .preserveValueOnDeletion) var sku: String
            @Attribute var audit: MigrationSchemaShared.Audit
            @Attribute var title: String
            @Attribute var price: MigrationSchemaShared.Money
            @Attribute var isDiscontinued: Bool
            
            @Relationship(deleteRule: .nullify, inverse: \Entity.LineItem.product)
            var lineItems: [LineItem] = []
            
            @Relationship(deleteRule: .nullify, inverse: \Entity.Category.products)
            var categories: [Category] = []
            
            init(
                sku: String,
                audit: MigrationSchemaShared.Audit = .init(),
                title: String,
                price: MigrationSchemaShared.Money,
                isDiscontinued: Bool = false,
                categories: [Category] = []
            ) {
                self.sku = sku
                self.audit = audit
                self.title = title
                self.price = price
                self.isDiscontinued = isDiscontinued
                self.categories = categories
            }
        }
        
        #if false
        
        @Model final class DigitalProduct: Product {
            @Attribute var downloadURL: String
            @Attribute var licenseKey: String?
            
            init(
                sku: String,
                title: String,
                price: MigrationSchemaShared.Money,
                downloadURL: String,
                licenseKey: String? = nil,
                isDiscontinued: Bool = false
            ) {
                self.downloadURL = downloadURL
                self.licenseKey = licenseKey
                super.init(
                    sku: sku,
                    title: title,
                    price: price,
                    isDiscontinued: isDiscontinued
                )
            }
        }
        
        @Model final class PhysicalProduct: Product {
            @Attribute var weightGrams: Int
            @Attribute var dimensions: MigrationSchemaShared.Dimensions
            @Attribute(.externalStorage) var heroImage: Data?
            
            init(
                sku: String,
                title: String,
                price: MigrationSchemaShared.Money,
                weightGrams: Int,
                dimensions: MigrationSchemaShared.Dimensions,
                heroImage: Data? = nil,
                isDiscontinued: Bool = false
            ) {
                self.weightGrams = weightGrams
                self.dimensions = dimensions
                self.heroImage = heroImage
                super.init(
                    sku: sku,
                    title: title,
                    price: price,
                    isDiscontinued: isDiscontinued
                )
            }
        }
        
        #endif
        
        @Model final class Category {
            #Unique<Category>([\.code])
            #Index<Category>([\.code])
            
            @Attribute(.unique, .preserveValueOnDeletion) var code: String
            @Attribute var name: String
            
            @Relationship(deleteRule: .nullify)
            var products: [Product] = []
            
            init(code: String, name: String, products: [Product] = []) {
                self.code = code
                self.name = name
                self.products = products
            }
        }
        
        @Model final class Order {
            #Unique<Order>([\.id])
            #Index<Order>([\.placedAt])
            
            @Attribute(.unique, .preserveValueOnDeletion) var id: String
            @Attribute var placedAt: Date
            @Attribute var status: Status
            @Attribute var subtotal: MigrationSchemaShared.Money
            @Attribute var notes: String?
            
            @Relationship
            var customer: Customer
            
            @Relationship(
                deleteRule: .cascade,
                minimumModelCount: 1,
                inverse: \Entity.LineItem.order
            ) var lineItems: [LineItem] = []
            
            @Relationship(
                deleteRule: .cascade,
                minimumModelCount: 0,
                maximumModelCount: 1
            ) var payment: Payment?
            
            @Relationship(
                deleteRule: .cascade,
                minimumModelCount: 0,
                maximumModelCount: 1
            ) var shipment: Shipment?
            
            init(
                id: String = UUID().uuidString,
                placedAt: Date = .now,
                status: Status = .pending,
                subtotal: MigrationSchemaShared.Money,
                notes: String? = nil,
                customer: Customer,
                lineItems: [LineItem] = [],
                payment: Payment? = nil,
                shipment: Shipment? = nil
            ) {
                self.id = id
                self.placedAt = placedAt
                self.status = status
                self.subtotal = subtotal
                self.notes = notes
                self.customer = customer
                self.lineItems = lineItems
                self.payment = payment
                self.shipment = shipment
            }
            
            enum Status: UInt8, CaseIterable, Codable, Sendable {
                case pending
                case paid
                case shipped
                case cancelled
            }
        }
        
        @Model final class LineItem {
            #Index<LineItem>([\.quantity])
            
            @Attribute var quantity: Int
            @Attribute var unitPrice: MigrationSchemaShared.Money
            
            @Relationship
            var order: Order
            
            @Relationship
            var product: Product
            
            init(
                quantity: Int,
                unitPrice: MigrationSchemaShared.Money,
                order: Order,
                product: Product
            ) {
                self.quantity = quantity
                self.unitPrice = unitPrice
                self.order = order
                self.product = product
            }
        }
        
        @Model final class Payment {
            #Unique<Payment>([\.id])
            #Index<Payment>([\.capturedAt])
            
            @Attribute(.unique, .preserveValueOnDeletion) var id: String
            @Attribute var method: Method
            @Attribute var capturedAt: Date?
            @Attribute var amount: MigrationSchemaShared.Money
            
            init(
                id: String = UUID().uuidString,
                method: Method,
                capturedAt: Date? = nil,
                amount: MigrationSchemaShared.Money
            ) {
                self.id = id
                self.method = method
                self.capturedAt = capturedAt
                self.amount = amount
            }
            
            enum Method: UInt8, CaseIterable, Codable, Sendable {
                case card
                case bankTransfer
                case cashOnDelivery
            }
        }
        
        @Model final class Shipment {
            #Unique<Shipment>([\.id])
            
            @Attribute(.unique, .preserveValueOnDeletion) var id: String
            @Attribute var carrier: String
            @Attribute var trackingNumber: String?
            @Attribute var shippedAt: Date?
            
            @Relationship(
                deleteRule: .nullify,
                minimumModelCount: 0,
                maximumModelCount: 1
            ) var destination: Address?
            
            init(
                id: String = UUID().uuidString,
                carrier: String,
                trackingNumber: String? = nil,
                shippedAt: Date? = nil,
                destination: Address? = nil
            ) {
                self.id = id
                self.carrier = carrier
                self.trackingNumber = trackingNumber
                self.shippedAt = shippedAt
                self.destination = destination
            }
        }
        
        @Model final class SupportCase {
            #Unique<SupportCase>([\.id])
            #Index<SupportCase>([\.openedAt])
            
            @Attribute(.unique, .preserveValueOnDeletion) var id: String
            @Attribute var openedAt: Date
            @Attribute var state: State
            @Attribute var subject: String
            @Attribute var details: String
            
            @Relationship
            var requester: Customer
            
            @Relationship(
                deleteRule: .cascade,
                minimumModelCount: 0,
                maximumModelCount: 10,
                inverse: \Entity.SupportAttachment.case
            ) var attachments: [SupportAttachment] = []
            
            init(
                id: String = UUID().uuidString,
                openedAt: Date = .now,
                state: State = .open,
                subject: String,
                details: String,
                requester: Customer,
                attachments: [SupportAttachment] = []
            ) {
                self.id = id
                self.openedAt = openedAt
                self.state = state
                self.subject = subject
                self.details = details
                self.requester = requester
                self.attachments = attachments
            }
            
            enum State: UInt8, CaseIterable, Codable, Sendable {
                case open
                case waitingOnCustomer
                case resolved
                case closed
            }
        }
        
        @Model final class SupportAttachment {
            #Unique<SupportAttachment>([\.id])
            
            @Attribute(.unique, .preserveValueOnDeletion) var id: String
            @Attribute var filename: String
            @Attribute var mimeType: String
            @Attribute(.externalStorage) var payload: Data?
            
            @Relationship
            var `case`: SupportCase
            
            init(
                id: String = UUID().uuidString,
                filename: String,
                mimeType: String,
                payload: Data? = nil,
                case: SupportCase
            ) {
                self.id = id
                self.filename = filename
                self.mimeType = mimeType
                self.payload = payload
                self.case = `case`
            }
        }
    }
}

struct MigrationSchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version { .init(2, 0, 0) }
    
    static var models: [any PersistentModel.Type] {
        [
            Entity.Customer.self,
            Entity.CustomerProfile.self,
            Entity.Address.self,
            Entity.Vendor.self,
            Entity.Product.self,
            Entity.ProductCategoryLink.self,
            Entity.Category.self,
            Entity.Order.self,
            Entity.LineItem.self,
            Entity.Payment.self,
            Entity.Shipment.self,
            Entity.SupportCase.self,
            Entity.SupportAttachment.self
        ]
    }
    
    enum Entity {
        @Model final class Customer {
            #Unique<Customer>([\.id], [\.email])
            #Index<Customer>([\.email, \.displayName])
            
            @Attribute(.unique, .preserveValueOnDeletion) var id: String
            @Attribute(.preserveValueOnDeletion) var email: String
            @Attribute var audit: MigrationSchemaShared.Audit
            @Attribute var displayName: String
            @Attribute var marketingOptIn: Bool
            @Attribute var preferences: [String: String]
            
            @Relationship(
                deleteRule: .cascade,
                inverse: \Entity.CustomerProfile.customer
            ) var profile: CustomerProfile?
            
            @Relationship(
                deleteRule: .nullify,
                inverse: \Entity.Order.purchaser
            ) var orders: [Order] = []
            
            @Relationship(
                deleteRule: .cascade,
                minimumModelCount: 0,
                maximumModelCount: 5,
                inverse: \Entity.Address.owner
            ) var addresses: [Address] = []
            
            @Relationship(
                deleteRule: .nullify,
                minimumModelCount: 0,
                maximumModelCount: 1
            ) var primaryAddress: Address?
            
            init(
                id: String = UUID().uuidString,
                email: String,
                audit: MigrationSchemaShared.Audit = .init(),
                displayName: String,
                marketingOptIn: Bool = false,
                preferences: [String: String] = [:],
                profile: CustomerProfile? = nil,
                addresses: [Address] = [],
                primaryAddress: Address? = nil
            ) {
                self.id = id
                self.email = email
                self.audit = audit
                self.displayName = displayName
                self.marketingOptIn = marketingOptIn
                self.preferences = preferences
                self.profile = profile
                self.addresses = addresses
                self.primaryAddress = primaryAddress
            }
        }
        
        @Model final class CustomerProfile {
            #Unique<CustomerProfile>([\.id])
            #Index<CustomerProfile>([\.tier])
            
            @Attribute(.unique, .preserveValueOnDeletion) var id: String
            @Attribute var nickname: String?
            @Attribute var tier: Tier
            @Attribute var avatarData: Data?
            @Attribute(.externalStorage) var bannerData: Data?
            
            @Relationship(.unique)
            var customer: Customer
            
            init(
                id: String = UUID().uuidString,
                nickname: String? = nil,
                tier: Tier = .standard,
                avatarData: Data? = nil,
                bannerData: Data? = nil,
                customer: Customer
            ) {
                self.id = id
                self.nickname = nickname
                self.tier = tier
                self.avatarData = avatarData
                self.bannerData = bannerData
                self.customer = customer
            }
            
            enum Tier: UInt8, CaseIterable, Codable, Sendable {
                case standard
                case plus
                case premium
            }
        }
        
        @Model final class Address {
            #Unique<Address>([\.id])
            #Index<Address>([\.postalCode])
            
            @Attribute(.unique, .preserveValueOnDeletion) var id: String
            @Attribute var label: String
            @Attribute var line1: String
            @Attribute var city: String
            @Attribute var region: String
            @Attribute var postalCode: String
            @Attribute var countryCode: String
            
            @Relationship
            var owner: Customer
            
            init(
                id: String = UUID().uuidString,
                label: String,
                line1: String,
                city: String,
                region: String,
                postalCode: String,
                countryCode: String,
                owner: Customer
            ) {
                self.id = id
                self.label = label
                self.line1 = line1
                self.city = city
                self.region = region
                self.postalCode = postalCode
                self.countryCode = countryCode
                self.owner = owner
            }
        }
        
        @Model final class Vendor {
            #Unique<Vendor>([\.id], [\.name])
            
            @Attribute(.unique, .preserveValueOnDeletion) var id: String
            @Attribute var name: String
            
            @Relationship(deleteRule: .nullify, inverse: \Entity.Product.vendor)
            var products: [Product] = []
            
            init(id: String = UUID().uuidString, name: String) {
                self.id = id
                self.name = name
            }
        }
        
        @Model final class Product {
            #Index<Product>([\.title])
            #Unique<Product>([\.vendorID, \.sku])
            
            @Attribute(.preserveValueOnDeletion) var vendorID: String
            @Attribute(.preserveValueOnDeletion) var sku: String
            @Attribute var audit: MigrationSchemaShared.Audit
            @Attribute var title: String
            @Attribute var price: MigrationSchemaShared.Money
            @Attribute var kind: Kind
            @Attribute var weightGrams: Int?
            @Attribute var downloadURL: String?
            @Attribute(.externalStorage) var heroImage: Data?
            
            @Relationship
            var vendor: Vendor
            
            @Relationship(
                deleteRule: .cascade,
                inverse: \Entity.ProductCategoryLink.product
            ) var categoryLinks: [ProductCategoryLink] = []
            
            @Relationship(
                deleteRule: .nullify,
                inverse: \Entity.LineItem.product
            ) var lineItems: [LineItem] = []
            
            init(
                vendorID: String,
                sku: String,
                audit: MigrationSchemaShared.Audit = .init(),
                title: String,
                price: MigrationSchemaShared.Money,
                kind: Kind,
                weightGrams: Int? = nil,
                downloadURL: String? = nil,
                heroImage: Data? = nil,
                vendor: Vendor
            ) {
                self.vendorID = vendorID
                self.sku = sku
                self.audit = audit
                self.title = title
                self.price = price
                self.kind = kind
                self.weightGrams = weightGrams
                self.downloadURL = downloadURL
                self.heroImage = heroImage
                self.vendor = vendor
            }
            
            enum Kind: UInt8, CaseIterable, Codable, Sendable {
                case physical
                case digital
            }
        }
        
        @Model final class Category {
            #Unique<Category>([\.code], [\.name])
            
            @Attribute(.unique, .preserveValueOnDeletion) var code: String
            @Attribute var name: String
            
            @Relationship(
                deleteRule: .cascade,
                inverse: \Entity.ProductCategoryLink.category
            ) var productLinks: [ProductCategoryLink] = []
            
            init(code: String, name: String) {
                self.code = code
                self.name = name
            }
        }
        
        @Model final class ProductCategoryLink {
            #Index<ProductCategoryLink>([\.rank])
            
            @Attribute var rank: Int
            @Attribute var addedAt: Date
            
            @Relationship
            var product: Product
            
            @Relationship
            var category: Category
            
            init(
                rank: Int = 0,
                addedAt: Date = .now,
                product: Product,
                category: Category
            ) {
                self.rank = rank
                self.addedAt = addedAt
                self.product = product
                self.category = category
            }
        }
        
        @Model final class Order {
            #Unique<Order>([\.id])
            #Index<Order>([\.placedAt, \.status])
            
            @Attribute(.unique, .preserveValueOnDeletion) var id: String
            @Attribute var placedAt: Date
            @Attribute var status: Status
            @Attribute var totals: Totals
            @Attribute var notes: String?
            
            @Relationship
            var purchaser: Customer
            
            @Relationship(
                deleteRule: .cascade,
                minimumModelCount: 1,
                maximumModelCount: 50,
                inverse: \Entity.LineItem.order
            ) var lineItems: [LineItem] = []
            
            @Relationship(
                deleteRule: .nullify,
                minimumModelCount: 0,
                maximumModelCount: 1
            ) var payment: Payment?
            
            @Relationship(
                deleteRule: .cascade,
                minimumModelCount: 0,
                maximumModelCount: 3
            ) var shipments: [Shipment] = []
            
            init(
                id: String = UUID().uuidString,
                placedAt: Date = .now,
                status: Status = .pending,
                totals: Totals,
                notes: String? = nil,
                purchaser: Customer,
                lineItems: [LineItem] = [],
                payment: Payment? = nil,
                shipments: [Shipment] = []
            ) {
                self.id = id
                self.placedAt = placedAt
                self.status = status
                self.totals = totals
                self.notes = notes
                self.purchaser = purchaser
                self.lineItems = lineItems
                self.payment = payment
                self.shipments = shipments
            }
            
            struct Totals: Codable, Hashable, Sendable {
                var subtotal: MigrationSchemaShared.Money
                var tax: MigrationSchemaShared.Money
                var shipping: MigrationSchemaShared.Money
                var grandTotal: MigrationSchemaShared.Money
                
                init(
                    subtotal: MigrationSchemaShared.Money,
                    tax: MigrationSchemaShared.Money,
                    shipping: MigrationSchemaShared.Money,
                    grandTotal: MigrationSchemaShared.Money
                ) {
                    self.subtotal = subtotal
                    self.tax = tax
                    self.shipping = shipping
                    self.grandTotal = grandTotal
                }
            }
            
            enum Status: UInt8, CaseIterable, Codable, Sendable {
                case pending
                case authorized
                case fulfilled
                case cancelled
            }
        }
        
        @Model final class LineItem {
            #Index<LineItem>([\.quantity])
            
            @Attribute var quantity: Int
            @Attribute var unitPrice: MigrationSchemaShared.Money
            @Attribute var discountMinorUnits: Int64
            
            @Relationship
            var order: Order
            
            @Relationship
            var product: Product
            
            init(
                quantity: Int,
                unitPrice: MigrationSchemaShared.Money,
                discountMinorUnits: Int64 = 0,
                order: Order,
                product: Product
            ) {
                self.quantity = quantity
                self.unitPrice = unitPrice
                self.discountMinorUnits = discountMinorUnits
                self.order = order
                self.product = product
            }
        }
        
        @Model final class Payment {
            #Unique<Payment>([\.id])
            
            @Attribute(.unique, .preserveValueOnDeletion) var id: String
            @Attribute var method: Method
            @Attribute var state: State
            @Attribute var capturedAt: Date?
            @Attribute var amount: MigrationSchemaShared.Money
            @Attribute var receiptData: Data?
            @Attribute(.externalStorage) var receiptArchive: Data?
            
            init(
                id: String = UUID().uuidString,
                method: Method,
                state: State = .initiated,
                capturedAt: Date? = nil,
                amount: MigrationSchemaShared.Money,
                receiptData: Data? = nil,
                receiptArchive: Data? = nil
            ) {
                self.id = id
                self.method = method
                self.state = state
                self.capturedAt = capturedAt
                self.amount = amount
                self.receiptData = receiptData
                self.receiptArchive = receiptArchive
            }
            
            enum Method: UInt8, CaseIterable, Codable, Sendable {
                case card
                case bankTransfer
                case wallet
            }
            
            enum State: UInt8, CaseIterable, Codable, Sendable {
                case initiated
                case authorized
                case captured
                case failed
            }
        }
        
        @Model final class Shipment {
            #Unique<Shipment>([\.id])
            #Index<Shipment>([\.shippedAt])
            
            @Attribute(.unique, .preserveValueOnDeletion) var id: String
            @Attribute var carrier: String
            @Attribute var trackingNumber: String?
            @Attribute var shippedAt: Date?
            @Attribute var deliveredAt: Date?
            
            @Relationship(
                deleteRule: .nullify,
                minimumModelCount: 0,
                maximumModelCount: 1
            ) var destination: Address?
            
            init(
                id: String = UUID().uuidString,
                carrier: String,
                trackingNumber: String? = nil,
                shippedAt: Date? = nil,
                deliveredAt: Date? = nil,
                destination: Address? = nil
            ) {
                self.id = id
                self.carrier = carrier
                self.trackingNumber = trackingNumber
                self.shippedAt = shippedAt
                self.deliveredAt = deliveredAt
                self.destination = destination
            }
        }
        
        @Model final class SupportCase {
            #Unique<SupportCase>([\.id])
            
            @Attribute(.unique, .preserveValueOnDeletion) var id: String
            @Attribute var openedAt: Date
            @Attribute var state: State
            @Attribute var subject: String
            @Attribute var details: String
            @Attribute var priority: Priority
            
            @Relationship
            var requester: Customer
            
            @Relationship(
                deleteRule: .cascade,
                minimumModelCount: 0,
                maximumModelCount: 20,
                inverse: \Entity.SupportAttachment.case
            ) var attachments: [SupportAttachment] = []
            
            init(
                id: String = UUID().uuidString,
                openedAt: Date = .now,
                state: State = .open,
                subject: String,
                details: String,
                priority: Priority = .normal,
                requester: Customer,
                attachments: [SupportAttachment] = []
            ) {
                self.id = id
                self.openedAt = openedAt
                self.state = state
                self.subject = subject
                self.details = details
                self.priority = priority
                self.requester = requester
                self.attachments = attachments
            }
            
            enum State: UInt8, CaseIterable, Codable, Sendable {
                case open
                case triaged
                case resolved
                case closed
            }
            
            enum Priority: UInt8, CaseIterable, Codable, Sendable {
                case low
                case normal
                case high
                case urgent
            }
        }
        
        @Model final class SupportAttachment {
            #Unique<SupportAttachment>([\.id])
            #Index<SupportAttachment>([\.filename])
            @Attribute(.unique, .preserveValueOnDeletion) var id: String
            @Attribute var filename: String
            @Attribute var mimeType: String
            @Attribute var payload: Data?
            @Attribute(.externalStorage) var payloadArchive: Data?
            
            @Relationship
            var `case`: SupportCase
            
            init(
                id: String = UUID().uuidString,
                filename: String,
                mimeType: String,
                payload: Data? = nil,
                payloadArchive: Data? = nil,
                case: SupportCase
            ) {
                self.id = id
                self.filename = filename
                self.mimeType = mimeType
                self.payload = payload
                self.payloadArchive = payloadArchive
                self.case = `case`
            }
        }
    }
}

struct MigrationAuxiliarySchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { .init(1, 0, 0) }
    
    static var models: [any PersistentModel.Type] {
        [
            Entity.Catalog.self,
            Entity.Artist.self,
            Entity.Album.self,
            Entity.Track.self,
            Entity.Playlist.self,
            Entity.PlaylistEntry.self,
            Entity.Artwork.self
        ]
    }
    
    enum Entity {
        @Model final class Catalog {
            #Unique<Catalog>([\.id])
            
            @Attribute(.unique, .preserveValueOnDeletion) var id: String
            @Attribute var name: String
            
            @Relationship(deleteRule: .cascade, inverse: \Entity.Album.catalog)
            var albums: [Album] = []
            
            @Relationship(deleteRule: .cascade, inverse: \Entity.Playlist.catalog)
            var playlists: [Playlist] = []
            
            init(id: String = UUID().uuidString, name: String) {
                self.id = id
                self.name = name
            }
        }
        
        @Model final class Artist {
            #Unique<Artist>([\.id], [\.name])
            
            @Attribute(.unique, .preserveValueOnDeletion) var id: String
            @Attribute(.preserveValueOnDeletion) var name: String
            @Attribute var countryCode: String?
            
            init(
                id: String = UUID().uuidString,
                name: String,
                countryCode: String? = nil
            ) {
                self.id = id
                self.name = name
                self.countryCode = countryCode
            }
        }
        
        @Model final class Album {
            #Unique<Album>([\.id])
            #Index<Album>([\.title, \.year])
            
            @Attribute(.unique, .preserveValueOnDeletion) var id: String
            @Attribute var title: String
            @Attribute var year: Int
            @Attribute var genre: String
            
            @Relationship
            var artist: Artist
            
            @Relationship
            var catalog: Catalog
            
            @Relationship(
                deleteRule: .cascade,
                minimumModelCount: 1,
                inverse: \Entity.Track.album
            ) var tracks: [Track] = []
            
            @Relationship(
                deleteRule: .cascade,
                minimumModelCount: 0,
                maximumModelCount: 1
            ) var artwork: Artwork?
            
            init(
                id: String = UUID().uuidString,
                title: String,
                year: Int,
                genre: String,
                artist: Artist,
                catalog: Catalog,
                tracks: [Track] = [],
                artwork: Artwork? = nil
            ) {
                self.id = id
                self.title = title
                self.year = year
                self.genre = genre
                self.artist = artist
                self.catalog = catalog
                self.tracks = tracks
                self.artwork = artwork
            }
        }
        
        @Model final class Track {
            #Unique<Track>([\.id])
            #Index<Track>([\.title])
            
            @Attribute(.unique, .preserveValueOnDeletion) var id: String
            @Attribute var title: String
            @Attribute var durationSeconds: Int
            @Attribute var trackNumber: Int
            
            @Relationship
            var album: Album
            
            init(
                id: String = UUID().uuidString,
                title: String,
                durationSeconds: Int,
                trackNumber: Int,
                album: Album
            ) {
                self.id = id
                self.title = title
                self.durationSeconds = durationSeconds
                self.trackNumber = trackNumber
                self.album = album
            }
        }
        
        @Model final class Playlist {
            #Unique<Playlist>([\.id])
            #Index<Playlist>([\.name])
            
            @Attribute(.unique, .preserveValueOnDeletion) var id: String
            @Attribute var name: String
            @Attribute var createdAt: Date
            
            @Relationship
            var catalog: Catalog
            
            @Relationship(deleteRule: .cascade, inverse: \Entity.PlaylistEntry.playlist)
            var entries: [PlaylistEntry] = []
            
            init(
                id: String = UUID().uuidString,
                name: String,
                createdAt: Date = .now,
                catalog: Catalog,
                entries: [PlaylistEntry] = []
            ) {
                self.id = id
                self.name = name
                self.createdAt = createdAt
                self.catalog = catalog
                self.entries = entries
            }
        }
        
        @Model final class PlaylistEntry {
            #Index<PlaylistEntry>([\.position])
            
            @Attribute var position: Int
            @Attribute var addedAt: Date
            
            @Relationship
            var playlist: Playlist
            
            @Relationship
            var track: Track
            
            init(
                position: Int,
                addedAt: Date = .now,
                playlist: Playlist,
                track: Track
            ) {
                self.position = position
                self.addedAt = addedAt
                self.playlist = playlist
                self.track = track
            }
        }
        
        @Model final class Artwork {
            #Unique<Artwork>([\.id])
            
            @Attribute(.unique, .preserveValueOnDeletion) var id: String
            @Attribute var mimeType: String
            @Attribute(.externalStorage) var imageData: Data?
            
            init(
                id: String = UUID().uuidString,
                mimeType: String,
                imageData: Data? = nil
            ) {
                self.id = id
                self.mimeType = mimeType
                self.imageData = imageData
            }
        }
    }
}

struct MigrationAuxiliarySchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version { .init(2, 0, 0) }
    
    static var models: [any PersistentModel.Type] {
        [
            Entity.Catalog.self,
            Entity.Artist.self,
            Entity.Album.self,
            Entity.Track.self,
            Entity.AlbumTrack.self,
            Entity.Playlist.self,
            Entity.PlaylistEntry.self
        ]
    }
    
    enum Entity {
        @Model final class Catalog {
            #Unique<Catalog>([\.id])
            
            @Attribute(.unique, .preserveValueOnDeletion) var id: String
            @Attribute var name: String
            @Attribute var regionCode: String
            
            @Relationship(deleteRule: .cascade, inverse: \Entity.Album.catalog)
            var albums: [Album] = []
            
            @Relationship(deleteRule: .cascade, inverse: \Entity.Playlist.catalog)
            var playlists: [Playlist] = []
            
            init(
                id: String = UUID().uuidString,
                name: String,
                regionCode: String = "US"
            ) {
                self.id = id
                self.name = name
                self.regionCode = regionCode
            }
        }
        
        @Model final class Artist {
            #Unique<Artist>([\.id])
            #Index<Artist>([\.name])
            
            @Attribute(.unique, .preserveValueOnDeletion) var id: String
            @Attribute(.preserveValueOnDeletion) var name: String
            @Attribute var socialHandle: String?
            
            init(
                id: String = UUID().uuidString,
                name: String,
                socialHandle: String? = nil
            ) {
                self.id = id
                self.name = name
                self.socialHandle = socialHandle
            }
        }
        
        @Model final class Album {
            #Unique<Album>([\.id], [\.title, \.year])
            #Index<Album>([\.year])
            
            @Attribute(.unique, .preserveValueOnDeletion) var id: String
            @Attribute var title: String
            @Attribute var year: Int
            @Attribute var genre: String
            @Attribute var isCompilation: Bool
            @Attribute(.externalStorage) var artworkData: Data?
            
            @Relationship(
                deleteRule: .nullify,
                minimumModelCount: 0,
                maximumModelCount: 1
            ) var artist: Artist?
            
            @Relationship
            var catalog: Catalog
            
            @Relationship(
                deleteRule: .cascade,
                minimumModelCount: 1,
                inverse: \Entity.AlbumTrack.album
            ) var trackLinks: [AlbumTrack] = []
            
            init(
                id: String = UUID().uuidString,
                title: String,
                year: Int,
                genre: String,
                isCompilation: Bool = false,
                artworkData: Data? = nil,
                artist: Artist? = nil,
                catalog: Catalog,
                trackLinks: [AlbumTrack] = []
            ) {
                self.id = id
                self.title = title
                self.year = year
                self.genre = genre
                self.isCompilation = isCompilation
                self.artworkData = artworkData
                self.artist = artist
                self.catalog = catalog
                self.trackLinks = trackLinks
            }
        }
        
        @Model final class Track {
            #Unique<Track>([\.id])
            #Index<Track>([\.title])
            
            @Attribute(.unique, .preserveValueOnDeletion) var id: String
            @Attribute var title: String
            @Attribute var durationSeconds: Int
            @Attribute var isExplicit: Bool
            
            @Relationship(
                deleteRule: .cascade,
                inverse: \Entity.AlbumTrack.track
            ) var albumLinks: [AlbumTrack] = []
            
            init(
                id: String = UUID().uuidString,
                title: String,
                durationSeconds: Int,
                isExplicit: Bool = false,
                albumLinks: [AlbumTrack] = []
            ) {
                self.id = id
                self.title = title
                self.durationSeconds = durationSeconds
                self.isExplicit = isExplicit
                self.albumLinks = albumLinks
            }
        }
        
        @Model final class AlbumTrack {
            #Index<AlbumTrack>([\.discNumber, \.trackNumber])
            
            @Attribute var discNumber: Int
            @Attribute var trackNumber: Int
            @Attribute var addedAt: Date
            
            @Relationship
            var album: Album
            
            @Relationship
            var track: Track
            
            init(
                discNumber: Int = 1,
                trackNumber: Int,
                addedAt: Date = .now,
                album: Album,
                track: Track
            ) {
                self.discNumber = discNumber
                self.trackNumber = trackNumber
                self.addedAt = addedAt
                self.album = album
                self.track = track
            }
        }
        
        @Model final class Playlist {
            #Unique<Playlist>([\.id])
            #Index<Playlist>([\.name])
            
            @Attribute(.unique, .preserveValueOnDeletion) var id: String
            @Attribute var name: String
            @Attribute var createdAt: Date
            @Attribute var isPinned: Bool
            
            @Relationship
            var catalog: Catalog
            
            @Relationship(
                deleteRule: .cascade,
                inverse: \Entity.PlaylistEntry.playlist
            ) var entries: [PlaylistEntry] = []
            
            init(
                id: String = UUID().uuidString,
                name: String,
                createdAt: Date = .now,
                isPinned: Bool = false,
                catalog: Catalog,
                entries: [PlaylistEntry] = []
            ) {
                self.id = id
                self.name = name
                self.createdAt = createdAt
                self.isPinned = isPinned
                self.catalog = catalog
                self.entries = entries
            }
        }
        
        @Model final class PlaylistEntry {
            #Index<PlaylistEntry>([\.position])
            @Attribute var position: Int
            @Attribute var addedAt: Date
            @Attribute var note: String?
            
            @Relationship
            var playlist: Playlist
            
            @Relationship
            var track: Track
            
            init(
                position: Int,
                addedAt: Date = .now,
                note: String? = nil,
                playlist: Playlist,
                track: Track
            ) {
                self.position = position
                self.addedAt = addedAt
                self.note = note
                self.playlist = playlist
                self.track = track
            }
        }
    }
}
