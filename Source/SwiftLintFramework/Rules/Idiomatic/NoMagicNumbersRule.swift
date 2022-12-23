import SwiftSyntax

struct NoMagicNumbersRule: SwiftSyntaxRule, OptInRule, ConfigurationProviderRule {
    init() {}

    var configuration = SeverityConfiguration(.warning)

    static let description = RuleDescription(
        identifier: "no_magic_numbers",
        name: "No Magic Numbers",
        description: "Magic numbers should be replaced by named constants",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("var foo = 123"),
            Example("static let bar: Double = 0.123"),
            Example("let a = b + 1.0"),
            Example("array[0] + array[1] "),
            Example("let foo = 1_000.000_01"),
            Example("// array[1337]"),
            Example("baz(\"9999\")"),
            Example("""
        func foo() {
            let x: Int = 2
            let y = 3
            let vector = [x, y, -1]
        }
        """),
            Example("""
        class A {
            var foo: Double = 132
            static let bar: Double = 0.98
        }
        """),
            Example("""
        @available(iOS 13, *)
        func version() {
            if #available(iOS 13, OSX 10.10, *) {
                return
            }
        }
        """)
        ],
        triggeringExamples: [
            Example("foo(↓321)"),
            Example("bar(↓1_000.005_01)"),
            Example("array[↓42]"),
            Example("let box = array[↓12 + ↓14]"),
            Example("let a = b + ↓2.0"),
            Example("Color.primary.opacity(isAnimate ? ↓0.1 : ↓1.5)")
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension NoMagicNumbersRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: FloatLiteralExprSyntax) {
            if node.floatingDigits.isMagicNumber {
                self.violations.append(node.floatingDigits.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: IntegerLiteralExprSyntax) {
            if node.digits.isMagicNumber {
                self.violations.append(node.digits.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}

private extension TokenSyntax {
    var isMagicNumber: Bool {
        let numerStr = text.replacingOccurrences(of: "_", with: "")

        guard let number = Double(numerStr),
              ![0, 1].contains(number),
              let parentToken = parent?.parent,
              !parentToken.is(InitializerClauseSyntax.self) else {
            return false
        }
        return true
    }
}
