import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct ModifierMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let varDecl = declaration.as(VariableDeclSyntax.self) else {
            return []
        }
        
        guard let binding = varDecl.bindings.first else {
            return []
        }
        
        guard let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
            return []
        }
        
        let functionName = identifier.prefix(1).uppercased() + identifier.dropFirst()
        
        guard let typeAnnotation = binding.typeAnnotation?.type else {
            return []
        }
        
        let modifierDecl = """
            public func \(functionName)(_ \(identifier): \(typeAnnotation)) -> Self {
                var copy = self
                copy.\(identifier) = \(identifier)
                return copy
            }
        """
        
        return [DeclSyntax(stringLiteral: modifierDecl)]
    }
}

@main
struct ModifierMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ModifierMacro.self
    ]
}

