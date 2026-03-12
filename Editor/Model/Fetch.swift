//
//  Fetch.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import DataStoreKit
import DataStoreSQL
import DataStoreSupport
import Logging

nonisolated func fetch(_ configuration: DatabaseConfiguration) -> [(
    table: String,
    rows: [[String: any Sendable]]
)] {
    var result = [(String, [[String: any Sendable]])]()
    do {
        try configuration.store?.queue.reader { connection in
            let tables = try connection.fetch(
                """
                SELECT name FROM sqlite_schema
                WHERE type = 'table' AND name NOT LIKE 'sqlite_%';
                """
            )
            for table in tables {
                guard let name = table[0] as? String else {
                    fatalError()
                }
                let sql: String
                if name == "_History" {
                    sql = """
                        SELECT rowid, * FROM "\(name)"
                        ORDER BY "timestamp" DESC
                        """
//                    LIMIT 10;
                } else {
                    sql = """
                        SELECT rowid, * FROM "\(name)"
                        ORDER BY rowid ASC
                        LIMIT 50;
                        """
                }
                let rows = try connection.query(sql)
                result.append((name, rows))
            }
        }
    } catch {
        logger.error("Error: \(error)")
    }
    return result
}
