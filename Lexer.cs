using System;
using System.Collections.Generic;

namespace NesCompiler
{
    public class Lexer
    {
        private string _text;
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
                if (" \n\r".IndexOf(c) != -1) continue;
                else if (c == '/')
                {
                    // Check for single-line comment
                    if (i < _text.Length - 1 && _text[i + 1] == '/')
                    {
                        // Skip the rest of the line
                        i++;
                        while (i < _text.Length && _text[i] != '\n')
                        {
                            i++;
                        }
                        continue;
                    }
                }
                else if ("()[]{},;:.".IndexOf(c) != -1) // Removed '=' from here
                {
                    result.Add(new Token("" + c, ""));
                }
                else if ("+-*/><=!".IndexOf(c) != -1)
                {
                    bool flag = false;
                    if (i < _text.Length - 1)
                    {
                        var nextChar = _text[i + 1];
                        // Check for two-character operators involving '='
                        if ((c == '=' && nextChar == '=') || // For '=='
                            (c == '!' && nextChar == '=') || // For '!='
                            (c == '>' && (nextChar == '=' || nextChar == '>')) || // For '>=' and '>>'
                            (c == '<' && (nextChar == '=' || nextChar == '<'))) // For '<=' and '<<'
                        {
                            flag = true;
                            i++;
                            result.Add(new Token("operation","" + c + nextChar));
                        }
                    }
                    // This handles the case where '=' is not part of a two-character operator
                    if (!flag)
                    {
                        if ("+-*/<>".IndexOf(c) != -1)
                        {
                            result.Add(new Token("operation", "" + c));
                        }
                        else
                        {
                            result.Add(new Token("" + c, ""));
                        }
                    }
                }
                else if (c == '"')
                {
                    // Find the closing quotation mark and extract the string literal
                    int j = i + 1;
                    while (j < _text.Length && _text[j] != '"')
                    {
                        j++;
                    }
                    if (j >= _text.Length)
                    {
                        // Unterminated string literal
                        // You can throw an exception or handle it in some other way
                        throw new Exception("Unterminated string literal at index " + i);
                    }
                    string stringLiteral = _text.Substring(i + 1, j - i - 1);
                    result.Add(new Token("string", stringLiteral));
                    i = j;
                }
                else if (char.IsDigit(c))
                {
                    // Extract the numeric literal
                    int j = i;
                    while (j < _text.Length && char.IsDigit(_text[j]))
                    {
                        j++;
                    }
                    string numericLiteral = _text.Substring(i, j - i);
                    result.Add(new Token("number", numericLiteral));
                    i = j - 1;
                }
                else if (char.IsLetter(c) || c == '_')
                {
                    int j = i;
                    while (j < _text.Length && (char.IsLetterOrDigit(_text[j]) || _text[j] == '_'))
                    {
                        j++;
                    }
                    string literal = _text.Substring(i, j - i);

                    // Check for boolean literals before adding as a symbol
                    if (literal == "true" || literal == "false")
                    {
                        result.Add(new Token("boolean", literal));
                    }
                    else if (IsType(literal))
                    {
                        result.Add(new Token("type", literal));
                    }
                    else
                    {
                        result.Add(new Token("symbol", literal));
                    }
                    i = j - 1; // Move past the last character of the symbol
                }
                else
                {
                    Console.WriteLine("\\n: " + (int)'\n');
                    Console.WriteLine("Unrecognized character: '" + (int)c + "' at " + i + ", after '" + _text[i - 1] + "'.");
                    throw new Exception("Unrecognized character: '" + c + "'.");
                }

            }
            return result;
        }

        private bool IsType(string literal)
        {
            switch (literal)
            {
                case "byte":
                case "Sprite":
                case "bool":
                    return true;
            }

            return false;
        }
    }
}
