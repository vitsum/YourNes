using System.Collections.Generic;

namespace NesCompiler
{
    public static class NodeType
    {
        public const string Root = "Root";
        public const string FunctionDeclaration = "FunctionDeclaration";
        public const string FunctionParameters = "FunctionParameters";
        public const string FunctionBody = "FunctionBody";
        public const string FunctionCall = "FunctionCall";
        public const string ByteDeclaration = "ByteDeclaration";
        public const string SpriteDeclaration = "SpriteDeclaration";
        public const string Block = "Block";
        public const string IfStatement = "IfStatement";
        public const string WhileStatement = "WhileStatement";
        public const string ReturnStatement = "ReturnStatement";
        public const string ExpressionStatement = "ExpressionStatement";
        public const string Expression = "Expression";
        public const string Assignment = "Assignment";
        public const string Operation = "Operation";
        public const string MemberAccess = "MemberAccess";
        public const string ArrayAccess = "ArrayAccess";
        public const string Identifier = "Identifier";
        public const string Constant = "Constant";
        public const string Boolean = "Boolean";
        public const string Type = "Type";
        public const string Name = "Name";
        public const string Declaration = "Declaration";
        public const string Void = "Void";
        public const string Return = "Return";
        public const string Length = "Length";
        public const string Sprite = "Sprite";
    }

    public class AstNode
    {
        public string Type { get; }
        public string Value { get; }
        public List<AstNode> Children { get; }

        public AstNode(string type, string value = "")
        {
            Type = type;
            Value = value;
            Children = new List<AstNode>();
        }
    }
}
