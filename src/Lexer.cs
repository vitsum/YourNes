using System;
using System.Collections.Generic;

namespace NesCompiler
{
    public class Lexer
    {
        private readonly string _text;

        private static readonly Dictionary<char, TokenType> SingleCharTokens = new()
        {
            { '(', TokenType.OpenParen },
            { ')', TokenType.CloseParen },
            { '[', TokenType.OpenBracket },
            { ']', TokenType.CloseBracket },
            { '{', TokenType.OpenBrace },
            { '}', TokenType.CloseBrace },
            { ',', TokenType.Comma },
            { ';', TokenType.Semicolon },
            { ':', TokenType.Colon },
            { '.', TokenType.Dot },
        };

        private static readonly HashSet<string> TypeKeywords = new() { "byte", "Sprite", "bool" };

        public Lexer(string text)
        {
            _text = text;
        }

        public List<Token> Process()
        {
            var result = new List<Token>();
            for (int i = 0; i < _text.Length; i++)
            {
                var c = _text[i];

                if (char.IsWhiteSpace(c))
                    continue;

                if (c == '/')
                {
                    if (i < _text.Length - 1 && _text[i + 1] == '/')
                    {
                        i++;
                        while (i < _text.Length && _text[i] != '\n')
                            i++;
                        continue;
                    }
                }

                if (SingleCharTokens.TryGetValue(c, out var singleCharType))
                {
                    result.Add(new Token(singleCharType));
                    continue;
                }

                if ("+-*/><=!".IndexOf(c) != -1)
                {
                    bool twoChar = false;
                    if (i < _text.Length - 1)
                    {
                        var next = _text[i + 1];
                        if ((c == '=' && next == '=') ||
                            (c == '!' && next == '=') ||
                            (c == '>' && (next == '=' || next == '>')) ||
                            (c == '<' && (next == '=' || next == '<')))
                        {
                            twoChar = true;
                            i++;
                            result.Add(new Token(TokenType.Operation, "" + c + next));
                        }
                    }
                    if (!twoChar)
                    {
                        if ("+-*/<>".IndexOf(c) != -1)
                            result.Add(new Token(TokenType.Operation, "" + c));
                        else if (c == '=')
                            result.Add(new Token(TokenType.Equals));
                        else
                            result.Add(new Token(TokenType.Exclamation));
                    }
                    continue;
                }

                if (c == '"')
                {
                    int j = i + 1;
                    while (j < _text.Length && _text[j] != '"')
                        j++;
                    if (j >= _text.Length)
                        throw new Exception("Unterminated string literal at index " + i);
                    result.Add(new Token(TokenType.String, _text.Substring(i + 1, j - i - 1)));
                    i = j;
                    continue;
                }

                if (char.IsDigit(c))
                {
                    int j = i;
                    while (j < _text.Length && char.IsDigit(_text[j]))
                        j++;
                    result.Add(new Token(TokenType.Number, _text.Substring(i, j - i)));
                    i = j - 1;
                    continue;
                }

                if (char.IsLetter(c) || c == '_')
                {
                    int j = i;
                    while (j < _text.Length && (char.IsLetterOrDigit(_text[j]) || _text[j] == '_'))
                        j++;
                    string literal = _text.Substring(i, j - i);

                    if (literal == "true" || literal == "false")
                        result.Add(new Token(TokenType.Boolean, literal));
                    else if (TypeKeywords.Contains(literal))
                        result.Add(new Token(TokenType.Type, literal));
                    else
                        result.Add(new Token(TokenType.Symbol, literal));

                    i = j - 1;
                    continue;
                }

                throw new Exception($"Unrecognized character: '{c}' at position {i}.");
            }
            return result;
        }
    }
}
