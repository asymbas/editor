# Editor

A companion application for [DataStoreKit](https://github.com/asymbas/datastorekit) that serves as both a demonstration of its features and a development tool for working with SwiftData databases.

## Overview

DataStoreKit is developed in Swift Playground. As it matures, Editor is intended to grow into a standalone tool for managing and inspecting DataStoreKit databases.

Editor showcases SwiftData functioning with a custom store and DataStoreKit's extended features. It provides interactive views for inspecting models, testing predicates, visualizing fetch behavior, exploring reference graphs, and working with a database schema.

## Requirements

Downloading as an Xcode project for macOS requires:
- Xcode 26.0+
- Swift 6.2+

Downloading as a Swift Playground package for iPadOS requires:
- iOS 18.2+
- Swift 6.0.2+

## Dependencies

- [DataStoreKit](https://github.com/asymbas/datastorekit)
- [swift-async-algorithms](https://github.com/apple/swift-async-algorithms)
- [swift-collections](https://github.com/apple/swift-collections)
- [swift-log](https://github.com/apple/swift-log)

## Getting Started

Clone the repository and open the Xcode project.
```bash
git clone https://github.com/asymbas/editor.git
```

### Configurator

<table>
<tr>
<td><img src="https://www.asymbas.com/assets/datastorekit/configurator.png" alt="Configurator" width="300"></td>
</tr>
</table>

### Editor

<table>
<tr>
<td><img src="https://www.asymbas.com/assets/datastorekit/editor.png" alt="Editor" width="300"></td>
</tr>
</table>

### Overview

- Tap on a table to expand the group box.
- Tap on a primary key of an entity to present a movable-floating panel that lists out the model's properties with editable fields.

<table>
<tr>
<td><img src="https://www.asymbas.com/assets/datastorekit/overview-iphone-light.png" alt="Overview iPhone Light" width="300"></td>
<td><img src="https://www.asymbas.com/assets/datastorekit/overview-iphone-dark.png" alt="Overview iPhone Dark" width="300"></td>
</tr>
<tr>
<td><img src="https://www.asymbas.com/assets/datastorekit/overview-iphone-panel-light.png" alt="Overview iPhone Panel Light" width="300"></td>
<td><img src="https://www.asymbas.com/assets/datastorekit/overview-iphone-panel-light-offset.png" alt="Overview iPhone Panel Light Offset" width="300"></td>
</tr>
<tr>
<td><img src="https://www.asymbas.com/assets/datastorekit/overview-ipad-light.png" alt="Overview iPad Light" width="300"></td>
<td><img src="https://www.asymbas.com/assets/datastorekit/overview-ipad-dark.png" alt="Overview iPad Dark" width="300"></td>
</tr>
<tr>
<td><img src="https://www.asymbas.com/assets/datastorekit/overview-ipad-panel-light.png" alt="Overview iPad Panel Light" width="300"></td>
<td><img src="https://www.asymbas.com/assets/datastorekit/overview-ipad-panel-light-offset.png" alt="Overview iPad Panel Light Offset" width="300"></td>
</tr>
</table>

### Foreign Key Error

- Receive alerts whenever a foreign key (red) or unique (yellow) constraint violations.

<table>
<tr>
<td><img src="https://www.asymbas.com/assets/datastorekit/foreign-key-error.png" alt="Foreign Key Error" width="300"></td>
<td><img src="https://www.asymbas.com/assets/datastorekit/foreign-key-error-popover.png" alt="Foreign Key Error Popover" width="300"></td>
</tr>
</table>

### Console

- Filter logs.
- Additional options in the menu button:
- Select a minimum log level.
- Filter by log level.
- Filter by source to narrow down logs per module.
- Filter by file.
- Multi-select filter by label that is based on domains.
- Set view options to make logs more compact or make metadata use inline.

<table>
<tr>
<td><img src="https://www.asymbas.com/assets/datastorekit/console-view-light.png" alt="Console Light" width="300"></td>
<td><img src="https://www.asymbas.com/assets/datastorekit/console-view-dark.png" alt="Console Dark" width="300"></td>
</tr>
</table>

### Predicate Tree

- Execute `FetchDescriptor` or `Predicate` in fetch requests to view how predicate expressions are evaluated into SQL expressions.

<table>
<tr>
<td><img src="https://www.asymbas.com/assets/datastorekit/predicate-tree-light.png" alt="Predicate Tree Light" width="300"></td>
<td><img src="https://www.asymbas.com/assets/datastorekit/predicate-tree-dark.png" alt="Predicate Tree Dark" width="300"></td>
</tr>
</table>

### Predicate Test

<table>
<tr>
<td><img src="https://www.asymbas.com/assets/datastorekit/predicate-test-light.png" alt="Predicate Test Light" width="300"></td>
<td><img src="https://www.asymbas.com/assets/datastorekit/predicate-test-dark.png" alt="Predicate Test Dark" width="300"></td>
</tr>
</table>

### Reference Graph

- View what's inside the foreign key / related identifier caching system.

<table>
<tr>
<td><img src="https://www.asymbas.com/assets/datastorekit/reference-graph-iphone-light.png" alt="Reference Graph iPhone Light" width="300"></td>
<td><img src="https://www.asymbas.com/assets/datastorekit/reference-graph-iphone-dark.png" alt="Reference Graph iPhone Dark" width="300"></td>
</tr>
<tr>
<td><img src="https://www.asymbas.com/assets/datastorekit/reference-graph-ipad-light.png" alt="Reference Graph iPad Light" width="300"></td>
<td><img src="https://www.asymbas.com/assets/datastorekit/reference-graph-ipad-dark.png" alt="Reference Graph iPad Dark" width="300"></td>
</tr>
</table>

### Graph Test

<table>
<tr>
<td><img src="https://www.asymbas.com/assets/datastorekit/graph-text-0.png" alt="Graph Test 0" width="300"></td>
<td><img src="https://www.asymbas.com/assets/datastorekit/graph-text-1.png" alt="Graph Test 1" width="300"></td>
</tr>
</table>

### SQL Print

- Convenience SQL formatting of tables (for server use).

<table>
<tr>
<td><img src="https://www.asymbas.com/assets/datastorekit/sql-print-0.png" alt="SQL Print 0" width="300"></td>
<td><img src="https://www.asymbas.com/assets/datastorekit/sql-print-1.png" alt="SQL Print 1" width="300"></td>
</tr>
</table>

## Contributing

This project is not accepting contributions at this time.

## License

This project is licensed under the **Apache 2.0** License. See [LICENSE](LICENSE).
