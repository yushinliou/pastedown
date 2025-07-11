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

struct TableInfo {
    let rows: Int
    let columns: Int
    let cells: [TableCell]
    let placeholder: String // Unique placeholder for this table
    let estimatedPosition: Int // Estimated character position in the attributed string
}

struct TableDetectionResult {
    let tables: [TableInfo]
    let attributedStringWithPlaceholders: NSMutableAttributedString
}

// MARK: - RTF Table Parser
class RTFTableParser {
    
    func parseTableFromRTF(_ rtfData: Data) -> [TableInfo] {
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
                    currentRow.append(cleanRTFText(cellBuffer))
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
                currentRow.append(cleanRTFText(cellBuffer))
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
    
    private func cleanRTFText(_ text: String) -> String {
        var cleaned = text
        
        // Remove common RTF control words
        let rtfPattern = #"\\[a-zA-Z]+\d*\s?"#
        cleaned = cleaned.replacingOccurrences(of: rtfPattern, with: "", options: .regularExpression)
        
        // Remove curly braces
        cleaned = cleaned.replacingOccurrences(of: "{", with: "")
        cleaned = cleaned.replacingOccurrences(of: "}", with: "")
        
        // Clean up whitespace
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        cleaned = cleaned.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        
        return cleaned
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
            rows: rows,
            columns: columns,
            cells: cells,
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
        let length = attributedString.length
        
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
                    rows: tableRows.count, 
                    columns: maxColumns, 
                    cells: cells,
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
                rows: potentialTable.count, 
                columns: maxColumns, 
                cells: cells,
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
    
    // MARK: - Main Table Detection
    static func detectTables(in attributedString: NSAttributedString) -> [TableInfo] {
        return parser.parseTableFromAttributedString(attributedString)
    }
    
    // MARK: - New Placeholder-Based Table Detection
    static func detectTablesWithPlaceholders(in attributedString: NSAttributedString, rawRTF: String?) -> TableDetectionResult {
        print("detectTablesWithPlaceholders")
        var detectedTables: [TableInfo] = []
        let mutableAttributedString = NSMutableAttributedString(attributedString: attributedString)
        
        if let rawRTF = rawRTF {
            // Use raw RTF string for table detection
            detectedTables = detectTablesFromRawRTF(rawRTF, in: attributedString)
            print("[detectTablesFromRawRTF]")
        } else {
            // Fallback to existing detection methods
            print("[parseTableFromAttributedString]")
            detectedTables = parser.parseTableFromAttributedString(attributedString)
                .enumerated()
                .map { index, table in
                    TableInfo(
                        rows: table.rows,
                        columns: table.columns,
                        cells: table.cells,
                        placeholder: "[[__TABLE_\(UUID().uuidString.replacingOccurrences(of: "-", with: "_"))__]]",
                        estimatedPosition: 0 // Will be estimated below
                    )
                }
        }
        
        // Insert placeholders into the attributed string
        insertPlaceholders(for: detectedTables, in: mutableAttributedString)
        
        return TableDetectionResult(tables: detectedTables, attributedStringWithPlaceholders: mutableAttributedString)
    }
    
    // MARK: - Markdown Conversion
    static func convertTableToMarkdown(_ table: TableInfo) -> String {
        guard table.rows > 0 && table.columns > 0 else {
            return ""
        }
        
        // Create a 2D array to organize the cells
        var grid: [[String]] = Array(repeating: Array(repeating: "", count: table.columns), count: table.rows)
        
        // Fill the grid with cell content
        for cell in table.cells {
            if cell.row < table.rows && cell.column < table.columns {
                grid[cell.row][cell.column] = cell.content.isEmpty ? " " : cell.content
            }
        }
        
        var markdown = ""
        
        // Add header row (first row)
        if table.rows > 0 {
            markdown += "| " + grid[0].joined(separator: " | ") + " |\n"
            
            // Add separator row, generate the length of `-` according to the length of content
            
            markdown += "|" + String(repeating: "---|", count: table.columns) + "\n"
            
            // Add data rows (skip first row which we used as header)
            for rowIndex in 1..<table.rows {
                markdown += "| " + grid[rowIndex].joined(separator: " | ") + " |\n"
            }
        }
        
        return markdown
    }

    private static func estimateNumberOfColumns(from rtfBlock: String, fallback: Int = 2) -> Int {
        // 根據出現的 \cellx 數量推估欄位數
        let pattern = #"\\cellx\d+"#
        let matches = try? NSRegularExpression(pattern: pattern)
            .matches(in: rtfBlock, range: NSRange(rtfBlock.startIndex..., in: rtfBlock))
        return matches?.count ?? fallback
    }

// MARK: - Improved RTF Table Detection
private static func detectTablesFromRawRTF(_ rtfString: String, in attributedString: NSAttributedString) -> [TableInfo] {
    var tables: [TableInfo] = []
    print("[rtfString]\(rtfString)")
    
    // Method 1: Look for complete tables ending with \lastrow\row
    let completeTablePattern = #"\\trowd[\s\S]*?\\lastrow\\row"#
    if let completeTableRegex = try? NSRegularExpression(pattern: completeTablePattern),
       !completeTableRegex.matches(in: rtfString, range: NSRange(rtfString.startIndex..., in: rtfString)).isEmpty {
        
        let matches = completeTableRegex.matches(in: rtfString, range: NSRange(rtfString.startIndex..., in: rtfString))
        for (index, match) in matches.enumerated() {
            guard let range = Range(match.range, in: rtfString) else { continue }
            let tableBlock = String(rtfString[range])
            let tableInfo = parseCompleteRTFTable(tableBlock, index: index, in: attributedString)
            if !tableInfo.cells.isEmpty {
                tables.append(tableInfo)
                print("[complete table]\(tableInfo)")
            }
        }
    } else {
        // Method 2: Fallback - Group consecutive table rows
        tables = groupConsecutiveTableRows(rtfString, in: attributedString)
    }
    
    return tables
}

// MARK: - Parse Complete RTF Table (with \lastrow)
private static func parseCompleteRTFTable(_ tableBlock: String, index: Int, in attributedString: NSAttributedString) -> TableInfo {
    // Split into individual rows by looking for \row markers
    let rowPattern = #"\\trowd[\s\S]*?\\row"#
    guard let rowRegex = try? NSRegularExpression(pattern: rowPattern) else {
        return createEmptyTable(index: index, in: attributedString)
    }
    
    let rowRange = NSRange(tableBlock.startIndex..., in: tableBlock)
    let rowMatches = rowRegex.matches(in: tableBlock, range: rowRange)
    
    var cellMatrix: [[String]] = []
    var maxColumns = 0
    
    for rowMatch in rowMatches {
        guard let rowRange = Range(rowMatch.range, in: tableBlock) else { continue }
        let rowBlock = String(tableBlock[rowRange])
        
        // Extract cells from this row
        let cells = extractCellsFromRow(rowBlock)
        if !cells.isEmpty {
            cellMatrix.append(cells)
            maxColumns = max(maxColumns, cells.count)
        }
    }
    
    // Normalize rows to have the same number of columns
    for i in 0..<cellMatrix.count {
        while cellMatrix[i].count < maxColumns {
            cellMatrix[i].append("")
        }
    }
    
    let estimatedPosition = estimatePositionFromRTFLine(index * 2, in: attributedString)
    return createTableInfoWithPlaceholder(from: cellMatrix, position: estimatedPosition)
}

// MARK: - Group Consecutive Table Rows (Fallback)
private static func groupConsecutiveTableRows(_ rtfString: String, in attributedString: NSAttributedString) -> [TableInfo] {
    var tables: [TableInfo] = []
    
    // Find all individual table rows
    let rowPattern = #"\\trowd[\s\S]*?\\row"#
    guard let rowRegex = try? NSRegularExpression(pattern: rowPattern) else {
        return []
    }
    
    let rowRange = NSRange(rtfString.startIndex..., in: rtfString)
    let rowMatches = rowRegex.matches(in: rtfString, range: rowRange)
    
    var currentTableRows: [String] = []
    var lastRowEnd = 0
    
    for (index, match) in rowMatches.enumerated() {
        guard let range = Range(match.range, in: rtfString) else { continue }
        let rowBlock = String(rtfString[range])
        
        // Check if this row is immediately after the previous one (consecutive)
        let currentRowStart = match.range.location
        let gap = currentRowStart - lastRowEnd
        
        // If gap is small (just whitespace/formatting), consider it part of the same table
        if gap < 100 && !currentTableRows.isEmpty {
            currentTableRows.append(rowBlock)
        } else {
            // If we have accumulated rows, create a table
            if !currentTableRows.isEmpty {
                let tableInfo = createTableFromRows(currentTableRows, index: tables.count, in: attributedString)
                if !tableInfo.cells.isEmpty {
                    tables.append(tableInfo)
                }
            }
            // Start new table
            currentTableRows = [rowBlock]
        }
        
        lastRowEnd = match.range.location + match.range.length
    }
    
    // Don't forget the last table
    if !currentTableRows.isEmpty {
        let tableInfo = createTableFromRows(currentTableRows, index: tables.count, in: attributedString)
        if !tableInfo.cells.isEmpty {
            tables.append(tableInfo)
        }
    }
    
    return tables
}

// MARK: - Create Table from Rows
private static func createTableFromRows(_ rows: [String], index: Int, in attributedString: NSAttributedString) -> TableInfo {
    var cellMatrix: [[String]] = []
    var maxColumns = 0
    
    for rowBlock in rows {
        let cells = extractCellsFromRow(rowBlock)
        if !cells.isEmpty {
            cellMatrix.append(cells)
            maxColumns = max(maxColumns, cells.count)
        }
    }
    
    // Normalize rows
    for i in 0..<cellMatrix.count {
        while cellMatrix[i].count < maxColumns {
            cellMatrix[i].append("")
        }
    }
    
    let estimatedPosition = estimatePositionFromRTFLine(index * 2, in: attributedString)
    return createTableInfoWithPlaceholder(from: cellMatrix, position: estimatedPosition)
}

// MARK: - Extract Cells from Row
private static func extractCellsFromRow(_ rowBlock: String) -> [String] {
    var cells: [String] = []
    
    // Method 1: Look for content between \pard\intbl and \cell markers
    let cellPattern = #"\\pard\\intbl.*?\\cf\d+\s+(.*?)\\cell"#
    if let cellRegex = try? NSRegularExpression(pattern: cellPattern, options: [.dotMatchesLineSeparators]) {
        let cellRange = NSRange(rowBlock.startIndex..., in: rowBlock)
        let cellMatches = cellRegex.matches(in: rowBlock, range: cellRange)
        
        for cellMatch in cellMatches {
            if cellMatch.numberOfRanges > 1,
               let textRange = Range(cellMatch.range(at: 1), in: rowBlock) {
                let cellText = String(rowBlock[textRange])
                let cleanedText = cleanRTFText(cellText)
                if !cleanedText.isEmpty {
                    cells.append(cleanedText)
                }
            }
        }
    }
    
    // Method 2: Alternative pattern for simpler cases
    if cells.isEmpty {
        let simplePattern = #"\\AppleTypeServices\s+\\cf\d+\s+(.*?)\\f\d+\\fs\d+\s+\\cell"#
        if let simpleRegex = try? NSRegularExpression(pattern: simplePattern, options: [.dotMatchesLineSeparators]) {
            let cellRange = NSRange(rowBlock.startIndex..., in: rowBlock)
            let cellMatches = simpleRegex.matches(in: rowBlock, range: cellRange)
            
            for cellMatch in cellMatches {
                if cellMatch.numberOfRanges > 1,
                   let textRange = Range(cellMatch.range(at: 1), in: rowBlock) {
                    let cellText = String(rowBlock[textRange])
                    let cleanedText = cleanRTFText(cellText)
                    if !cleanedText.isEmpty {
                        cells.append(cleanedText)
                    }
                }
            }
        }
    }
    
    // Method 3: Fallback - split by \cell and clean (more permissive)
    if cells.isEmpty {
        let components = rowBlock.components(separatedBy: "\\cell")
        for component in components {
            let cleanedText = cleanRTFText(component)
            if !cleanedText.isEmpty && isValidCellContent(cleanedText) {
                cells.append(cleanedText)
            }
        }
    }
    
    return cells
}

// MARK: - Clean RTF Text
private static func cleanRTFText(_ text: String) -> String {
    var cleanText = text
    
    // Remove RTF control sequences but preserve Unicode content
    let patterns = [
        (#"\\AppleTypeServices\\AppleTypeServicesF\d+"#, ""),  // Apple-specific formatting
        (#"\\AppleTypeServices"#, ""),                         // Apple-specific formatting
        (#"\\f\d+\\fs\d+"#, ""),                              // Font and size
        (#"\\f\d+"#, ""),                                     // Font only
        (#"\\fs\d+"#, ""),                                    // Font size only
        (#"\\cf\d+"#, ""),                                    // Color
        (#"\\[a-zA-Z]+\d*\s*"#, ""),                          // Other control words with numbers
        (#"\\[a-zA-Z]+\s*"#, ""),                             // Other control words
        (#"\{[^}]*\}"#, ""),                                  // Braced groups (but preserve Unicode)
        (#"\\\*[^\\]*"#, ""),                                 // Destination groups
        (#"\\'"#, "'"),                                       // Escaped quotes
        (#"\s+"#, " ")                                        // Normalize whitespace
    ]
    
    for (pattern, replacement) in patterns {
        cleanText = cleanText.replacingOccurrences(of: pattern, with: replacement, options: .regularExpression)
    }
    
    // Handle Unicode characters (RTF uses \u<code> format)
    let unicodePattern = #"\\u(\d+)\s*"#
    if let unicodeRegex = try? NSRegularExpression(pattern: unicodePattern) {
        let matches = unicodeRegex.matches(in: cleanText, range: NSRange(cleanText.startIndex..., in: cleanText))
        for match in matches.reversed() { // Process in reverse to maintain string indices
            if let codeRange = Range(match.range(at: 1), in: cleanText),
               let unicodeValue = Int(String(cleanText[codeRange])),
               let unicodeScalar = UnicodeScalar(unicodeValue) {
                let unicodeChar = String(Character(unicodeScalar))
                let fullRange = Range(match.range, in: cleanText)!
                cleanText.replaceSubrange(fullRange, with: unicodeChar)
            }
        }
    }
    
    return cleanText.trimmingCharacters(in: .whitespacesAndNewlines)
}

// MARK: - Validate Cell Content
private static func isValidCellContent(_ text: String) -> Bool {
    // Much more permissive validation - only filter out obvious formatting artifacts
    let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
    
    // Allow empty cells
    if trimmedText.isEmpty {
        return false
    }
    
    // Filter out only obvious formatting artifacts (like "x8640" type strings)
    let invalidPatterns = [
        #"^x\d+$"#,                    // Strings like "x8640"
        #"^-\d+$"#,                    // Strings like "-108"
        #"^[\s\-]*$"#                  // Only whitespace and dashes
    ]
    
    for pattern in invalidPatterns {
        if text.range(of: pattern, options: .regularExpression) != nil {
            return false
        }
    }
    
    // Accept all other content including:
    // - Numbers (1, 2, 3, 4, etc.)
    // - Chinese characters
    // - Mixed content
    // - Single characters
    return true
}

// MARK: - Helper Functions
private static func createEmptyTable(index: Int, in attributedString: NSAttributedString) -> TableInfo {
    let estimatedPosition = estimatePositionFromRTFLine(index * 2, in: attributedString)
    return createTableInfoWithPlaceholder(from: [[]], position: estimatedPosition)
}

    // MARK: - Alternative: More Robust Cell Extraction
    private static func extractCellsFromRowAlternative(_ rowBlock: String) -> [String] {
        var cells: [String] = []
        
        // Split by \cell and process each potential cell
        let cellComponents = rowBlock.components(separatedBy: "\\cell")
        
        for component in cellComponents {
            // Look for actual text content (not just formatting)
            var cleanText = component
            
            // Remove RTF formatting but preserve actual text
            let patterns = [
                (#"\\[a-zA-Z]+\d*\s*"#, ""), // Remove control words with numbers
                (#"\\[a-zA-Z]+\s*"#, ""),   // Remove control words
                (#"\{\d*"#, ""),            // Remove group markers with numbers
                (#"\}"#, ""),               // Remove closing braces
                (#"\s+"#, " ")              // Normalize whitespace
            ]
            
            for (pattern, replacement) in patterns {
                cleanText = cleanText.replacingOccurrences(of: pattern, with: replacement, options: .regularExpression)
            }
            
            cleanText = cleanText.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Only add if it contains actual content (not just numbers or formatting residue)
            if !cleanText.isEmpty && !cleanText.allSatisfy({ $0.isNumber || $0.isWhitespace || $0 == "-" }) {
                cells.append(cleanText)
            }
        }
        
        return cells
    }
    
    private static func cleanRTFTextAdvanced(_ text: String) -> String {
        var cleaned = text
        
        // Remove common RTF control words (more comprehensive)
        let rtfPatterns = [
            #"\\[a-zA-Z]+\d*\s?"#,
            #"\\\*[^;]*;"#,  // Ignore destination groups
            #"\\[{}\\]"#,    // Escaped characters
            #"\{\*\\[^}]*\}"# // Ignore groups
        ]
        
        for pattern in rtfPatterns {
            cleaned = cleaned.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
        }
        
        // Remove curly braces
        cleaned = cleaned.replacingOccurrences(of: "{", with: "")
        cleaned = cleaned.replacingOccurrences(of: "}", with: "")
        
        // Clean up whitespace
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        cleaned = cleaned.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        
        return cleaned
    }
    
    private static func createTableInfoWithPlaceholder(from tableData: [[String]], position: Int) -> TableInfo {
        let rows = tableData.count
        let columns = tableData.first?.count ?? 0
        
        var cells: [TableCell] = []
        
        for (rowIndex, row) in tableData.enumerated() {
            for (colIndex, cellContent) in row.enumerated() {
                cells.append(TableCell(content: cellContent, row: rowIndex, column: colIndex))
            }
        }
        
        let placeholder = "[[__TABLE_\(UUID().uuidString.replacingOccurrences(of: "-", with: "_"))__]]"
        
        return TableInfo(
            rows: rows,
            columns: columns,
            cells: cells,
            placeholder: placeholder,
            estimatedPosition: position
        )
    }
    
    private static func estimatePositionFromRTFLine(_ lineIndex: Int, in attributedString: NSAttributedString) -> Int {
        // Simple heuristic: estimate position based on line ratio
        let totalLength = attributedString.length
        let estimatedPosition = Int(Double(lineIndex) / 100.0 * Double(totalLength))
        return max(0, min(estimatedPosition, totalLength - 1))
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
    
    // MARK: - Legacy Methods (for backward compatibility)
    static func handleTables(_ text: String, attributes: [NSAttributedString.Key: Any]) -> String {
        // This method is kept for backward compatibility but will be replaced by the new detection
        return text
    }
    
    static func isTableRow(_ text: String, attributes: [NSAttributedString.Key: Any]) -> Bool {
        // This method is kept for backward compatibility but will be replaced by the new detection
        return false
    }
    
    static func isNextLineTable(_ nextLine: String, attributedString: NSAttributedString, nextLocation: Int) -> Bool {
        // This method is kept for backward compatibility but will be replaced by the new detection
        return false
    }
    
    static func processCompleteTable(_ rows: [String]) -> String {
        // This method is kept for backward compatibility but will be replaced by the new detection
        return rows.joined(separator: "\n") + "\n"
    }
}