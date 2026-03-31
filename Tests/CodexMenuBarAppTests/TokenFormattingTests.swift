import Testing
@testable import CodexMenuBarApp

@Test
func tokenFormatterUsesCompactUnits() {
    #expect(TokenCountFormatter.format(950) == "950")
    #expect(TokenCountFormatter.format(1_250) == "1.2K")
    #expect(TokenCountFormatter.format(54_321) == "54.3K")
    #expect(TokenCountFormatter.format(1_764_093) == "1.8M")
    #expect(TokenCountFormatter.format(281_536_117) == "281.5M")
}
