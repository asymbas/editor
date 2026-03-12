//
//  ResultBuilderView.swift
//  DataStoreKit
//
//  Copyright 2025 Asymbas and Anferne Pineda.
//  Licensed under the Apache License, Version 2.0 (see LICENSE file).
//  SPDX-License-Identifier: Apache-2.0
//

import DataStoreSQL
import SQLiteHandle
import SQLiteStatement
import SwiftUI

struct ResultBuilderView: View {
    @SQLBuilder private var sql: [any SQLFragment] {
        SQL {
            ""
//            _Select()
//            _From("Main \(as: "alias")")
//            _Join("Table") { table in
//                ("alias" as _SQLTable).column("pk") == table.column("pk")
//            }
        }.sql
    }
    
    var body: some View {
        EmptyView()
    }
}
