using System;
using System.Collections.Generic;

namespace NesCompiler
{
    public class Parser
    {
        private List<Token> _tokens;
        private int _current;

        public Parser(List<Token> tokens)
        {
            _tokens = tokens;
            _current = 0;
        }

        public AstNode Parse()
        {
            var root = new AstNode("root");

            while (_current < _tokens.Count)
            {
                var token = _tokens[_current];
                Console.WriteLine(token.Type + " : " + token.Value);
                switch (token.Type)
                {
                    case "symbol":
                        if (token.Value == "void")
                        {
                            root.Children.Add(ParseFunctionDeclaration());
                        }
                        else
                        {
                            throw new Exception("Unrecognized symbol: " + token.Value);
                        }
                        break;
                    case "type":
                        if (token.Value == "byte")
                        {
                            root.Children.Add(ParseByteDeclaration());
                        } else if(token.Value == "Sprite")
                        {
                            root.Children.Add(ParseSpriteDeclaration());
                        }
                        break;
                    default:
                        throw new Exception("Unexpected token: " + token.Type);
                }
            }

            return root;
        }

        private AstNode ParseByteDeclaration()
        {
            var node = new AstNode("ByteDeclaration");
            node.Children.Add(new AstNode("Byte", _tokens[_current++].Value));

            node.Children.Add(new AstNode("Name", _tokens[_current++].Value));

            var token = _tokens[_current++];

            if(token.Type == "=")
            {
                //TODO parse expression
                node.Children.Add(ParseExpression());

            }

            token = _tokens[_current++];

            if (token.Type == ";")
            {

            } else
            {
                throw new Exception("= or ; expected in byte declaration");
            }

            return node;
        }

        private AstNode ParseSpriteDeclaration()
        {

            var node = new AstNode("SpriteDeclaration");
            node.Children.Add(new AstNode("Sprite", _tokens[_current++].Value));

            node.Children.Add(new AstNode("Name", _tokens[_current++].Value));

            var token = _tokens[_current++];

            if (token.Type == "=")
            {
                //TODO parse expression
                node.Children.Add(ParseExpression());

                token = _tokens[_current++];
            }


            if (token.Type == ";")
            {

            }
            else
            {
                throw new Exception("= or ; expected in sprite declaration");
            }

            return node;
        }

        private AstNode ParseFunctionDeclaration()
        {
            // Parse "void"
            var node = new AstNode("FunctionDeclaration");
            node.Children.Add(new AstNode("void", _tokens[_current++].Value));

            // Parse function name
            node.Children.Add(new AstNode("Name", _tokens[_current++].Value));

            // Parse "("
            if (_tokens[_current++].Type != "(")
            {
                throw new Exception("Expected '('");
            }

            // Parse function parameters (optional)
            //if (_tokens[_current].Type != ")")
            {
                node.Children.Add(ParseFunctionParameters());
            }

            // Parse ")"
            if (_tokens[_current++].Type != ")")
            {
                throw new Exception("Expected ')'");
            }

            // Parse function body
            node.Children.Add(ParseFunctionBody());

            return node;
        }

        private AstNode ParseFunctionParameters()
        {
            // Parse function parameter list
            var node = new AstNode("FunctionParameters");
            
            while (_tokens[_current].Type != ")")
            {
                // Parse parameter type
                node.Children.Add(new AstNode("Type", _tokens[_current++].Value));

                // Parse parameter name
                node.Children.Add(new AstNode("Name", _tokens[_current++].Value));

                if (_tokens[_current].Value == ",")
                {
                    _current++;
                }
            }

            return node;
        }

        private AstNode ParseFunctionBody()
        {
            // Parse "{"
            if (_tokens[_current++].Type != "{")
            {
                throw new Exception("Expected '{'");
            }

            // Parse function statements
            var node = new AstNode("FunctionBody");
            while (_tokens[_current].Type != "}")
            {
                node.Children.Add(ParseStatement());
            }

            // Parse "}"
            if (_tokens[_current++].Type != "}")
            {
                throw new Exception("Expected '}'");
            }

            return node;
        }

        private AstNode ParseStatement()
        {
            // Parse statement
            var token = _tokens[_current];
            AstNode node;
            if (token.Type == "symbol")
            {
                if (token.Value == "return")
                {
                    node = ParseReturnStatement();
                }
                else
                {
                    node = ParseExpressionStatement();
                }
            }
            else
            {
                node = ParseExpressionStatement();
            }

            // Parse ";"
            if (_tokens[_current++].Type != ";")
            {
                throw new Exception("Expected ';'" + " found: " + _tokens[_current-1].Type + " : " + _tokens[_current - 1].Value);
            }

            return node;
        }

        private AstNode ParseReturnStatement()
        {
            // Parse "return"
            var node = new AstNode("Return Statement");
            node.Children.Add(new AstNode("return", _tokens[_current++].Value));

            // Parse return value (optional)
            if (_tokens[_current].Value != ";")
            {
                node.Children.Add(ParseExpression());
            }

            return node;
        }

        private AstNode ParseExpressionStatement()
        {
            // Parse expression
            var node = new AstNode("Expression Statement");
            node.Children.Add(ParseExpression());

            return node;
        }

        private AstNode ParseExpression()
        {
            var node = new AstNode("Expression");

            // Check if the current token is a variable declaration
            if (_tokens[_current].Type == "type")
            {
                node.Children.Add(new AstNode("Declaration", _tokens[_current].Value));
                _current++;

                // Check if the next token is a variable name
                if (_tokens[_current].Type == "symbol")
                {
                    node.Children.Add(new AstNode("Identifier", _tokens[_current].Value));
                    _current++;
                }
                else
                {
                    // Throw an error if the next token is not a variable name
                    throw new Exception("Expected identifier after type in declaration");
                }

                // Check if the next token is an assignment operator
                if (_tokens[_current].Type == "=")
                {
                    // Add an assignment node and its children
                    var assignment = new AstNode("Assignment");
                    assignment.Children.Add(new AstNode("Identifier", _tokens[_current - 1].Value));
                    _current++;
                    assignment.Children.Add(ParseExpression());
                    node.Children.Add(assignment);
                }
                else if (_tokens[_current].Type != ";")
                {
                    // Throw an error if the next token is not an assignment operator or a semicolon
                    throw new Exception("Expected = or ; after identifier in declaration");
                }
            }
            else
            {
                // Parse an expression that is not a variable declaration
                var termNode = ParseTerm();

                // Check if the current token is an assignment operator
                if (_tokens[_current].Type == "=")
                {
                    // Add an assignment node and its children
                    var assignment = new AstNode("Assignment");
                    assignment.Children.Add(termNode);
                    _current++;
                    assignment.Children.Add(ParseExpression());
                    node.Children.Add(assignment);
                }
                else
                {
                    // Parse a binary operation
                    while (_tokens[_current].Type == "operation" && (_tokens[_current].Value == "+"))
                    {
                        var operation = new AstNode("Operation", _tokens[_current++].Value);
                        var leftExpression = new AstNode("Expression");
                        var rightExpression = new AstNode("Expression");
                        operation.Children.Add(leftExpression); leftExpression.Children.Add(termNode);
                        operation.Children.Add(rightExpression); rightExpression.Children.Add(ParseTerm());
                        termNode = operation;
                    }

                    // Add the final operation or term to the expression node
                    node.Children.Add(termNode);
                }
            }

            return node;
        }



        private AstNode ParseTerm()
        {
            var token = _tokens[_current];
            if (token.Type == "number")
            {
                _current++;
                return new AstNode("Constant", token.Value);
            }
            else if (token.Type == "symbol")
            {
                _current++;
                var identifierOrNot = new AstNode("Identifier", token.Value);
                if (_tokens[_current].Type == ".")
                {
                    var memberAccess = new AstNode("MemberAccess");
                    ++_current;
                    if(_tokens[_current].Type == "symbol")
                    {
                        var member = new AstNode("Member", _tokens[_current].Value);
                        ++_current;
                        memberAccess.Children.Add(identifierOrNot);
                        memberAccess.Children.Add(member);
                        return memberAccess;
                    } else
                    {
                        throw new Exception("Expected member");
                    }
                } else if(_tokens[_current].Type == "(")
                {
                    --_current;
                    return ParseFunctionCall();
                }
                return identifierOrNot;
            }
            else
            {
                throw new Exception("Expected number or symbol");
            }
        }

        private AstNode ParseFunctionCall()
        {
            var node = new AstNode("FunctionCall");
            // Parse function name
            node.Children.Add(new AstNode("Name", _tokens[_current++].Value));
            // Parse "("
            if (_tokens[_current++].Type != "(")
            {
                throw new Exception("Expected '('");
            }
            // Parse function arguments
            node.Children.Add(ParseFunctionArguments());
            // Parse ")"
            if (_tokens[_current++].Type != ")")
            {
                throw new Exception("Expected ')'");
            }
            return node;
        }

        private AstNode ParseFunctionArguments()
        {
            var node = new AstNode("FunctionArguments");
            while (_tokens[_current].Type != ")")
            {
                node.Children.Add(ParseExpression());
                if (_tokens[_current].Type == ",")
                {
                    _current++;
                }
            }
            return node;
        }

        public void PrintAst(AstNode node, int level)
        {
            // Print the current node
            Console.WriteLine(new string(' ', level * 2) + node.Type + " (" + node.Value + ")");

            // Print the children of the current node
            foreach (var child in node.Children)
            {
                PrintAst(child, level + 1);
            }
        }
    }

    public class AstNode
    {
        public string Type;
        public string Value;
        public List<AstNode> Children;

        public AstNode(string type, string value = "")
        {
            Type = type;
            Value = value;
            Children = new List<AstNode>();
        }
    }
}