//
//  Graph.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import DataStoreKit
import SwiftData
import SwiftUI

@MainActor @Observable final class Graph: Sendable {
    private var roots: [PersistentIdentifier]
    nonisolated unowned let graph: ReferenceGraph
    var nodes: [PersistentIdentifier: Node] = [:]
    var edges: [Edge.Key: Edge] = [:]
    var plugins: GraphPlugins
    var configurations: GraphConfiguration
    var zoom: CGFloat = 1.0
    var offset: CGSize = .zero
    var selection: Set<PersistentIdentifier> = []
    var hovered: PersistentIdentifier? = nil
    var searchText: String = ""
    
    init(
        graph: ReferenceGraph,
        roots: [PersistentIdentifier],
        configurations: GraphConfiguration = .init(),
        plugins: GraphPlugins = .init()
    ) {
        self.graph = graph
        self.roots = roots
        self.configurations = configurations
        self.plugins = plugins
        rebuild()
    }
    
    func setRoots(_ newRoots: [PersistentIdentifier]) {
        self.roots = newRoots
        rebuild()
    }
    
    func rebuild() {
        var newNodes = [PersistentIdentifier: Node]()
        var newEdges = Set<Edge>()
        let frontier = Set<PersistentIdentifier>(roots)
        var seen = Set<PersistentIdentifier>()
        let includeOut = configurations.direction == .outgoing || configurations.direction == .both
        let includeIn  = configurations.direction == .incoming || configurations.direction == .both
        func ensureNode(_ identifier: PersistentIdentifier) {
            if newNodes[identifier] == nil {
                let pos = self.nodes[identifier]?.position ?? CGPoint(
                    x: Double.random(in: -200...200),
                    y: Double.random(in: -200...200)
                )
                newNodes[identifier] = Node(for: identifier, position: pos)
            }
        }
        if includeOut {
            var depth = 0
            var current = frontier
            while
                depth < configurations.depthOutgoing
                    && !current.isEmpty
                    && newNodes.count < configurations.maxNodes {
                var next = Set<PersistentIdentifier>()
                for owner in current {
                    ensureNode(owner)
                    let targets = self.graph.outgoing(from: owner, property: nil)
                    for target in targets {
                        ensureNode(target)
                        let incoming = self.graph.incoming(to: target).filter { $0.owner == owner }
                        for edge in incoming {
                            let graphEdge = Edge(
                                owner: owner,
                                property: edge.property,
                                target: target
                            )
                            newEdges.insert(graphEdge)
                        }
                        next.insert(target)
                    }
                    if newNodes.count >= configurations.maxNodes { break }
                }
                depth += 1
                current = next.subtracting(seen)
                seen.formUnion(current)
            }
        }
        if includeIn {
            var depth = 0
            var current: Set<PersistentIdentifier> = frontier
            while
                depth < configurations.depthIncoming
                    && !current.isEmpty
                    && newNodes.count < configurations.maxNodes {
                var next: Set<PersistentIdentifier> = []
                for target in current {
                    ensureNode(target)
                    let incoming = self.graph.incoming(to: target)
                    for edge in incoming {
                        ensureNode(edge.owner)
                        let graphEdge = Edge(
                            owner: edge.owner,
                            property: edge.property,
                            target: target
                        )
                        newEdges.insert(graphEdge)
                        next.insert(edge.owner)
                    }
                    if newNodes.count >= configurations.maxNodes { break }
                }
                depth += 1
                current = next.subtracting(seen)
                seen.formUnion(current)
            }
        }
        var degree = [PersistentIdentifier: Int]()
        for edge in newEdges {
            degree[edge.owner, default: 0] += 1
            degree[edge.target, default: 0] += 1
        }
        for (identifier, node) in newNodes {
            node.degree = degree[identifier, default: 0]
            newNodes[identifier] = node
        }
        for (identifier, oldNodes) in nodes {
            if let newNode = newNodes[identifier] {
                newNode.position = oldNodes.position
                newNode.velocity = oldNodes.velocity
                newNode.isFixed = oldNodes.isFixed
                newNodes[identifier] = newNode
            }
        }
        self.nodes = newNodes
        self.edges = Dictionary(uniqueKeysWithValues: newEdges.map { ($0.id, $0) })
    }
    
    func stepLayout(size: CGSize) {
        guard !nodes.isEmpty else { return }
        for _ in 0..<max(1, configurations.layoutStepsPerTick) {
            applyForces(size: size)
        }
    }
    
    private func applyForces(size: CGSize) {
        let springRestLength = self.configurations.springLength
        let springStiffness = self.configurations.springStiffness
        let repulsionStrength = self.configurations.repulsion
        let dampingRatio = self.configurations.damping
        let centerAttractionStrength = self.configurations.centerPull
        let identifiers = Array(nodes.keys)
        for index in 0..<identifiers.count {
            for j in (index+1)..<identifiers.count {
                let aIdentifier = identifiers[index], bIdentifier = identifiers[j]
                guard let a = self.nodes[aIdentifier],
                      let b = self.nodes[bIdentifier] else {
                    continue
                }
                let dx = b.position.x - a.position.x
                let dy = b.position.y - a.position.y
                let distanceSquared = max(dx*dx + dy*dy, 0.01)
                let inverseDistance = 1.0 / CGFloat(sqrt(distanceSquared))
                let force = repulsionStrength * inverseDistance * inverseDistance
                let fx = force * dx * inverseDistance
                let fy = force * dy * inverseDistance
                if !a.isFixed { a.velocity.x -= fx; a.velocity.y -= fy }
                if !b.isFixed { b.velocity.x += fx; b.velocity.y += fy }
                self.nodes[aIdentifier] = a
                self.nodes[bIdentifier] = b
            }
        }
        for edge in edges.values {
            guard let a = self.nodes[edge.owner],
                  let b = self.nodes[edge.target] else {
                continue
            }
            let dx = b.position.x - a.position.x
            let dy = b.position.y - a.position.y
            let distance = max(0.001, hypot(dx, dy))
            let delta = distance - springRestLength
            let force = springStiffness * delta
            let fx = force * (dx / distance)
            let fy = force * (dy / distance)
            if !a.isFixed { a.velocity.x += fx; a.velocity.y += fy }
            if !b.isFixed { b.velocity.x -= fx; b.velocity.y -= fy }
            self.nodes[edge.owner] = a
            self.nodes[edge.target] = b
        }
        let center = CGPoint(x: 0, y: 0)
        for (identifier, node) in nodes {
            if !node.isFixed {
                node.velocity.x += (center.x - node.position.x) * centerAttractionStrength
                node.velocity.y += (center.y - node.position.y) * centerAttractionStrength
                node.position.x += node.velocity.x * 0.016
                node.position.y += node.velocity.y * 0.016
                node.velocity.x *= dampingRatio
                node.velocity.y *= dampingRatio
            }
            self.nodes[identifier] = node
        }
    }
    
    func toggleSelection(_ identifier: PersistentIdentifier) {
        if selection.contains(identifier) {
            selection.remove(identifier)
        } else {
            selection.insert(identifier)
        }
    }
    
    func isHighlighted(_ identifier: PersistentIdentifier) -> Bool {
        if selection.isEmpty {
            return false
        }
        if selection.contains(identifier) {
            return true
        }
        for edge in edges.values {
            if selection.contains(edge.owner) && edge.target == identifier {
                return true
            }
            if selection.contains(edge.target) && edge.owner == identifier {
                return true
            }
        }
        return false
    }
    
    func neighbors(of identifier: PersistentIdentifier) -> Set<PersistentIdentifier> {
        var identifiers = Set<PersistentIdentifier>()
        for edge in edges.values {
            if edge.owner == identifier { identifiers.insert(edge.target) }
            if edge.target == identifier { identifiers.insert(edge.owner) }
        }
        return identifiers
    }
    
    func worldToScreen(_ point: CGPoint, in size: CGSize) -> CGPoint {
        .init(
            x: point.x * zoom + size.width/2 + offset.width,
            y: point.y * zoom + size.height/2 + offset.height
        )
    }
    
    func screenToWorld(_ point: CGPoint, in size: CGSize) -> CGPoint {
        .init(
            x: (point.x - size.width/2 - offset.width) / zoom,
            y: (point.y - size.height/2 - offset.height) / zoom
        )
    }
}

struct GraphContextAction: Identifiable {
    let id: UUID = .init()
    let title: String
    let systemImage: String?
    let action: () -> Void
    
    init(_ title: String, systemImage: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }
}

@MainActor struct GraphPlugins {
    var label: any GraphLabelProvider
    var style: any GraphStyleProvider
    var interaction: any GraphInteractionProvider
    
    nonisolated init(
        label: any GraphLabelProvider = DefaultGraphLabel(),
        style: any GraphStyleProvider = DefaultGraphStyle(),
        interaction: any GraphInteractionProvider = DefaultGraphInteraction()
    ) {
        self.label = label
        self.style = style
        self.interaction = interaction
    }
}

enum GraphExploreDirection: Sendable {
    case outgoing, incoming, both
}

struct GraphConfiguration: Sendable {
    var depthOutgoing: Int = 1
    var depthIncoming: Int = 0
    var direction: GraphExploreDirection = .both
    var maxNodes: Int = 600
    var springLength: CGFloat = 180
    var springStiffness: CGFloat = 0.045
    var repulsion: CGFloat = 9500
    var damping: CGFloat = 0.85
    var centerPull: CGFloat = 0.02
    var layoutStepsPerTick: Int = 1
    var labelEdgeThreshold: CGFloat = 36
    
    init() {}
    
    init(
        depthOutgoing: Int,
        depthIncoming: Int,
        direction: GraphExploreDirection = .both
    ) {
        self.depthOutgoing = depthOutgoing
        self.depthIncoming = depthIncoming
        self.direction = direction
    }
}
