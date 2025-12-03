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
                Console.WriteLine("("+_current + ") " + token.Type + " : " + token.Value);
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
            var typeToken = _tokens[_current++];
            

            bool isArray = _tokens[_current].Type == "["; 
            
            if (isArray)
            {
                node.Children.Add(new AstNode("Type", typeToken.Value + "[]"));
                _current = _current + 2; //skipping []

                var nameToken = _tokens[_current++];
                if (nameToken.Type != "symbol")
                {
                    throw new Exception("Expected variable name in byte declaration but found: " + nameToken.Type + "," + nameToken.Value);
                }
                node.Children.Add(new AstNode("Name", nameToken.Value));


                if (_tokens[_current].Type != "=")
                {
                    throw new Exception("Expected '=' after array declaration");
                }
                _current++; // Skip '='

                if (_tokens[_current].Type != "[")
                {
                    throw new Exception("Expected '[' after '='");
                }
                _current++; // Skip '['

                var sizeNode = new AstNode("Constant", _tokens[_current++].Value);
                node.Children.Add(sizeNode);

                if (_tokens[_current].Type != "]")
                {
                    throw new Exception("Expected ']' after array size");
                }
                _current++; // Skip ']'
            }
            else
            {
                node.Children.Add(new AstNode("Type", typeToken.Value));
                var nameToken = _tokens[_current++];
                if (nameToken.Type != "symbol")
                {
                    throw new Exception("Expected variable name in byte declaration");
                }
                node.Children.Add(new AstNode("Name", nameToken.Value));

                if (_tokens[_current].Type == "=")
                {
                    _current++; // Skip '='
                    node.Children.Add(ParseExpression());
                }
            }

            if (_tokens[_current].Type != ";")
            {
                throw new Exception("Expected ';' after byte declaration");
            }
            _current++; // Skip ';'

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

        private AstNode ParseIfStatement()
        {
            // Expect the current token to be "if", so skip it
            _current++;

            // Parse the condition inside parentheses
            if (_tokens[_current++].Type != "(")
            {
                throw new Exception("Expected '(' after 'if'");
            }

            var condition = ParseExpression();

            if (_tokens[_current++].Type != ")")
            {
                throw new Exception("Expected ')' after if condition");
            }

            // Parse the statement block for the true branch
            var trueBranch = ParseStatementBlock();

            AstNode falseBranch = null;
            // Optionally, handle else statement
            if (_current < _tokens.Count && _tokens[_current].Type == "symbol" && _tokens[_current].Value == "else")
            {
                _current++; // Skip "else"
                falseBranch = ParseStatementBlock();
            }

            var ifNode = new AstNode("IfStatement");
            ifNode.Children.Add(condition);
            ifNode.Children.Add(trueBranch);
            if (falseBranch != null)
            {
                ifNode.Children.Add(falseBranch);
            }

            return ifNode;
        }

        private AstNode ParseWhileStatement()
        {
            // Expect the current token to be "while", so skip it
            _current++;

            // Parse the condition inside parentheses
            if (_tokens[_current++].Type != "(")
            {
                throw new Exception("Expected '(' after 'while'");
            }

            var condition = ParseExpression();

            if (_tokens[_current++].Type != ")")
            {
                throw new Exception("Expected ')' after while condition");
            }

            // Parse the statement block for the loop body
            var body = ParseStatementBlock();

            var whileNode = new AstNode("WhileStatement");
            whileNode.Children.Add(condition);
            whileNode.Children.Add(body);

            return whileNode;
        }

        private AstNode ParseStatementBlock()
        {
            if (_tokens[_current].Type != "{")
            {
                throw new Exception("Expected '{' at the beginning of a block");
            }
            _current++;

            var blockNode = new AstNode("Block");
            while (_current < _tokens.Count && _tokens[_current].Type != "}")
            {
                var statement = ParseStatement();
                blockNode.Children.Add(statement);
            }

            if (_tokens[_current].Type != "}")
            {
                throw new Exception("Expected '}' at the end of a block");
            }
            _current++;

            return blockNode;
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
            var token = _tokens[_current];
            AstNode node;

            // Check if the statement is an 'if' statement
            if (token.Type == "symbol" && token.Value == "if")
            {
                node = ParseIfStatement();
                // For 'if' statements, the ParseIfStatement method handles the block and semicolon,
                // so we don't expect a semicolon immediately after it.
            }
            else if (token.Type == "symbol" && token.Value == "while")
            {
                node = ParseWhileStatement();
            }
            else if (token.Type == "symbol" && token.Value == "return")
            {
                // 'return' statement should end with a semicolon, which is handled inside ParseReturnStatement
                node = ParseReturnStatement();
                ExpectSemicolon(); // Checks for and consumes the semicolon, advancing _current
            }
            else
            {
                // This handles expression statements and expects them to end with a semicolon.
                node = ParseExpressionStatement();
                ExpectSemicolon(); // Checks for and consumes the semicolon, advancing _current
            }

            return node;
        }

        private void ExpectSemicolon()
        {
            if (_tokens[_current].Type != ";")
            {
                throw new Exception("Expected ';'" + " found: " + _tokens[_current].Type + " : " + _tokens[_current].Value);
            }
            _current++; // Consume the semicolon and move to the next token
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
                    while (_tokens[_current].Type == "operation" && ("+-*/!==>=<=").Contains(_tokens[_current].Value))
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
            AstNode node = null;

            switch (token.Type)
            {
                case "number":
                    _current++;
                    node = new AstNode("Constant", token.Value);
                    break;
                case "boolean": // Handle boolean literals
                    _current++;
                    node = new AstNode("Boolean", token.Value);
                    break;
                case "symbol":
                    _current++;
                    node = new AstNode("Identifier", token.Value);
                    break;
                default:
                    throw new Exception($"Unexpected token: {token.Type}");
            }

            // Проверка на последующий доступ к члену или вызов функции
            while (_current < _tokens.Count && (_tokens[_current].Type == "." || _tokens[_current].Type == "(" || _tokens[_current].Type == "["))
            {
                if (_tokens[_current].Type == ".")
                {
                    _current++; // Пропустить '.'
                    var memberToken = Expect("symbol"); // Ожидаем следующий символ как имя члена
                                                                // Создаем узел доступа к члену и добавляем текущий узел и узел идентификатора как детей
                    var memberAccessNode = new AstNode("MemberAccess");
                    memberAccessNode.Children.Add(node); // Добавляем базовый узел
                    memberAccessNode.Children.Add(new AstNode("Identifier", memberToken.Value)); // Добавляем узел идентификатора члена
                    node = memberAccessNode; // Обновляем текущий узел
                }
                else if (_tokens[_current].Type == "(")
                {
                    // Для обработки вызова функции нам нужно адаптировать ParseFunctionCall,
                    // чтобы он мог принять текущий узел как часть вызова
                    node = ParseFunctionCall(node);
                    // Поскольку ParseFunctionCall уже продвигает _current, не нужно увеличивать его здесь
                }
                else if (_tokens[_current].Type == "[")
                {
                    _current++; // Пропустить '['
                    var indexExpression = ParseExpression(); // Обрабатываем выражение индекса
                    if (_tokens[_current].Type != "]")
                    {
                        throw new Exception("Expected ']' after array index");
                    }
                    _current++; // Пропустить ']'

                    // Создаем узел ArrayAccess и обновляем node
                    var arrayAccessNode = new AstNode("ArrayAccess");
                    arrayAccessNode.Children.Add(node); // Добавляем текущий узел (например, идентификатор массива)
                    arrayAccessNode.Children.Add(indexExpression); // Добавляем выражение индекса
                    node = arrayAccessNode;
                }
            }

            return node;
        }

        private Token Expect(string expectedType)
        {
            if (_current >= _tokens.Count)
            {
                throw new Exception("Unexpected end of input");
            }

            var currentToken = _tokens[_current];
            if (currentToken.Type != expectedType)
            {
                throw new Exception($"Expected token of type {expectedType}, but found {currentToken.Type}");
            }

            _current++; // Переходим к следующему токену
            return currentToken; // Возвращаем текущий токен
        }


        private AstNode ParseFunctionCall(AstNode functionOrIdentifierNode)
        {
            // Считаем, что _current уже указывает на '(', поэтому пропускаем его
            _current++;
            var args = new List<AstNode>();
            while (_tokens[_current].Type != ")")
            {
                args.Add(ParseExpression());
                if (_tokens[_current].Type == ",") _current++; // Пропускаем запятую между аргументами
            }
            _current++; // Пропускаем закрывающую скобку ')'

            var functionCallNode = new AstNode("FunctionCall");
            functionCallNode.Children.Add(functionOrIdentifierNode); // Добавляем узел функции или идентификатора как первого ребенка
            foreach (var arg in args)
            {
                functionCallNode.Children.Add(arg); // Добавляем аргументы вызова функции
            }
            return functionCallNode;
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