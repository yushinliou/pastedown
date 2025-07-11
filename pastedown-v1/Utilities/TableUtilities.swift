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
}

struct TableStructure {
    let rows: Int
    let columns: Int
    let cellPositions: [(row: Int, column: Int)] // Ordered list of cell positions
}

struct TableInfo {
    let structure: TableStructure
    let content: [String] // Ordered cell content from NSAttributedString
    let placeholder: String // Unique placeholder for this table
    let estimatedPosition: Int // Estimated character position in the attributed string
    
    // Computed property to get cells by combining structure and content
    var cells: [TableCell] {
        var cells: [TableCell] = []
        for (index, position) in structure.cellPositions.enumerated() {
            let cellContent = index < content.count ? content[index] : ""
            cells.append(TableCell(content: cellContent, row: position.row, column: position.column))
        }
        return cells
    }
    
    var rows: Int { structure.rows }
    var columns: Int { structure.columns }
}

struct TableDetectionResult {
    let tables: [TableInfo]
    let attributedStringWithPlaceholders: NSMutableAttributedString
}

// MARK: - RTF Table Structure Parser
class RTFTableStructureParser {
    
    func extractTableStructures(from rtfString: String) -> [TableStructure] {
        print("[extractTableStructures] Analyzing RTF for table structures")
        print("[rtfString sample]: \(String(rtfString.prefix(200)))...")
        
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
                if let structure = parseAppleRTFTableStructure(from: tableBlock) {
                    structures.append(structure)
                    print("✅ Found Apple RTF table: \(structure.rows)×\(structure.columns)")
                }
            }
        }
        
        // Method 2: Fallback - look for simpler table patterns
        if structures.isEmpty {
            print("🔄 Trying fallback patterns...")
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
    private func parseAppleRTFTableStructure(from tableBlock: String) -> TableStructure? {
        print("🔍 [parseAppleRTFTableStructure] Parsing Apple RTF table structure")
        
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
        print("📊 Detected \(columns) columns from cellx values: \(cellxValues.sorted())")
        
        // Count rows by looking for \row markers
        let rowPattern = #"\\(lastrow\\)?row"#
        guard let rowRegex = try? NSRegularExpression(pattern: rowPattern) else { return nil }
        
        let rowMatches = rowRegex.matches(in: tableBlock, range: NSRange(tableBlock.startIndex..., in: tableBlock))
        let rows = rowMatches.count
        print("📊 Detected \(rows) rows from \\row markers")
        
        // Validate we have a meaningful table
        guard rows > 0 && columns > 0 else {
            print("❌ Invalid table structure: \(rows) rows, \(columns) columns")
            return nil
        }
        
        // Generate cell positions
        var cellPositions: [(row: Int, column: Int)] = []
        for rowIndex in 0..<rows {
            for columnIndex in 0..<columns {
                cellPositions.append((row: rowIndex, column: columnIndex))
            }
        }
        
        print("✅ Created table structure: \(rows)×\(columns) with \(cellPositions.count) cells")
        
        return TableStructure(
            rows: rows,
            columns: columns,
            cellPositions: cellPositions
        )
    }
    
    private func parseTableStructure(from tableBlock: String) -> TableStructure? {
        // Legacy method - now calls the Apple RTF parser
        return parseAppleRTFTableStructure(from: tableBlock)
    }
    
    private func groupConsecutiveTableRowStructures(_ rtfString: String) -> [TableStructure] {
        var structures: [TableStructure] = []
        
        let rowPattern = #"\\trowd[\s\S]*?\\row"#
        guard let rowRegex = try? NSRegularExpression(pattern: rowPattern) else { return [] }
        
        let rowRange = NSRange(rtfString.startIndex..., in: rtfString)
        let rowMatches = rowRegex.matches(in: rtfString, range: rowRange)
        
        var currentRows: [String] = []
        var lastRowEnd = 0
        
        for match in rowMatches {
            guard let range = Range(match.range, in: rtfString) else { continue }
            let rowBlock = String(rtfString[range])
            
            let currentRowStart = match.range.location
            let gap = currentRowStart - lastRowEnd
            
            if gap < 100 && !currentRows.isEmpty {
                currentRows.append(rowBlock)
            } else {
                if !currentRows.isEmpty,
                   let structure = createStructureFromRows(currentRows) {
                    structures.append(structure)
                    print("✅ Found grouped table: \(structure.rows)×\(structure.columns)")
                }
                currentRows = [rowBlock]
            }
            
            lastRowEnd = match.range.location + match.range.length
        }
        
        if !currentRows.isEmpty,
           let structure = createStructureFromRows(currentRows) {
            structures.append(structure)
        }
        
        return structures
    }
    
    private func createStructureFromRows(_ rows: [String]) -> TableStructure? {
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
    
    func extractTableContent(from attributedString: NSAttributedString, expectedCellCount: Int) -> [String] {
        print("📝 [extractTableContent] Extracting content for \(expectedCellCount) cells")
        
        var content: [String] = []
        
        // Method 1: Direct string extraction with smart cleaning
        content = extractCleanTextContent(from: attributedString, expectedCells: expectedCellCount)
        print("   Method 1 (clean text): \(content.count) cells")
        
        // Method 2: Look for tab-separated content if Method 1 didn't work well
        if content.count < expectedCellCount || content.allSatisfy({ $0.isEmpty }) {
            let tabContent = extractTabSeparatedContent(from: attributedString)
            if tabContent.count > content.count {
                content = tabContent
                print("   Method 2 (tab-separated): \(content.count) cells")
            }
        }
        
        // Method 3: Look for table-structured content using attachment boundaries
        if content.count < expectedCellCount {
            let attachmentContent = extractContentAroundAttachments(from: attributedString)
            if attachmentContent.count > content.count {
                content = attachmentContent
                print("   Method 3 (attachment-based): \(content.count) cells")
            }
        }
        
        // Method 4: Split by lines and try to extract cells
        if content.count < expectedCellCount {
            let lineBasedContent = extractLineBasedContent(from: attributedString, expectedCells: expectedCellCount)
            if lineBasedContent.count > content.count {
                content = lineBasedContent
                print("   Method 4 (line-based): \(content.count) cells")
            }
        }
        
        // Ensure we have enough content slots (pad with empty strings if needed)
        while content.count < expectedCellCount {
            content.append("")
        }
        
        print("✅ Final extracted content (\(content.count) cells): \(content)")
        return content
    }
    
    // NEW: Method for extracting content for multiple tables with better separation
    func extractMultiTableContent(from attributedString: NSAttributedString, tableStructures: [TableStructure]) -> [[String]] {
        print("📝 [extractMultiTableContent] Extracting content for \(tableStructures.count) tables")
        
        let string = attributedString.string
        var allTableContent: [[String]] = []
        
        // First, try to identify table groups in the content
        let lines = string.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        
        var currentTableLines: [String] = []
        var tablesContent: [[String]] = []
        
        for line in lines {
            if line.isEmpty {
                // Empty line might indicate table boundary
                if !currentTableLines.isEmpty {
                    let tableContent = extractContentFromLines(currentTableLines)
                    if !tableContent.isEmpty {
                        tablesContent.append(tableContent)
                    }
                    currentTableLines = []
                }
                continue
            }
            
            // Check if this line contains table-like content (tabs or multiple spaces)
            if line.contains("\t") || line.range(of: "\\s{2,}", options: .regularExpression) != nil {
                currentTableLines.append(line)
            } else if !currentTableLines.isEmpty {
                // Non-table content - end current table
                let tableContent = extractContentFromLines(currentTableLines)
                if !tableContent.isEmpty {
                    tablesContent.append(tableContent)
                }
                currentTableLines = [line] // Start new potential table
            } else {
                currentTableLines.append(line)
            }
        }
        
        // Don't forget the last table
        if !currentTableLines.isEmpty {
            let tableContent = extractContentFromLines(currentTableLines)
            if !tableContent.isEmpty {
                tablesContent.append(tableContent)
            }
        }
        
        print("📊 Identified \(tablesContent.count) content groups from text analysis")
        
        // Match content groups to table structures
        for (index, structure) in tableStructures.enumerated() {
            let expectedCells = structure.cellPositions.count
            
            if index < tablesContent.count {
                let content = tablesContent[index]
                // Pad or trim to match expected cell count
                let adjustedContent = adjustContentToStructure(content, expectedCells: expectedCells)
                allTableContent.append(adjustedContent)
                print("   Table \(index + 1): matched \(content.count) -> \(adjustedContent.count) cells")
            } else {
                // Fallback: create empty content
                allTableContent.append(Array(repeating: "", count: expectedCells))
                print("   Table \(index + 1): fallback empty content (\(expectedCells) cells)")
            }
        }
        
        return allTableContent
    }
    
    private func extractContentFromLines(_ lines: [String]) -> [String] {
        var content: [String] = []
        
        for line in lines {
            if line.contains("\t") {
                // Tab-separated content
                let cells = line.components(separatedBy: "\t")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                content.append(contentsOf: cells)
            } else {
                // Try space-separated (2+ spaces)
                let pattern = "\\s{2,}"
                if let regex = try? NSRegularExpression(pattern: pattern) {
                    let normalizedLine = regex.stringByReplacingMatches(
                        in: line,
                        range: NSRange(location: 0, length: line.count),
                        withTemplate: "\t"
                    )
                    let cells = normalizedLine.components(separatedBy: "\t")
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                    
                    if cells.count > 1 {
                        content.append(contentsOf: cells)
                    } else {
                        content.append(line)
                    }
                } else {
                    content.append(line)
                }
            }
        }
        
        return content
    }
    
    private func adjustContentToStructure(_ content: [String], expectedCells: Int) -> [String] {
        if content.count == expectedCells {
            return content
        } else if content.count > expectedCells {
            return Array(content.prefix(expectedCells))
        } else {
            return content + Array(repeating: "", count: expectedCells - content.count)
        }
    }
    
    private func extractCleanTextContent(from attributedString: NSAttributedString, expectedCells: Int) -> [String] {
        let string = attributedString.string
        print("   Raw attributed string: '\(string)'")
        
        // For simple cases, just split the clean text intelligently
        var content: [String] = []
        let trimmedString = string.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !trimmedString.isEmpty {
            // Try splitting by common separators
            let separators = ["\t", "\n", "  "] // Tab, newline, double space
            
            for separator in separators {
                let parts = trimmedString.components(separatedBy: separator)
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                
                if parts.count >= expectedCells || (parts.count > 1 && parts.count >= content.count) {
                    content = parts
                    print("   Split by '\(separator)': \(content)")
                    break
                }
            }
            
            // If no good split found, treat as single content piece
            if content.isEmpty {
                content = [trimmedString]
            }
        }
        
        return content
    }
    
    private func extractTabSeparatedContent(from attributedString: NSAttributedString) -> [String] {
        let string = attributedString.string
        var content: [String] = []
        
        // Split by lines and then by tabs
        let lines = string.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }
            
            let cells = trimmed.components(separatedBy: "\t")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            
            content.append(contentsOf: cells)
        }
        
        return content
    }
    
    private func extractContentAroundAttachments(from attributedString: NSAttributedString) -> [String] {
        var content: [String] = []
        var currentText = ""
        
        attributedString.enumerateAttributes(in: NSRange(location: 0, length: attributedString.length), options: []) { attrs, range, _ in
            if attrs[.attachment] != nil {
                // Found attachment (likely table boundary)
                if !currentText.isEmpty {
                    content.append(currentText.trimmingCharacters(in: .whitespacesAndNewlines))
                    currentText = ""
                }
            } else {
                let substring = attributedString.attributedSubstring(from: range).string
                currentText += substring
            }
        }
        
        // Don't forget the last piece of text
        if !currentText.isEmpty {
            content.append(currentText.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        
        return content.filter { !$0.isEmpty }
    }
    
    private func extractLineBasedContent(from attributedString: NSAttributedString, expectedCells: Int) -> [String] {
        let string = attributedString.string
        let lines = string.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        var content: [String] = []
        
        // Try to split content evenly among expected cells
        if lines.count > 0 {
            let cellsPerLine = max(1, expectedCells / max(1, lines.count / 2)) // Estimate
            
            for line in lines {
                // Try different splitting approaches
                var cells: [String] = []
                
                // First try tabs
                let tabCells = line.components(separatedBy: "\t")
                if tabCells.count > 1 {
                    cells = tabCells
                } else {
                    // Try multiple spaces (2 or more)
                    let pattern = "\\s{2,}"
                    if let regex = try? NSRegularExpression(pattern: pattern) {
                        let spaceCells = regex.stringByReplacingMatches(in: line, range: NSRange(location: 0, length: line.count), withTemplate: "\t")
                            .components(separatedBy: "\t")
                        if spaceCells.count > 1 {
                            cells = spaceCells
                        } else {
                            // Single cell
                            cells = [line]
                        }
                    } else {
                        // Single cell
                        cells = [line]
                    }
                }
                
                content.append(contentsOf: cells.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) })
            }
        }
        
        return content.filter { !$0.isEmpty }
    }
}

// MARK: - RTF Table Parser
class RTFTableParser {
    
    func parseTableFromRTF(_ rtfData: Data) -> [TableInfo] {
        print("[parseTableFromRTF]")
        guard let rtfString = String(data: rtfData, encoding: .utf8) else {
            return []
        }
        
        return extractTablesFromRTF(rtfString)
    }
    
    func parseTableFromAttributedString(_ attributedString: NSAttributedString) -> [TableInfo] {
        // First try to get RTF data from attributed string
        let range = NSRange(location: 0, length: attributedString.length)
        
        guard let rtfData = try? attributedString.data(
            from: range,
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        ) else {
            // Fallback to other detection methods
            return parseTableFromParagraphStyles(attributedString) + parseTableFromTabs(attributedString)
        }
        
        let rtfTables = parseTableFromRTF(rtfData)
        if !rtfTables.isEmpty {
            return rtfTables
        }
        
        // Fallback to other methods if RTF parsing doesn't find tables
        return parseTableFromParagraphStyles(attributedString) + parseTableFromTabs(attributedString)
    }
    
    private func extractTablesFromRTF(_ rtfString: String) -> [TableInfo] {
        // NOTE: This is a legacy fallback method. 
        // The new approach uses RTFTableStructureParser for much better results.
        print("⚠️ Using legacy RTF table extraction - consider using the new separated approach")
        
        var tables: [TableInfo] = []
        let lines = rtfString.components(separatedBy: .newlines)
        var currentTable: [[String]] = []
        var currentRow: [String] = []
        var inTable = false
        var cellBuffer = ""
        
        for line in lines {
            // Check for table start
            if line.contains("\\trowd") {
                inTable = true
                currentTable = []
                currentRow = []
                cellBuffer = ""
                continue
            }
            
            // Check for row end
            if line.contains("\\row") && inTable {
                if !cellBuffer.isEmpty {
                    // Simple text cleaning - just remove basic RTF commands
                    let cleanedContent = simplifyRTFText(cellBuffer)
                    currentRow.append(cleanedContent)
                    cellBuffer = ""
                }
                if !currentRow.isEmpty {
                    currentTable.append(currentRow)
                    currentRow = []
                }
                continue
            }
            
            // Check for cell end
            if line.contains("\\cell") && inTable {
                let cleanedContent = simplifyRTFText(cellBuffer)
                currentRow.append(cleanedContent)
                cellBuffer = ""
                continue
            }
            
            // Check for table end
            if line.contains("\\pard") && inTable {
                if !currentTable.isEmpty {
                    tables.append(createTableInfo(from: currentTable))
                }
                inTable = false
                currentTable = []
                currentRow = []
                cellBuffer = ""
                continue
            }
            
            // Accumulate cell content
            if inTable {
                cellBuffer += line + " "
            }
        }
        
        // Handle case where table doesn't end with \pard
        if !currentTable.isEmpty {
            tables.append(createTableInfo(from: currentTable))
        }
        
        return tables
    }
    
    // Simple RTF text cleaning (much simpler than the old problematic method)
    private func simplifyRTFText(_ text: String) -> String {
        var cleanText = text
        
        // Remove common RTF control words (simple approach)
        let basicPatterns = [
            (#"\\[a-zA-Z]+\d*\s*"#, ""),  // Remove control words
            (#"\\."#, ""),                // Remove escaped characters
            (#"[{}]"#, ""),              // Remove braces
            (#"\s+"#, " ")               // Normalize whitespace
        ]
        
        for (pattern, replacement) in basicPatterns {
            cleanText = cleanText.replacingOccurrences(of: pattern, with: replacement, options: .regularExpression)
        }
        
        return cleanText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    

    
    private func createTableInfo(from tableData: [[String]]) -> TableInfo {
        let rows = tableData.count
        let columns = tableData.first?.count ?? 0
        
        var cells: [TableCell] = []
        
        for (rowIndex, row) in tableData.enumerated() {
            for (colIndex, cellContent) in row.enumerated() {
                cells.append(TableCell(content: cellContent, row: rowIndex, column: colIndex))
            }
        }
        
        return TableInfo(
            structure: TableStructure(rows: rows, columns: columns, cellPositions: cells.map { ($0.row, $0.column) }),
            content: cells.map { $0.content },
            placeholder: "[[__TABLE_\(UUID().uuidString.replacingOccurrences(of: "-", with: "_"))__]]",
            estimatedPosition: 0
        )
    }
}

// MARK: - NSTextTable Detection Extension
extension RTFTableParser {
    
    func parseTableFromParagraphStyles(_ attributedString: NSAttributedString) -> [TableInfo] {
        // iOS/UIKit doesn't support textBlocks like AppKit does
        // Instead, we'll detect tables using tab stops and alignment patterns
        var potentialTableLines: [String] = []
        let string = attributedString.string
        _ = attributedString.length
        
        let lines = string.components(separatedBy: .newlines)
        var currentLocation = 0
        
        for line in lines {
            if line.isEmpty {
                currentLocation += 1
                continue
            }
            
            let lineRange = NSRange(location: currentLocation, length: line.count)
            var hasTableIndicators = false
            
            // Check for table indicators in paragraph styles
            attributedString.enumerateAttribute(
                .paragraphStyle,
                in: lineRange,
                options: []
            ) { value, range, _ in
                guard let paragraphStyle = value as? NSParagraphStyle else { return }
                
                // Look for tab stops which indicate structured table data
                if !paragraphStyle.tabStops.isEmpty {
                    hasTableIndicators = true
                }
                
                // Check for non-standard tab intervals (often used in tables)
                if paragraphStyle.defaultTabInterval > 0 && paragraphStyle.defaultTabInterval != 28.0 {
                    hasTableIndicators = true
                }
                
                // Check for specific alignment patterns that suggest table structure
                if paragraphStyle.alignment != .natural && paragraphStyle.alignment != .left {
                    // Center or right alignment often indicates table headers/cells
                    hasTableIndicators = true
                }
            }
            
            if hasTableIndicators && line.contains("\t") {
                potentialTableLines.append(line)
            }
            
            currentLocation += line.count + 1
        }
        
        // Convert potential table lines to TableInfo
        if potentialTableLines.count > 1 {
            var tableRows: [[String]] = []
            var maxColumns = 0
            
            for line in potentialTableLines {
                let cells = line.components(separatedBy: "\t")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
                
                if cells.count > 1 {
                    tableRows.append(cells)
                    maxColumns = max(maxColumns, cells.count)
                }
            }
            
            if !tableRows.isEmpty && maxColumns > 1 {
                var cells: [TableCell] = []
                
                for (rowIndex, row) in tableRows.enumerated() {
                    for (colIndex, content) in row.enumerated() {
                        cells.append(TableCell(content: content, row: rowIndex, column: colIndex))
                    }
                }
                
                return [TableInfo(
                    structure: TableStructure(rows: tableRows.count, columns: maxColumns, cellPositions: cells.map { ($0.row, $0.column) }),
                    content: cells.map { $0.content },
                    placeholder: "[[__TABLE_\(UUID().uuidString.replacingOccurrences(of: "-", with: "_"))__]]",
                    estimatedPosition: 0
                )]
            }
        }
        
        return []
    }
    
    func parseTableFromTabs(_ attributedString: NSAttributedString) -> [TableInfo] {
        let string = attributedString.string
        let lines = string.components(separatedBy: .newlines)
        
        var potentialTable: [[String]] = []
        var maxColumns = 0
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Skip empty lines
            if trimmed.isEmpty { 
                if !potentialTable.isEmpty {
                    // End of potential table
                    break
                }
                continue 
            }
            
            // Split by tabs first
            var cells = trimmed.components(separatedBy: "\t")
            
            // If no tabs, try splitting by multiple spaces (2 or more)
            if cells.count <= 1 {
                let pattern = #"\s{2,}"#
                let regex = try? NSRegularExpression(pattern: pattern)
                let range = NSRange(location: 0, length: trimmed.count)
                let components = regex?.stringByReplacingMatches(in: trimmed, range: range, withTemplate: "\t")
                    .components(separatedBy: "\t") ?? []
                
                if components.count > 1 {
                    cells = components
                }
            }
            
            // Clean up cells
            let cleanCells = cells.map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            
            if cleanCells.count > 1 {
                potentialTable.append(cleanCells)
                maxColumns = max(maxColumns, cleanCells.count)
            } else if !potentialTable.isEmpty {
                // End of table
                break
            }
        }
        
        // Only consider it a table if we have multiple rows and columns
        if potentialTable.count > 1 && maxColumns > 1 {
            var cells: [TableCell] = []
            
            for (rowIndex, row) in potentialTable.enumerated() {
                for (colIndex, content) in row.enumerated() {
                    cells.append(TableCell(content: content, row: rowIndex, column: colIndex))
                }
            }
            
            return [TableInfo(
                structure: TableStructure(rows: potentialTable.count, columns: maxColumns, cellPositions: cells.map { ($0.row, $0.column) }),
                content: cells.map { $0.content },
                placeholder: "[[__TABLE_\(UUID().uuidString.replacingOccurrences(of: "-", with: "_"))__]]",
                estimatedPosition: 0
            )]
        }
        
        return []
    }
}

// MARK: - Table Utilities
struct TableUtilities {
    
    static let parser = RTFTableParser()
    static let structureParser = RTFTableStructureParser()
    static let contentExtractor = AttributedStringTableContentExtractor()
    
    // MARK: - Main Table Detection
    static func detectTables(in attributedString: NSAttributedString) -> [TableInfo] {
        return parser.parseTableFromAttributedString(attributedString)
    }
    
    // MARK: - New Placeholder-Based Table Detection with Separated Structure and Content
    static func detectTablesWithPlaceholders(in attributedString: NSAttributedString, rawRTF: String?) -> TableDetectionResult {
        print("🔍 [detectTablesWithPlaceholders] Starting improved table detection")
        var detectedTables: [TableInfo] = []
        let mutableAttributedString = NSMutableAttributedString(attributedString: attributedString)
        
        if let rawRTF = rawRTF {
            // NEW APPROACH: Extract structure from RTF, content from NSAttributedString
            print("📋 Using separated structure + content approach")
            detectedTables = detectTablesWithSeparatedApproach(rawRTF: rawRTF, attributedString: attributedString)
        } else {
            // Fallback to existing detection methods
            print("🔄 Fallback to existing detection methods")
            detectedTables = parser.parseTableFromAttributedString(attributedString)
                .enumerated()
                .map { index, table in
                    TableInfo(
                        structure: TableStructure(rows: table.rows, columns: table.columns, cellPositions: table.cells.map { ($0.row, $0.column) }),
                        content: table.cells.map { $0.content },
                        placeholder: "[[__TABLE_\(UUID().uuidString.replacingOccurrences(of: "-", with: "_"))__]]",
                        estimatedPosition: 0
                    )
                }
        }
        
        print("✅ Found \(detectedTables.count) tables total")
        for (index, table) in detectedTables.enumerated() {
            print("   Table \(index + 1): \(table.rows)×\(table.columns) with \(table.content.count) content pieces")
        }
        
        // Insert placeholders into the attributed string
        insertPlaceholders(for: detectedTables, in: mutableAttributedString)
        
        return TableDetectionResult(tables: detectedTables, attributedStringWithPlaceholders: mutableAttributedString)
    }
    
    // MARK: - New Separated Approach
    private static func detectTablesWithSeparatedApproach(rawRTF: String, attributedString: NSAttributedString) -> [TableInfo] {
        // Step 1: Extract table structures from raw RTF
        let structures = structureParser.extractTableStructures(from: rawRTF)
        print("📐 Extracted \(structures.count) table structures from RTF")
        
        // Step 2: Extract ALL content from NSAttributedString once
        let totalExpectedCells = structures.reduce(0) { $0 + $1.cellPositions.count }
        let allContent = contentExtractor.extractTableContent(from: attributedString, expectedCellCount: totalExpectedCells)
        print("📝 Extracted \(allContent.count) total content pieces for \(structures.count) tables")
        
        // Step 3: Distribute content to tables based on their structure
        var tables: [TableInfo] = []
        var contentIndex = 0
        
        for (index, structure) in structures.enumerated() {
            let cellCount = structure.cellPositions.count
            let endIndex = min(contentIndex + cellCount, allContent.count)
            
            // Extract content for this specific table
            let tableContent = Array(allContent[contentIndex..<endIndex])
            
            // Pad with empty strings if we don't have enough content
            let paddedContent = tableContent + Array(repeating: "", count: max(0, cellCount - tableContent.count))
            
            let placeholder = "[[__TABLE_\(UUID().uuidString.replacingOccurrences(of: "-", with: "_"))__]]"
            let estimatedPosition = estimatePositionFromTableIndex(index, in: attributedString)
            
            let tableInfo = TableInfo(
                structure: structure,
                content: paddedContent,
                placeholder: placeholder,
                estimatedPosition: estimatedPosition
            )
            
            tables.append(tableInfo)
            print("🔗 Table \(index + 1): \(structure.rows)×\(structure.columns) with content[\(contentIndex)..<\(endIndex)]: \(tableContent)")
            
            // Move to next table's content
            contentIndex = endIndex
        }
        
        return tables
    }
    
    // MARK: - Markdown Conversion - Updated for new structure
    static func convertTableToMarkdown(_ table: TableInfo) -> String {
        guard table.rows > 0 && table.columns > 0 else {
            return ""
        }
        
        print("📝 Converting table to markdown: \(table.rows)×\(table.columns)")
        
        // Create a 2D array to organize the cells using the combined data
        var grid: [[String]] = Array(repeating: Array(repeating: "", count: table.columns), count: table.rows)
        
        // Fill the grid using the cells property (which combines structure + content)
        for cell in table.cells {
            if cell.row < table.rows && cell.column < table.columns {
                grid[cell.row][cell.column] = cell.content.isEmpty ? " " : cell.content
                print("   Cell[\(cell.row),\(cell.column)]: '\(cell.content)'")
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
        
        print("✅ Generated markdown table:\n\(markdown)")
        return markdown
    }


// MARK: - Helper Functions
private static func estimatePositionFromTableIndex(_ index: Int, in attributedString: NSAttributedString) -> Int {
    // Simple heuristic: distribute tables evenly across the document
    let totalLength = attributedString.length
    let estimatedPosition = Int(Double(index + 1) / 10.0 * Double(totalLength))
    return max(0, min(estimatedPosition, totalLength - 1))
}

// MARK: - Improved RTF Table Detection (Legacy - now simplified)
private static func detectTablesFromRawRTF(_ rtfString: String, in attributedString: NSAttributedString) -> [TableInfo] {
    // This method is kept for backward compatibility but simplified
    // The new approach separates structure and content extraction
    return detectTablesWithSeparatedApproach(rawRTF: rtfString, attributedString: attributedString)
}

// MARK: - Simplified Table Creation Helpers
private static func createTableInfoWithPlaceholder(from tableData: [[String]], position: Int) -> TableInfo {
    let rows = tableData.count
    let columns = tableData.first?.count ?? 0
    
    var cellPositions: [(row: Int, column: Int)] = []
    var content: [String] = []
    
    for (rowIndex, row) in tableData.enumerated() {
        for (colIndex, cellContent) in row.enumerated() {
            cellPositions.append((row: rowIndex, column: colIndex))
            content.append(cellContent)
        }
    }
    
    let structure = TableStructure(
        rows: rows,
        columns: columns,
        cellPositions: cellPositions
    )
    
    let placeholder = "[[__TABLE_\(UUID().uuidString.replacingOccurrences(of: "-", with: "_"))__]]"
    
    return TableInfo(
        structure: structure,
        content: content,
        placeholder: placeholder,
        estimatedPosition: position
    )
}

private static func insertPlaceholders(for tables: [TableInfo], in mutableAttributedString: NSMutableAttributedString) {
    // Sort tables by position (reverse order to maintain indices)
    let sortedTables = tables.sorted { $0.estimatedPosition > $1.estimatedPosition }
    
    for table in sortedTables {
        // Find a suitable location to insert the placeholder
        let insertPosition = findBestInsertionPoint(for: table, in: mutableAttributedString)
        
        // Insert the placeholder
        let placeholderString = NSAttributedString(string: "\n\(table.placeholder)\n")
        mutableAttributedString.insert(placeholderString, at: insertPosition)
    }
}

private static func findBestInsertionPoint(for table: TableInfo, in attributedString: NSMutableAttributedString) -> Int {
    let content = attributedString.string
    let length = content.count
    
    // Try to find table content in the attributed string
    for cell in table.cells.prefix(3) { // Check first few cells
        if !cell.content.isEmpty,
           let range = content.range(of: cell.content) {
            // Find the start of the line containing this cell
            let lineStart = content.lineRange(for: range).lowerBound
            return NSRange(lineStart..<lineStart, in: content).location
        }
    }
    
    // Fallback to estimated position
    return min(table.estimatedPosition, length)
}

// MARK: - Placeholder Replacement
static func replacePlaceholdersWithMarkdown(_ markdown: String, tables: [TableInfo]) -> String {
    var result = markdown
    
    for table in tables {
        let tableMarkdown = convertTableToMarkdown(table)
        result = result.replacingOccurrences(of: table.placeholder, with: tableMarkdown)
    }
    
    return result
}


}