//
//  AttachmentTests.swift
//  SendGrid
//
//  Created by Scott Kawai on 5/17/16.
//  Copyright © 2016 Scott Kawai. All rights reserved.
//

import XCTest
@testable import SendGrid

class AttachmentTests: XCTestCase {
    
    let dotBase64: String = "iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAHElEQVQI12P4\\/\\/8\\/w38GIAXDIBKE0DHxgljNBAAO9TXL0Y4OHwAAAABJRU5ErkJggg=="
    
    var image: Data?
    
    override func setUp() {
        super.setUp()
        if let path = Bundle(for: type(of: self)).pathForImageResource("dot.png") {
            self.image = try? Data(contentsOf: URL(fileURLWithPath: path))
        }
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testInitialization() {
        if let image = self.image {
            let basic = Attachment(filename: "dot.png", content: image)
            XCTAssertEqual(basic.filename, "dot.png")
            XCTAssertEqual(basic.disposition, ContentDisposition.Attachment)
            XCTAssertNil(basic.contentID)
            XCTAssertNil(basic.type)
            
            let advance = Attachment(filename: "dot_inline.png", content: image, disposition: ContentDisposition.Inline, type: ContentType.png, contentID: "dot")
            XCTAssertEqual(advance.filename, "dot_inline.png")
            XCTAssertEqual(advance.disposition, ContentDisposition.Inline)
            XCTAssertEqual(advance.type!.description, ContentType.png.description)
            XCTAssertEqual(advance.contentID, "dot")
        } else {
            XCTFail("Unable to locate `dot.png` file to run Attachment tests.")
        }
    }
    
    func testJSONValue() {
        if let image = self.image {
            let basic = Attachment(filename: "dot.png", content: image)
            XCTAssertEqual(basic.jsonValue, "{\"disposition\":\"attachment\",\"content\":\"\(self.dotBase64)\",\"filename\":\"dot.png\"}")
            
            let advance = Attachment(filename: "dot_inline.png", content: image, disposition: ContentDisposition.Inline, type: ContentType.png, contentID: "dot")
            XCTAssertEqual(advance.jsonValue, "{\"disposition\":\"inline\",\"content\":\"\(self.dotBase64)\",\"filename\":\"dot_inline.png\",\"type\":\"image\\/png\",\"content_id\":\"dot\"}")
        } else {
            XCTFail("Unable to locate `dot.png` file to run Attachment tests.")
        }
    }
    
    func testValidation() {
        if let image = self.image {
            do {
                // Validation should pass with a valid content type.
                let good = Attachment(filename: "dot.png", content: image, disposition: .Attachment, type: .png, contentID: nil)
                try good.validate()
                XCTAssertTrue(true)
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
            
            do {
                // Validation should pass when no content type is present.
                let good = Attachment(filename: "dot.png", content: image)
                try good.validate()
                XCTAssertTrue(true)
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
            
            do {
                // Should fail when content type has a semicolon.
                let semicolon = Attachment(filename: "dot.png", content: image, disposition: .Attachment, type: .other("image/png;"), contentID: nil)
                try semicolon.validate()
                XCTFail("Expected errot to be thrown when providing a content type with a semicolon, but no error was thrown")
            } catch {
                XCTAssertEqual("\(error)", SGError.Mail.invalidContentType("image/png;").description)
            }
            
            do {
                // Should fail when content type has a semicolon.
                let newline = Attachment(filename: "dot.png", content: image, disposition: .Attachment, type: .other("image/png\n"), contentID: nil)
                try newline.validate()
                XCTFail("Expected errot to be thrown when providing a content type with a semicolon, but no error was thrown")
            } catch {
                XCTAssertEqual("\(error)", SGError.Mail.invalidContentType("image/png\n").description)
            }
            
            do {
                //Should fail if filename has semicolons and newlines.
                let newline = Attachment(filename: "dot;\n.png", content: image, disposition: .Attachment, type: .png, contentID: nil)
                try newline.validate()
                XCTFail("Expected error to be thrown when providing a filename with a semicolon, but no error was thrown")
            } catch {
                XCTAssertEqual("\(error)", SGError.Mail.invalidFilename("dot;\n.png").description)
            }
            
            do {
                //Should fail if content ID has semicolons and newlines.
                let newline = Attachment(filename: "dot.png", content: image, disposition: .Attachment, type: .png, contentID: "asdf,asdf")
                try newline.validate()
                XCTFail("Expected error to be thrown when providing a content ID with a commma, but no error was thrown")
            } catch {
                XCTAssertEqual("\(error)", SGError.Mail.invalidContentID("asdf,asdf").description)
            }
            
            do {
                //Should fail if content ID is a blank string.
                let newline = Attachment(filename: "dot.png", content: image, disposition: .Attachment, type: .png, contentID: "")
                try newline.validate()
                XCTFail("Expected error to be thrown when providing a blank string for the content ID, but no error was thrown")
            } catch {
                XCTAssertEqual("\(error)", SGError.Mail.invalidContentID("").description)
            }
        }
    }
    
}
