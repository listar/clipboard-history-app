import XCTest
@testable import ClipboardHistoryApp

class ClipboardTests: XCTestCase {

    var clipboardStore: ClipboardStore!

    override func setUp() {
        super.setUp()
        clipboardStore = ClipboardStore()
    }

    override func tearDown() {
        clipboardStore = nil
        super.tearDown()
    }

    func testAddClipboardItem() {
        let item = ClipboardItem(content: "Test content", timestamp: Date())
        clipboardStore.add(item: item)
        
        XCTAssertEqual(clipboardStore.items.count, 1)
        XCTAssertEqual(clipboardStore.items.first?.content, "Test content")
    }

    func testRemoveClipboardItem() {
        let item = ClipboardItem(content: "Test content", timestamp: Date())
        clipboardStore.add(item: item)
        clipboardStore.remove(item: item)
        
        XCTAssertEqual(clipboardStore.items.count, 0)
    }

    func testRetrieveClipboardItems() {
        let item1 = ClipboardItem(content: "First item", timestamp: Date())
        let item2 = ClipboardItem(content: "Second item", timestamp: Date())
        clipboardStore.add(item: item1)
        clipboardStore.add(item: item2)
        
        let items = clipboardStore.items
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[0].content, "First item")
        XCTAssertEqual(items[1].content, "Second item")
    }
}