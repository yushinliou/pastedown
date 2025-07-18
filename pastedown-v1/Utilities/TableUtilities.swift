//
//  TableUtilities.swift
//  pastedown-v1
//
//  Created by AI Assistant on 2025/6/30.
//

import SwiftUI
import Foundation
import UIKit

// MARK: - Table Data Structures
struct TableCell {
    let content: String
    let row: Int
    let column: Int
    let blockID: String?
    let range: NSRange
}

struct TableStructure {
    let rows: Int
    let columns: Int
    let cellPositions: [(row: Int, column: Int)] // Ordered list of cell positions
}

struct TableInfo {
    let structure: TableStructure
    let cells: [TableCell] // Direct storage of cells with content, range, and blockID
    let firstCellNSTableBlockID: String? // Optional NSTextTableBlock ID for the first cell, if available
    let firstCellRange: NSRange
    
    var rows: Int { structure.rows }
    var columns: Int { structure.columns }
}

struct TableDetectionResult {
    let tables: [TableInfo]
    let attributedStringWithTables: NSMutableAttributedString
}

// MARK: - RTF Table Structure Parser
class RTFTableStructureParser {


    func extractTableStructures(from rtfString: String) -> [TableStructure] {
        
        var structures: [TableStructure] = []
        
        // Method 1: Look for complete tables with proper Apple RTF format
        // Pattern: \itap1\trowd ... \lastrow\row
        let appleTablePattern = #"\\itap1\\trowd[\s\S]*?\\lastrow\\row"#
        if let appleTableRegex = try? NSRegularExpression(pattern: appleTablePattern),
           !appleTableRegex.matches(in: rtfString, range: NSRange(rtfString.startIndex..., in: rtfString)).isEmpty {
            
            let matches = appleTableRegex.matches(in: rtfString, range: NSRange(rtfString.startIndex..., in: rtfString))
            for match in matches {
                guard let range = Range(match.range, in: rtfString) else { continue }
                let tableBlock = String(rtfString[range])
                if let structure = parseAppleRTFTableStructure(from: tableBlock, range: match.range) {
                    structures.append(structure)
                }
            }
        }
        
        // Method 2: Fallback - look for simpler table patterns
        if structures.isEmpty {

            let simpleTablePattern = #"\\trowd[\s\S]*?\\row"#
            if let simpleRegex = try? NSRegularExpression(pattern: simpleTablePattern) {
                let matches = simpleRegex.matches(in: rtfString, range: NSRange(rtfString.startIndex..., in: rtfString))
                if matches.count > 0 {
                    structures = groupConsecutiveTableRowStructures(rtfString)
                }
            }
        }
        
        return structures
    }


    // MARK: - Apple RTF Table Structure Parser
    private func parseAppleRTFTableStructure(from tableBlock: String, range: NSRange) -> TableStructure? {

        // Extract column information from \cellx definitions
        let columnPattern = #"\\cellx(\d+)"#
        guard let columnRegex = try? NSRegularExpression(pattern: columnPattern) else { return nil }
        
        let columnMatches = columnRegex.matches(in: tableBlock, range: NSRange(tableBlock.startIndex..., in: tableBlock))
        
        // Find unique cellx values to determine column count (may be repeated per row)
        var cellxValues: Set<Int> = []
        for match in columnMatches {
            if let cellxRange = Range(match.range(at: 1), in: tableBlock),
               let cellxValue = Int(String(tableBlock[cellxRange])) {
                cellxValues.insert(cellxValue)
            }
        }
        
        let columns = cellxValues.count
        
        // Count rows by looking for \row markers
        let rowPattern = #"\\(lastrow\\)?row"#
        guard let rowRegex = try? NSRegularExpression(pattern: rowPattern) else { return nil }
        
        let rowMatches = rowRegex.matches(in: tableBlock, range: NSRange(tableBlock.startIndex..., in: tableBlock))
        let rows = rowMatches.count
        
        // Validate we have a meaningful table
        guard rows > 0 && columns > 0 else {
            return nil
        }
        
        // Generate cell positions
        var cellPositions: [(row: Int, column: Int)] = []
        for rowIndex in 0..<rows {
            for columnIndex in 0..<columns {
                cellPositions.append((row: rowIndex, column: columnIndex))
            }
        }
        
        
        return TableStructure(
            rows: rows,
            columns: columns,
            cellPositions: cellPositions
        )
    }
    
    
private func groupConsecutiveTableRowStructures(_ rtfString: String) -> [TableStructure] {
    var structures: [TableStructure] = []
    
    let rowPattern = #"\\trowd[\s\S]*?\\row"#
    guard let rowRegex = try? NSRegularExpression(pattern: rowPattern) else { return [] }
    
    let rowMatches = rowRegex.matches(in: rtfString, range: NSRange(rtfString.startIndex..., in: rtfString))
    
    var currentRows: [String] = []
    var groupStart: Int? = nil
    var lastRowEnd: Int = 0
    
    for match in rowMatches {
        let matchStart = match.range.location
        let matchEnd = match.range.location + match.range.length
        
        let gap = matchStart - lastRowEnd
        
        guard let range = Range(match.range, in: rtfString) else { continue }
        let rowBlock = String(rtfString[range])
        
        if gap < 100 && !currentRows.isEmpty {
            currentRows.append(rowBlock)
        } else {
            // finish previous row
            if let start = groupStart, !currentRows.isEmpty,
               let structure = createStructureFromRows(currentRows, nsRange: NSRange(location: start, length: lastRowEnd - start)) {
                structures.append(structure)
            }
            // new row
            currentRows = [rowBlock]
            groupStart = matchStart
        }
        
        lastRowEnd = matchEnd
    }
    
    // finish last row
    if let start = groupStart, !currentRows.isEmpty,
       let structure = createStructureFromRows(currentRows, nsRange: NSRange(location: start, length: lastRowEnd - start)) {
        structures.append(structure)
    }
    
    return structures
}


    private func createStructureFromRows(_ rows: [String], nsRange: NSRange) -> TableStructure? {
        var cellPositions: [(row: Int, column: Int)] = []
        var maxColumns = 0
        
        for (rowIndex, rowBlock) in rows.enumerated() {
            let cellCount = countCellsInRow(rowBlock)
            maxColumns = max(maxColumns, cellCount)
            
            for columnIndex in 0..<cellCount {
                cellPositions.append((row: rowIndex, column: columnIndex))
            }
        }
        
        guard !cellPositions.isEmpty else { return nil }
        
        return TableStructure(
            rows: rows.count,
            columns: maxColumns,
            cellPositions: cellPositions
        )
    }
    
    private func countCellsInRow(_ rowBlock: String) -> Int {
        // Count \cell markers to determine number of cells
        let cellMatches = rowBlock.components(separatedBy: "\\cell")
        return max(0, cellMatches.count - 1) // -1 because split creates n+1 components for n separators
    }
}

// MARK: - Content Extractor from NSAttributedString  
class AttributedStringTableContentExtractor {
    
    func extractTableCells(from attributedString: NSAttributedString, structure: TableStructure) -> [TableCell] {
        let extractedCells = extractTableCellsWithDetails(from: attributedString)
        var cells: [TableCell] = []
        
        // Map extracted cells to table structure positions
        for (index, position) in structure.cellPositions.enumerated() {
            if index < extractedCells.count {
                let extractedCell = extractedCells[index]
                let cell = TableCell(
                    content: extractedCell.content,
                    row: position.row,
                    column: position.column,
                    blockID: extractedCell.blockID,
                    range: extractedCell.range
                )
                cells.append(cell)
            } else {
                // Pad with empty cells if structure expects more cells
                let cell = TableCell(
                    content: "",
                    row: position.row,
                    column: position.column,
                    blockID: nil,
                    range: NSRange(location: 0, length: 0)
                )
                cells.append(cell)
            }
        }
        
        return cells
    }

    func extractTableCellsWithDetails(from attributedString: NSAttributedString) -> [(content: String, blockID: String?, range: NSRange)] {
        var cells: [(content: String, blockID: String?, range: NSRange)] = []
        var currentBlockID: String? = nil
        var buffer = NSMutableAttributedString()
        var currentRange = NSRange(location: 0, length: 0)
        
        attributedString.enumerateAttributes(in: NSRange(location: 0, length: attributedString.length)) { attrs, range, _ in
            
            guard let paragraphStyle = attrs[.paragraphStyle] as? NSParagraphStyle else {
                if buffer.length > 0 {
                    let content = convertCellTextWithFormatting(buffer)
                    cells.append((content: content, blockID: currentBlockID, range: currentRange))
                    buffer = NSMutableAttributedString()
                    currentBlockID = nil
                }
                return
            }

            let description = paragraphStyle.description
            let blockID = extractNSTextTableBlockID(from: description)
            
            if let blockID = blockID {
                if currentBlockID != nil && currentBlockID != blockID {
                    // Save previous cell
                    let content = convertCellTextWithFormatting(buffer)
                    cells.append((content: content, blockID: currentBlockID, range: currentRange))
                    buffer = NSMutableAttributedString()
                }
                
                // Start new cell or continue current one
                if currentBlockID != blockID {
                    currentBlockID = blockID
                    currentRange = range
                } else {
                    // Extend the range for the current cell
                    currentRange = NSRange(
                        location: currentRange.location,
                        length: range.location + range.length - currentRange.location
                    )
                }
                
                let substring = attributedString.attributedSubstring(from: range)
                buffer.append(substring)
            } else {
                if buffer.length > 0 {
                    let content = convertCellTextWithFormatting(buffer)
                    cells.append((content: content, blockID: currentBlockID, range: currentRange))
                    buffer = NSMutableAttributedString()
                    currentBlockID = nil
                }
            }
        }
        
        // Handle any remaining buffer
        if buffer.length > 0 {
            let content = convertCellTextWithFormatting(buffer)
            cells.append((content: content, blockID: currentBlockID, range: currentRange))
        }
        
        return cells
    }
    
    private func extractNSTextTableBlockID(from description: String) -> String? {
        // get pattern "<NSTextTableBlock: 0x60000265efa0>"
        let pattern = "<NSTextTableBlock:\\s*([^>]+)>"
        if let match = description.range(of: pattern, options: .regularExpression) {
            return String(description[match])
        }
        return nil
    }
    
    // New method to extract first cell NSTextTableBlock ID for each table
    func extractFirstCellTableBlockIDs(from attributedString: NSAttributedString) -> [String] {
        var firstCellIDs: [String] = []
        var seenBlockIDs: Set<String> = []
        
        attributedString.enumerateAttribute(.paragraphStyle, in: NSRange(location: 0, length: attributedString.length), options: []) { value, range, _ in
            guard let paragraphStyle = value as? NSParagraphStyle else { return }
            
            let description = paragraphStyle.description
            if let blockID = extractNSTextTableBlockID(from: description) {
                if !seenBlockIDs.contains(blockID) {
                    seenBlockIDs.insert(blockID)
                    firstCellIDs.append(blockID)
                }
            }
        }
        
        return firstCellIDs
    }

    // private func extractNSTextTableBlockID(from description: String) -> String? {
    //     // get pattern "<NSTextTableBlock: 0x60000265efa0>"
    //     let pattern = "<NSTextTableBlock:\\s*([^>]+)>"
    //     if let match = description.range(of: pattern, options: .regularExpression) {
    //         return String(description[match])
    //     }
    //     return nil
    // }
    

    private func convertCellTextWithFormatting(_ attributedString: NSAttributedString) -> String {
        var result = ""
        
        attributedString.enumerateAttributes(in: NSRange(location: 0, length: attributedString.length), options: []) { attrs, range, _ in
            let substring = attributedString.attributedSubstring(from: range).string
            
            // Apply formatting similar to how it's done in RichTextProcessor
            var formattedText = substring
            formattedText = MarkdownUtilities.handleLinks(formattedText, attributes: attrs)
            formattedText = MarkdownUtilities.applyTextFormatting(formattedText, attributes: attrs)
            
            result += formattedText
        }
        
        return result
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: "<br>")
    }
}

// MARK: - Table Utilities
struct TableUtilities {
    
    static let structureParser = RTFTableStructureParser()
    static let contentExtractor = AttributedStringTableContentExtractor()
    
    // MARK: - Direct Table Insertion with NSTextTableBlock ID
    static func detectTablesWithDirectInsertion(in attributedString: NSAttributedString, rawRTF: String?) -> TableDetectionResult {
        var detectedTables: [TableInfo] = []
        let mutableAttributedString = NSMutableAttributedString(attributedString: attributedString)
        
        if let rawRTF = rawRTF {
            // Extract structure from RTF, content from NSAttributedString
            detectedTables = detectTablesWithSeparatedApproach(rawRTF: rawRTF, attributedString: attributedString)
        }
        
        // Insert markdown tables directly into the attributed string
        insertMarkdownTablesDirectly(for: detectedTables, in: mutableAttributedString)
        
        return TableDetectionResult(tables: detectedTables, attributedStringWithTables: mutableAttributedString)
    }

    private static func findFirstCellRange(for blockID: String?, in attributedString: NSAttributedString) -> NSRange {
        print("[findFirstCellRange] \(attributedString.string)")
        guard let blockID = blockID else { return NSRange(location: 0, length: 0) }

        var firstCellRange = NSRange(location: 0, length: 0)

        attributedString.enumerateAttribute(.paragraphStyle, in: NSRange(location: 0, length: attributedString.length), options: []) { value, range, stop in
            guard let paragraphStyle = value as? NSParagraphStyle else { return }

            let description = paragraphStyle.description
            if let foundBlockID = extractNSTextTableBlockID(from: description),
            foundBlockID == blockID {
                firstCellRange = range
                stop.pointee = true
                print("firstCellRange: \(firstCellRange)")
                print("attributedString: \(attributedString.attributedSubstring(from: range).string)")
            }
        }
    
    return firstCellRange
    }

    // MARK: - New Separated Approach
    private static func detectTablesWithSeparatedApproach(rawRTF: String, attributedString: NSAttributedString) -> [TableInfo] {
        // Step 1: Extract table structures from raw RTF
        let structures = structureParser.extractTableStructures(from: rawRTF)
        
        // Step 2: Extract first cell NSTextTableBlock IDs
        let firstCellBlockIDs = contentExtractor.extractFirstCellTableBlockIDs(from: attributedString)
        
        // Step 3: Extract all table cells with their content, range, and blockID
        let cellExtractor = AttributedStringTableContentExtractor()
        let allExtractedCells = cellExtractor.extractTableCellsWithDetails(from: attributedString)
        
        // Step 4: Create tables by grouping cells based on structure
        var tables: [TableInfo] = []
        var cellIndex = 0
        
        for (index, structure) in structures.enumerated() {
            let cellCount = structure.cellPositions.count
            let endIndex = min(cellIndex + cellCount, allExtractedCells.count)
            
            // Extract cells for this specific table
            var tableCells: [TableCell] = []
            
            for (positionIndex, position) in structure.cellPositions.enumerated() {
                let extractedIndex = cellIndex + positionIndex
                
                if extractedIndex < allExtractedCells.count {
                    let extractedCell = allExtractedCells[extractedIndex]
                    let cell = TableCell(
                        content: extractedCell.content,
                        row: position.row,
                        column: position.column,
                        blockID: extractedCell.blockID,
                        range: extractedCell.range
                    )
                    tableCells.append(cell)
                } else {
                    // Pad with empty cells if we don't have enough extracted cells
                    let cell = TableCell(
                        content: "",
                        row: position.row,
                        column: position.column,
                        blockID: nil,
                        range: NSRange(location: 0, length: 0)
                    )
                    tableCells.append(cell)
                }
            }
            
            // Get the first cell NSTextTableBlock ID for this table
            let firstCellBlockID = index < firstCellBlockIDs.count ? firstCellBlockIDs[index] : nil
            let firstCellRange = findFirstCellRange(for: firstCellBlockID, in: attributedString)
            
            print("[table \(index)] cells: \(tableCells.count)")
            for cell in tableCells {
                print("  Cell(\(cell.row),\(cell.column)): '\(cell.content)' blockID: \(cell.blockID ?? "nil") range: \(cell.range)")
            }

            let tableInfo = TableInfo(
                structure: structure,
                cells: tableCells,
                firstCellNSTableBlockID: firstCellBlockID,
                firstCellRange: firstCellRange
            )
            
            tables.append(tableInfo)
            
            // Move to next table's cells
            cellIndex = endIndex
        }
        
        return tables
    }
    
    // MARK: - Markdown Conversion - Updated for new structure
    static func convertTableToMarkdown(_ table: TableInfo) -> String {
        guard table.rows > 0 && table.columns > 0 else {
            return ""
        }
        
        // Create a 2D array to organize the cells
        var grid: [[String]] = Array(repeating: Array(repeating: "", count: table.columns), count: table.rows)
        
        // Fill the grid using the cells with their content, range, and blockID
        for cell in table.cells {
            if cell.row < table.rows && cell.column < table.columns {
                grid[cell.row][cell.column] = cell.content.isEmpty ? " " : cell.content
            }
        }
        
        var markdown = ""
        
        // Add header row (first row)
        if table.rows > 0 {
            markdown += "| " + grid[0].joined(separator: " | ") + " |\n"
            
            // Add separator row
            markdown += "|" + String(repeating: "---|", count: table.columns) + "\n"
            
            // Add data rows (skip first row which we used as header)
            for rowIndex in 1..<table.rows {
                markdown += "| " + grid[rowIndex].joined(separator: " | ") + " |\n"
            }
        }
        return markdown
    }


// MARK: - Helper Functions
private static func estimatePositionFromTableIndex(_ index: Int, in attributedString: NSAttributedString) -> Int {
    // Find actual table content in the attributed string to get more accurate position
    let string = attributedString.string
    var tableBlockRanges: [NSRange] = []
    
    // Look for table blocks in the attributed string
    attributedString.enumerateAttribute(.paragraphStyle, in: NSRange(location: 0, length: attributedString.length), options: []) { value, range, _ in
        if let paragraphStyle = value as? NSParagraphStyle,
           paragraphStyle.description.contains("NSTextTableBlock") {
            tableBlockRanges.append(range)
        }
    }
    
    // Sort ranges by location
    tableBlockRanges.sort { $0.location < $1.location }
    
    // Return the actual position if we have enough table blocks
    if index < tableBlockRanges.count {
        return tableBlockRanges[index].location
    }
    
    // Fallback: distribute remaining tables after the last known table
    let lastKnownPosition = tableBlockRanges.last?.location ?? 0
    let remainingLength = attributedString.length - lastKnownPosition
    let tablesAfterKnown = index - tableBlockRanges.count + 1
    let spacing = tablesAfterKnown > 1 ? remainingLength / tablesAfterKnown : remainingLength
    
    return lastKnownPosition + (spacing * (index - tableBlockRanges.count + 1))
}

// MARK: - Direct markdown table insertion based on NSTextTableBlock ID
// private static func insertMarkdownTablesDirectly(for tables: [TableInfo], in mutableAttributedString: NSMutableAttributedString) {
//     // Create a mapping of table block IDs to tables
//     var tableBlockIDToTable: [String: TableInfo] = [:]
//     for table in tables {
//         if let blockID = table.firstCellNSTableBlockID {
//             tableBlockIDToTable[blockID] = table
//         }
//     }
    
//     // Track processed tables and collect insertion points
//     var processedTables: Set<String> = []
//     var insertions: [(position: Int, table: TableInfo)] = []
    
//     // Iterate through the attributed string to find table blocks
//     mutableAttributedString.enumerateAttribute(.paragraphStyle, in: NSRange(location: 0, length: mutableAttributedString.length), options: []) { value, range, _ in
//         let substring = mutableAttributedString.attributedSubstring(from: range).string
//         print("───")
//         print("[substring] \(substring)")
//         print("[range] \(range)")
//         print("[has style] \(value != nil)")
//         guard let paragraphStyle = value as? NSParagraphStyle else { return }
        
//         let description = paragraphStyle.description
//         if let blockID = extractNSTextTableBlockID(from: description),
//            let table = tableBlockIDToTable[blockID] {
            
//             // Use a unique identifier for the table to avoid processing the same table multiple times
//             let tableIdentifier = table.firstCellNSTableBlockID ?? UUID().uuidString
//             // print char in location
//             let currentString = mutableAttributedString.attributedSubstring(from: range).string
//             print("[currentString] \(currentString)")
//             print("[blockID] \(blockID)")
//             print("[range] \(range)")
//             print("[range.location] \(range.location)")

//             if !processedTables.contains(tableIdentifier) {
//                 // Found a matching table block ID, record the insertion position
//                 insertions.append((position: range.location, table: table))
//                 print("[range \(range.location) to table \(table)")
//                 processedTables.insert(tableIdentifier)
//             }
//         }
//     }
    
//     // Sort insertions by position in reverse order to maintain indices when replacing
//     insertions.sort { $0.position > $1.position }
    
//     // Remove all existing table blocks first
//     removeTableBlocks(from: mutableAttributedString)
    
//     // Insert markdown tables at the recorded positions
//     for insertion in insertions {
//         let adjustedPosition = min(insertion.position, mutableAttributedString.length)
//         print("[adjust Pos] \(adjustedPosition)")
//         print("min(\(insertion.position)), \(mutableAttributedString.length)")
//         let markdownTable = convertTableToMarkdown(insertion.table)
//         let tableAttributedString = NSAttributedString(string: "\n\(markdownTable)\n")
//         mutableAttributedString.insert(tableAttributedString, at: adjustedPosition)
//         print("[table after insert] \(mutableAttributedString.string)")
//     }
// }

private static func insertMarkdownTablesDirectly(for tables: [TableInfo], in mutableAttributedString: NSMutableAttributedString) {
    // Sort tables by their first cell location in reverse order to maintain indices when replacing
    let sortedTables = tables.sorted { $0.firstCellRange.location > $1.firstCellRange.location }
    
    // Debug: Print table cells info
    for table in sortedTables {
        print("[Table cells count: \(table.cells.count)]")
        for cell in table.cells {
            print("  Cell(\(cell.row),\(cell.column)): '\(cell.content)' blockID: \(cell.blockID ?? "nil") range: \(cell.range)")
        }
    }
    print("========start insert========")
    // Insert markdown tables at the recorded positions
    for table in sortedTables {
        let adjustedPosition = min(table.firstCellRange.location, mutableAttributedString.length)
        if let firstCell = table.cells.first{
            print("[firstCell: Content=\(firstCell.content), BlockID=\(firstCell.blockID), Range=\(firstCell.range)]")
            print("[before insert]")
            print("\(mutableAttributedString.string)")
            print("[insert in \(adjustedPosition)=max(\(table.firstCellRange.location), \(mutableAttributedString.length))]")
            let markdownTable = convertTableToMarkdown(table)
            let tableAttributedString = NSAttributedString(string: "\n\(markdownTable)\n")
            mutableAttributedString.insert(tableAttributedString, at: firstCell.range.location)
            print("[after insert]")
            print("\(mutableAttributedString.string)")
            print("---")
        }
        
    }
    // Remove all existing table blocks first
    removeTableBlocks(from: mutableAttributedString)
}

private static func extractNSTextTableBlockID(from description: String) -> String? {
    // get pattern "<NSTextTableBlock: 0x60000265efa0>"
    let pattern = "<NSTextTableBlock:\\s*([^>]+)>"
    if let match = description.range(of: pattern, options: .regularExpression) {
        return String(description[match])
    }
    return nil
}

private static func removeTableBlocks(from mutableAttributedString: NSMutableAttributedString) {
    // Remove all NSTextTableBlock content from the attributed string
    var tableBlockRanges: [NSRange] = []
    
    mutableAttributedString.enumerateAttribute(.paragraphStyle, in: NSRange(location: 0, length: mutableAttributedString.length), options: []) { value, range, _ in
        if let paragraphStyle = value as? NSParagraphStyle,
           paragraphStyle.description.contains("NSTextTableBlock") {
            tableBlockRanges.append(range)
        }
    }
    
    // Sort ranges by location in reverse order to maintain indices
    tableBlockRanges.sort { $0.location > $1.location }
    
    // Remove table blocks
    for range in tableBlockRanges {
        mutableAttributedString.deleteCharacters(in: range)
    }
}

// MARK: - Legacy method for backward compatibility
static func replacePlaceholdersWithMarkdown(_ markdown: String, tables: [TableInfo]) -> String {
    // This method is now deprecated since we insert markdown directly
    // Keep it for backward compatibility if needed
    return markdown
}

}