using System;
using System.Collections.Generic;

namespace NesCompiler
{
    public class Parser
    {
        private readonly List<Token> _tokens;
        private int _current;

        public Parser(List<Token> tokens)
        {
            _tokens = tokens;
            _current = 0;
        }

        public AstNode Parse()
        {
            var root = new AstNode(NodeType.Root);

            while (_current < _tokens.Count)
            {
                var token = _tokens[_current];
                Console.WriteLine($"({_current}) {token.Type} : {token.Value}");

                switch (token.Type)
                {
                    case TokenType.Symbol:
                        if (token.Value == "void")
                            root.Children.Add(ParseFunctionDeclaration());
                        else
                            throw new Exception("Unrecognized symbol: " + token.Value);
                        break;
                    case TokenType.Type:
                        if (token.Value == "byte")
                            root.Children.Add(ParseByteDeclaration());
                        else if (token.Value == "Sprite")
                            root.Children.Add(ParseSpriteDeclaration());
                        break;
                    default:
                        throw new Exception("Unexpected token: " + token.Type);
                }
            }

            return root;
        }

        private AstNode ParseByteDeclaration()
        {
            var node = new AstNode(NodeType.ByteDeclaration);
            var typeToken = _tokens[_current++];

            bool isArray = _tokens[_current].Type == TokenType.OpenBracket;

            if (isArray)
            {
                node.Children.Add(new AstNode(NodeType.Type, typeToken.Value + "[]"));
                _current += 2; // skip []

                var nameToken = Expect(TokenType.Symbol);
                node.Children.Add(new AstNode(NodeType.Name, nameToken.Value));

                if (_tokens[_current].Type != TokenType.Equals)
                    throw new Exception("Expected '=' after array declaration");
                _current++;

                if (_tokens[_current].Type != TokenType.OpenBracket)
                    throw new Exception("Expected '[' after '='");
                _current++;

                node.Children.Add(new AstNode(NodeType.Constant, _tokens[_current++].Value));

                if (_tokens[_current].Type != TokenType.CloseBracket)
                    throw new Exception("Expected ']' after array size");
                _current++;
            }
            else
            {
                node.Children.Add(new AstNode(NodeType.Type, typeToken.Value));

                var nameToken = Expect(TokenType.Symbol);
                node.Children.Add(new AstNode(NodeType.Name, nameToken.Value));

                if (_tokens[_current].Type == TokenType.Equals)
                {
                    _current++;
                    node.Children.Add(ParseExpression());
                }
            }

            ExpectSemicolon();
            return node;
        }

        private AstNode ParseSpriteDeclaration()
        {
            var node = new AstNode(NodeType.SpriteDeclaration);
            node.Children.Add(new AstNode(NodeType.Sprite, _tokens[_current++].Value));
            node.Children.Add(new AstNode(NodeType.Name, _tokens[_current++].Value));

            var token = _tokens[_current++];

            if (token.Type == TokenType.Equals)
            {
                node.Children.Add(ParseExpression());
                token = _tokens[_current++];
            }

            if (token.Type != TokenType.Semicolon)
                throw new Exception("= or ; expected in sprite declaration");

            return node;
        }

        private AstNode ParseIfStatement()
        {
            _current++; // skip "if"

            if (_tokens[_current++].Type != TokenType.OpenParen)
                throw new Exception("Expected '(' after 'if'");

            var condition = ParseExpression();

            if (_tokens[_current++].Type != TokenType.CloseParen)
                throw new Exception("Expected ')' after if condition");

            var trueBranch = ParseStatementBlock();

            AstNode falseBranch = null;
            if (_current < _tokens.Count &&
                _tokens[_current].Type == TokenType.Symbol &&
                _tokens[_current].Value == "else")
            {
                _current++;
                falseBranch = ParseStatementBlock();
            }

            var ifNode = new AstNode(NodeType.IfStatement);
            ifNode.Children.Add(condition);
            ifNode.Children.Add(trueBranch);
            if (falseBranch != null)
                ifNode.Children.Add(falseBranch);

            return ifNode;
        }

        private AstNode ParseWhileStatement()
        {
            _current++; // skip "while"

            if (_tokens[_current++].Type != TokenType.OpenParen)
                throw new Exception("Expected '(' after 'while'");

            var condition = ParseExpression();

            if (_tokens[_current++].Type != TokenType.CloseParen)
                throw new Exception("Expected ')' after while condition");

            var body = ParseStatementBlock();

            var whileNode = new AstNode(NodeType.WhileStatement);
            whileNode.Children.Add(condition);
            whileNode.Children.Add(body);

            return whileNode;
        }

        private AstNode ParseStatementBlock()
        {
            if (_tokens[_current].Type != TokenType.OpenBrace)
                throw new Exception("Expected '{' at the beginning of a block");
            _current++;

            var blockNode = new AstNode(NodeType.Block);
            while (_current < _tokens.Count && _tokens[_current].Type != TokenType.CloseBrace)
                blockNode.Children.Add(ParseStatement());

            if (_tokens[_current].Type != TokenType.CloseBrace)
                throw new Exception("Expected '}' at the end of a block");
            _current++;

            return blockNode;
        }

        private AstNode ParseFunctionDeclaration()
        {
            var node = new AstNode(NodeType.FunctionDeclaration);
            node.Children.Add(new AstNode(NodeType.Void, _tokens[_current++].Value));
            node.Children.Add(new AstNode(NodeType.Name, _tokens[_current++].Value));

            if (_tokens[_current++].Type != TokenType.OpenParen)
                throw new Exception("Expected '('");

            node.Children.Add(ParseFunctionParameters());

            if (_tokens[_current++].Type != TokenType.CloseParen)
                throw new Exception("Expected ')'");

            node.Children.Add(ParseFunctionBody());

            return node;
        }

        private AstNode ParseFunctionParameters()
        {
            var node = new AstNode(NodeType.FunctionParameters);

            while (_tokens[_current].Type != TokenType.CloseParen)
            {
                node.Children.Add(new AstNode(NodeType.Type, _tokens[_current++].Value));
                node.Children.Add(new AstNode(NodeType.Name, _tokens[_current++].Value));

                if (_tokens[_current].Type == TokenType.Comma)
                    _current++;
            }

            return node;
        }

        private AstNode ParseFunctionBody()
        {
            if (_tokens[_current++].Type != TokenType.OpenBrace)
                throw new Exception("Expected '{'");

            var node = new AstNode(NodeType.FunctionBody);
            while (_tokens[_current].Type != TokenType.CloseBrace)
                node.Children.Add(ParseStatement());

            if (_tokens[_current++].Type != TokenType.CloseBrace)
                throw new Exception("Expected '}'");

            return node;
        }

        private AstNode ParseStatement()
        {
            var token = _tokens[_current];

            if (token.Type == TokenType.Symbol && token.Value == "if")
                return ParseIfStatement();

            if (token.Type == TokenType.Symbol && token.Value == "while")
                return ParseWhileStatement();

            if (token.Type == TokenType.Symbol && token.Value == "return")
            {
                var node = ParseReturnStatement();
                ExpectSemicolon();
                return node;
            }

            var exprStmt = ParseExpressionStatement();
            ExpectSemicolon();
            return exprStmt;
        }

        private void ExpectSemicolon()
        {
            if (_tokens[_current].Type != TokenType.Semicolon)
                throw new Exception($"Expected ';' found: {_tokens[_current].Type} : {_tokens[_current].Value}");
            _current++;
        }

        private Token Expect(TokenType expectedType)
        {
            if (_current >= _tokens.Count)
                throw new Exception("Unexpected end of input");

            var currentToken = _tokens[_current];
            if (currentToken.Type != expectedType)
                throw new Exception($"Expected token of type {expectedType}, but found {currentToken.Type}");

            _current++;
            return currentToken;
        }

        private AstNode ParseReturnStatement()
        {
            var node = new AstNode(NodeType.ReturnStatement);
            node.Children.Add(new AstNode(NodeType.Return, _tokens[_current++].Value));

            if (_tokens[_current].Type != TokenType.Semicolon)
                node.Children.Add(ParseExpression());

            return node;
        }

        private AstNode ParseExpressionStatement()
        {
            var node = new AstNode(NodeType.ExpressionStatement);
            node.Children.Add(ParseExpression());
            return node;
        }

        private AstNode ParseExpression()
        {
            var node = new AstNode(NodeType.Expression);

            if (_tokens[_current].Type == TokenType.Type)
            {
                node.Children.Add(new AstNode(NodeType.Declaration, _tokens[_current].Value));
                _current++;

                if (_tokens[_current].Type != TokenType.Symbol)
                    throw new Exception("Expected identifier after type in declaration");

                node.Children.Add(new AstNode(NodeType.Identifier, _tokens[_current].Value));
                _current++;

                if (_tokens[_current].Type == TokenType.Equals)
                {
                    var assignment = new AstNode(NodeType.Assignment);
                    assignment.Children.Add(new AstNode(NodeType.Identifier, _tokens[_current - 1].Value));
                    _current++;
                    assignment.Children.Add(ParseExpression());
                    node.Children.Add(assignment);
                }
                else if (_tokens[_current].Type != TokenType.Semicolon)
                {
                    throw new Exception("Expected = or ; after identifier in declaration");
                }
            }
            else
            {
                var termNode = ParseTerm();

                if (_tokens[_current].Type == TokenType.Equals)
                {
                    var assignment = new AstNode(NodeType.Assignment);
                    assignment.Children.Add(termNode);
                    _current++;
                    assignment.Children.Add(ParseExpression());
                    node.Children.Add(assignment);
                }
                else
                {
                    while (_tokens[_current].Type == TokenType.Operation)
                    {
                        var operation = new AstNode(NodeType.Operation, _tokens[_current++].Value);
                        var leftExpression = new AstNode(NodeType.Expression);
                        var rightExpression = new AstNode(NodeType.Expression);
                        leftExpression.Children.Add(termNode);
                        rightExpression.Children.Add(ParseTerm());
                        operation.Children.Add(leftExpression);
                        operation.Children.Add(rightExpression);
                        termNode = operation;
                    }
                    node.Children.Add(termNode);
                }
            }

            return node;
        }

        private AstNode ParseTerm()
        {
            var token = _tokens[_current];
            AstNode node;

            switch (token.Type)
            {
                case TokenType.Number:
                    _current++;
                    node = new AstNode(NodeType.Constant, token.Value);
                    break;
                case TokenType.Boolean:
                    _current++;
                    node = new AstNode(NodeType.Boolean, token.Value);
                    break;
                case TokenType.Symbol:
                    _current++;
                    node = new AstNode(NodeType.Identifier, token.Value);
                    break;
                default:
                    throw new Exception($"Unexpected token: {token.Type}");
            }

            // Check for member access, function call, or array index
            while (_current < _tokens.Count &&
                   (_tokens[_current].Type == TokenType.Dot ||
                    _tokens[_current].Type == TokenType.OpenParen ||
                    _tokens[_current].Type == TokenType.OpenBracket))
            {
                if (_tokens[_current].Type == TokenType.Dot)
                {
                    _current++;
                    var memberToken = Expect(TokenType.Symbol);
                    var memberAccessNode = new AstNode(NodeType.MemberAccess);
                    memberAccessNode.Children.Add(node);
                    memberAccessNode.Children.Add(new AstNode(NodeType.Identifier, memberToken.Value));
                    node = memberAccessNode;
                }
                else if (_tokens[_current].Type == TokenType.OpenParen)
                {
                    node = ParseFunctionCall(node);
                }
                else if (_tokens[_current].Type == TokenType.OpenBracket)
                {
                    _current++;
                    var indexExpression = ParseExpression();
                    if (_tokens[_current].Type != TokenType.CloseBracket)
                        throw new Exception("Expected ']' after array index");
                    _current++;

                    var arrayAccessNode = new AstNode(NodeType.ArrayAccess);
                    arrayAccessNode.Children.Add(node);
                    arrayAccessNode.Children.Add(indexExpression);
                    node = arrayAccessNode;
                }
            }

            return node;
        }

        private AstNode ParseFunctionCall(AstNode functionNode)
        {
            _current++; // skip '('
            var args = new List<AstNode>();
            while (_tokens[_current].Type != TokenType.CloseParen)
            {
                args.Add(ParseExpression());
                if (_tokens[_current].Type == TokenType.Comma)
                    _current++;
            }
            _current++; // skip ')'

            var functionCallNode = new AstNode(NodeType.FunctionCall);
            functionCallNode.Children.Add(functionNode);
            foreach (var arg in args)
                functionCallNode.Children.Add(arg);
            return functionCallNode;
        }

        public void PrintAst(AstNode node, int level)
        {
            Console.WriteLine(new string(' ', level * 2) + node.Type + " (" + node.Value + ")");
            foreach (var child in node.Children)
                PrintAst(child, level + 1);
        }
    }
}
