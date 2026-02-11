namespace NesCompiler
{
    public enum TokenType
    {
        Symbol,
        Number,
        String,
        Boolean,
        Type,
        Operation,

        // Single-character tokens
        OpenParen,    // (
        CloseParen,   // )
        OpenBracket,  // [
        CloseBracket, // ]
        OpenBrace,    // {
        CloseBrace,   // }
        Comma,        // ,
        Semicolon,    // ;
        Colon,        // :
        Dot,          // .
        Equals,       // =
        Exclamation,  // !
    }

    public class Token
    {
        public TokenType Type { get; }
        public string Value { get; }

        public Token(TokenType type, string value = "")
        {
            Type = type;
            Value = value;
        }
    }
}
