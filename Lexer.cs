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
                else if ("(){},;=:.".IndexOf(c) != -1) result.Add(new Token("" + c, ""));
                else if ("+-*/".IndexOf(c) != -1)
                {
                    bool flag = false;
                    if("+-".IndexOf(c) != -1 && i < _text.Length - 1)
                    {
                        var n = _text[i + 1];
                        if(n == c)
                        {
                            flag = true;
                            i++;
                            result.Add(new Token("" + c + n, ""));
                        }
                    }
                    if (!flag)
                    {
                        result.Add(new Token("operation", "" + c));
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
                    // Extract the symbolic literal
                    int j = i;
                    while (j < _text.Length && (char.IsLetterOrDigit(_text[j]) || _text[j] == '_'))
                    {
                        j++;
                    }
                    string symbolicLiteral = _text.Substring(i, j - i);
                    if (symbolicLiteral == "byte" || symbolicLiteral == "Sprite")
                    {
                        result.Add(new Token("type", symbolicLiteral));
                        i = j - 1;
                        continue;
                    }
                    result.Add(new Token("symbol", symbolicLiteral));
                    i = j - 1;
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
    }
}
