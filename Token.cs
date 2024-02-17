using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace NesCompiler
{
    public class Token
    {
        public string Type;
        public string Value;

        public Token(string type, string value)
        {
            Type = type;
            Value = value;
        }
    }
}
