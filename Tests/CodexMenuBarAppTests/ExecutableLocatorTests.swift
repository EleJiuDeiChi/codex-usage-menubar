import Foundation
import Testing
@testable import CodexMenuBarApp

@Test
func locatorPrefersBinaryFoundOnPath() {
    let locator = CodexExecutableLocator(
        environment: ["PATH": "/usr/local/bin:/opt/homebrew/bin"],
        fileExists: { path in
            path == "/opt/homebrew/bin/ccusage-codex"
        },
        nvmVersionsProvider: { [] }
    )

    #expect(locator.locate() == "/opt/homebrew/bin/ccusage-codex")
}

@Test
func locatorFallsBackToNewestNvmCandidate() {
    let locator = CodexExecutableLocator(
        environment: [:],
        fileExists: { path in
            path == "/Users/test/.nvm/versions/node/v22.22.0/bin/ccusage-codex"
        },
        nvmVersionsProvider: {
            [
                "/Users/test/.nvm/versions/node/v20.0.0/bin/ccusage-codex",
                "/Users/test/.nvm/versions/node/v22.22.0/bin/ccusage-codex"
            ]
        }
    )

    #expect(locator.locate() == "/Users/test/.nvm/versions/node/v22.22.0/bin/ccusage-codex")
}

@Test
func nodeLocatorFindsNodeInNvm() {
    let locator = NodeExecutableLocator(
        environment: [:],
        fileExists: { path in
            path == "/Users/test/.nvm/versions/node/v22.22.0/bin/node"
        },
        nvmVersionsProvider: {
            [
                "/Users/test/.nvm/versions/node/v20.0.0/bin/node",
                "/Users/test/.nvm/versions/node/v22.22.0/bin/node"
            ]
        }
    )

    #expect(locator.locate() == "/Users/test/.nvm/versions/node/v22.22.0/bin/node")
}
