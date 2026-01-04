//  Created by GitHub Copilot on 04/01/2026.
//

import XCTest
@testable import Feather

final class GuideParserTests: XCTestCase {
    
    func testAccentColorHeadingWithPrefix() throws {
        // Test (accent://) prefix in headings
        let markdown = "## (accent://)Part 1"
        let result = GuideParser.parse(markdown: markdown)
        
        XCTAssertEqual(result.elements.count, 1)
        
        if case .heading(let level, let text, let isAccent) = result.elements[0] {
            XCTAssertEqual(level, 2)
            XCTAssertEqual(text, "Part 1")
            XCTAssertTrue(isAccent)
        } else {
            XCTFail("Expected heading element")
        }
    }
    
    func testAccentColorHeadingWithBrackets() throws {
        // Test existing [text](accent://) format
        let markdown = "## [Introduction](accent://)"
        let result = GuideParser.parse(markdown: markdown)
        
        XCTAssertEqual(result.elements.count, 1)
        
        if case .heading(let level, let text, let isAccent) = result.elements[0] {
            XCTAssertEqual(level, 2)
            XCTAssertEqual(text, "Introduction")
            XCTAssertTrue(isAccent)
        } else {
            XCTFail("Expected heading element")
        }
    }
    
    func testAccentColorInlineText() throws {
        // Test (accent://) followed by text in paragraphs
        let markdown = "This is (accent://)important text"
        let result = GuideParser.parse(markdown: markdown)
        
        XCTAssertEqual(result.elements.count, 1)
        
        if case .paragraph(let content) = result.elements[0] {
            // Should have: "This is ", accent("important"), " text"
            XCTAssertTrue(content.count >= 2, "Expected at least 2 content segments")
            
            // Check that we have an accentText segment
            let hasAccentText = content.contains { segment in
                if case .accentText(let text) = segment {
                    return text == "important"
                }
                return false
            }
            XCTAssertTrue(hasAccentText, "Expected accentText segment with 'important'")
        } else {
            XCTFail("Expected paragraph element")
        }
    }
    
    func testRegularHeadingWithoutAccent() throws {
        // Test that regular headings without accent markers work normally
        let markdown = "## Regular Heading"
        let result = GuideParser.parse(markdown: markdown)
        
        XCTAssertEqual(result.elements.count, 1)
        
        if case .heading(let level, let text, let isAccent) = result.elements[0] {
            XCTAssertEqual(level, 2)
            XCTAssertEqual(text, "Regular Heading")
            XCTAssertFalse(isAccent)
        } else {
            XCTFail("Expected heading element")
        }
    }
    
    func testMultipleAccentMarkersInParagraph() throws {
        // Test multiple accent markers in one paragraph
        let markdown = "(accent://)First and (accent://)Second"
        let result = GuideParser.parse(markdown: markdown)
        
        XCTAssertEqual(result.elements.count, 1)
        
        if case .paragraph(let content) = result.elements[0] {
            // Should have accent segments for both "First" and "Second"
            let accentTexts = content.compactMap { segment -> String? in
                if case .accentText(let text) = segment {
                    return text
                }
                return nil
            }
            
            XCTAssertTrue(accentTexts.contains("First"), "Expected 'First' to be accent text")
            XCTAssertTrue(accentTexts.contains("Second"), "Expected 'Second' to be accent text")
        } else {
            XCTFail("Expected paragraph element")
        }
    }
}
