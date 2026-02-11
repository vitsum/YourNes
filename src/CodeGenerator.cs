using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;

namespace NesCompiler
{
    public class CodeGenerator
    {
        private readonly AstNode _root;
        private StringBuilder _currentSb;
        private readonly StringBuilder _zeroPageSb;
        private readonly StringBuilder _startMethodSb;
        private readonly StringBuilder _updateMethodSb;
        private readonly StringBuilder _codeSb;
        private readonly Dictionary<string, string> _symbolTable;
        private int _labelCounter;
        private readonly string _templateCode;

        private static readonly Dictionary<string, int> SpriteFieldOffsets = new()
        {
            { "Y", 0 },
            { "Tile", 1 },
            { "Attribute", 2 },
            { "X", 3 },
        };

        private static readonly Dictionary<string, string> KeyCodeMap = new()
        {
            { "KeyCode.Player1.Right", "BTN_RIGHT" },
            { "KeyCode.Player1.Left", "BTN_LEFT" },
            { "KeyCode.Player1.Down", "BTN_DOWN" },
            { "KeyCode.Player1.Up", "BTN_UP" },
            { "KeyCode.Player1.Start", "BTN_START" },
            { "KeyCode.Player1.Select", "BTN_SELECT" },
            { "KeyCode.Player1.B", "BTN_B" },
            { "KeyCode.Player1.A", "BTN_A" },
        };

        public CodeGenerator(AstNode root, string templateFile)
        {
            _root = root;
            _codeSb = new StringBuilder();
            _zeroPageSb = new StringBuilder();
            _startMethodSb = new StringBuilder();
            _updateMethodSb = new StringBuilder();
            _currentSb = _codeSb;
            _symbolTable = new Dictionary<string, string>();
            _labelCounter = 0;
            _templateCode = File.ReadAllText(templateFile);
        }

        public string Generate()
        {
            GenerateNode(_root);
            return string.Format(_templateCode, _zeroPageSb, _startMethodSb, _updateMethodSb);
        }

        private void GenerateNode(AstNode node)
        {
            switch (node.Type)
            {
                case NodeType.Root:
                    foreach (var child in node.Children)
                        GenerateNode(child);
                    break;
                case NodeType.FunctionDeclaration:
                    GenerateFunctionDeclaration(node);
                    break;
                case NodeType.ByteDeclaration:
                    WithSb(_zeroPageSb, () => GenerateByteDeclaration(node));
                    break;
                case NodeType.SpriteDeclaration:
                    WithSb(_zeroPageSb, () => GenerateSpriteDeclaration(node));
                    break;
                case NodeType.Expression:
                    GenerateExpression(node);
                    break;
                case NodeType.Block:
                case NodeType.FunctionBody:
                    foreach (var child in node.Children)
                        GenerateNode(child);
                    break;
                case NodeType.ExpressionStatement:
                    GenerateExpression(node.Children[0]);
                    break;
                case NodeType.IfStatement:
                    GenerateIfStatement(node);
                    break;
                case NodeType.WhileStatement:
                    GenerateWhileStatement(node);
                    break;
                default:
                    throw new Exception("Unrecognized node type: " + node.Type);
            }
        }

        /// <summary>
        /// Temporarily switches _currentSb to the given StringBuilder, runs the action, then restores it.
        /// </summary>
        private void WithSb(StringBuilder sb, Action action)
        {
            var previous = _currentSb;
            _currentSb = sb;
            action();
            _currentSb = previous;
        }

        private void GenerateFunctionDeclaration(AstNode node)
        {
            var functionName = node.Children[1].Value;
            bool isSpecialFunction = functionName == "Start" || functionName == "Update";

            if (functionName == "Start")
                _currentSb = _startMethodSb;
            else if (functionName == "Update")
                _currentSb = _updateMethodSb;
            else
                _currentSb.AppendLine(functionName + ":");

            _symbolTable[functionName] = "function";
            GenerateNode(node.Children[3]);

            if (isSpecialFunction)
                _currentSb = _codeSb;
            else
                _currentSb.AppendLine("RTS");
        }

        private void GenerateByteDeclaration(AstNode node)
        {
            var name = node.Children[1].Value;
            var type = _symbolTable[name] = node.Children[0].Value;

            _currentSb.AppendLine("; Byte var or array declaration: " + name);

            if (type == "byte[]")
            {
                var size = int.Parse(node.Children[2].Value);

                _currentSb.AppendLine($"{name}_ptr: .res 2");
                _currentSb.AppendLine($"{name}_size: .res 1");
                _currentSb.AppendLine($"    LDA #{size}");
                _currentSb.AppendLine($"    STA {name}_size");
                _currentSb.AppendLine($"{name}: .res {size}");
                _currentSb.AppendLine($"    LDA #<{name}");
                _currentSb.AppendLine($"    STA {name}_ptr");
                _currentSb.AppendLine($"    LDA #>{name}");
                _currentSb.AppendLine($"    STA {name}_ptr+1");
            }
            else
            {
                _currentSb.AppendLine($"{name}: .res 1");
                var value = node.Children[2].Children[0].Value;
                _startMethodSb.AppendLine($"; initialization of {name} with {value}");
                _startMethodSb.AppendLine($"LDA #{value}");
                _startMethodSb.AppendLine($"STA {name}");
            }
        }

        private void GenerateSpriteDeclaration(AstNode node)
        {
            var name = node.Children[1].Value;
            _symbolTable[name] = "Sprite";
            _currentSb.AppendLine("; Sprite declaration: " + name);
            _currentSb.AppendLine($"{name}: .res 1");
        }

        private void GenerateExpression(AstNode node)
        {
            var child = node.Children[0];

            switch (child.Type)
            {
                case NodeType.Constant:
                    _currentSb.AppendLine($"    LDA #{child.Value}");
                    break;
                case NodeType.Boolean:
                    _currentSb.AppendLine($"    LDA #{(child.Value == "true" ? "1" : "0")}");
                    break;
                case NodeType.Identifier:
                    GenerateIdentifierLoad(child);
                    break;
                case NodeType.MemberAccess:
                    GenerateMemberAccessLoad(child);
                    break;
                case NodeType.Assignment:
                    GenerateAssignment(child);
                    break;
                case NodeType.Operation:
                    GenerateOperation(child);
                    break;
                case NodeType.FunctionCall:
                    GenerateFunctionCall(child);
                    break;
                case NodeType.ArrayAccess:
                    GenerateArrayAccessLoad(child);
                    break;
                case NodeType.Length:
                    GenerateLengthAccess(child);
                    break;
            }
        }

        private void GenerateIdentifierLoad(AstNode node)
        {
            if (!_symbolTable.ContainsKey(node.Value))
                throw new Exception("Undefined symbol: " + node.Value);
            _currentSb.AppendLine($"    LDA {node.Value}");
        }

        private int GetSpriteFieldOffset(string fieldName)
        {
            if (SpriteFieldOffsets.TryGetValue(fieldName, out var offset))
                return offset;
            throw new Exception($"No field '{fieldName}' in sprite");
        }

        /// <summary>
        /// Emits the indirect addressing setup for accessing a sprite field.
        /// Leaves the offset in Y, and sets up (temp) pointer to OAM page.
        /// </summary>
        private void EmitSpriteIndirectSetup(AstNode identifier, int offset)
        {
            _currentSb.AppendLine($"    LDY #{offset}");
            _currentSb.AppendLine($"    LDX {identifier.Value}");
            _currentSb.AppendLine($"    STX temp");
            _currentSb.AppendLine($"    LDX #$02");
            _currentSb.AppendLine($"    STX temp2");
        }

        private void GenerateMemberAccessLoad(AstNode node)
        {
            var identifier = node.Children[0];
            var member = node.Children[1];
            var offset = GetSpriteFieldOffset(member.Value);
            EmitSpriteIndirectSetup(identifier, offset);
            _currentSb.AppendLine($"    LDA (temp), Y");
        }

        private void GenerateAssignment(AstNode node)
        {
            var assignee = node.Children[0];
            var expression = node.Children[1];
            GenerateExpression(expression);

            if (assignee.Type == NodeType.MemberAccess)
            {
                var identifier = assignee.Children[0];
                var member = assignee.Children[1];
                var offset = GetSpriteFieldOffset(member.Value);
                EmitSpriteIndirectSetup(identifier, offset);
                _currentSb.AppendLine($"    STA (temp), Y");
            }
            else if (assignee.Type == NodeType.Identifier)
            {
                _currentSb.AppendLine($"    STA {assignee.Value}");
            }
        }

        private void GenerateOperation(AstNode node)
        {
            GenerateNode(node.Children[0]); // left
            _currentSb.AppendLine("    PHA");
            GenerateNode(node.Children[1]); // right
            _currentSb.AppendLine("    PHA");

            var subroutine = node.Value switch
            {
                "+" => "add",
                "-" => "subtract",
                "==" => "equal",
                "!=" => "notEqual",
                ">" => "greaterThan",
                "<" => "lowerThan",
                "*" => throw new NotImplementedException("Multiplication not yet implemented"),
                "/" => throw new NotImplementedException("Division not yet implemented"),
                _ => throw new Exception($"Unknown operation: {node.Value}")
            };

            _currentSb.AppendLine($"    JSR {subroutine}");
            _currentSb.AppendLine("    PLA");
        }

        private void GenerateFunctionCall(AstNode node)
        {
            var target = node.Children[0];
            var funcName = BuildMemberPath(target);

            if (funcName == "CreateSprite")
                GenerateCreateSpriteCall(node);
            else if (funcName == "Input.GetKey")
                GenerateInputGetKeyCall(node);
        }

        private void GenerateCreateSpriteCall(AstNode node)
        {
            // Push arguments: x, y, tile, attribute
            for (int i = 1; i <= 4; i++)
            {
                GenerateNode(node.Children[i]);
                _currentSb.AppendLine("    PHA");
            }
            _currentSb.AppendLine("    JSR CreateSprite");
            _currentSb.AppendLine("    PLA");
        }

        private void GenerateInputGetKeyCall(AstNode node)
        {
            var keyPath = BuildMemberPath(node.Children[1].Children[0]);
            var player = keyPath.Contains("Player1") ? "Player1" :
                         keyPath.Contains("Player2") ? "Player2" :
                         throw new Exception($"Unknown player in key path: {keyPath}");
            var padVariable = player == "Player1" ? "pad1" : "pad2";

            if (!KeyCodeMap.TryGetValue(keyPath, out var keyCode))
                throw new Exception($"Unknown key: {keyPath}");

            var labelIndex = _labelCounter++;
            var notPressedLabel = $"NotPressed{labelIndex}";
            var endLabel = $"EndCheck{labelIndex}";

            _currentSb.AppendLine($"    LDA {padVariable}");
            _currentSb.AppendLine($"    AND #{keyCode}");
            _currentSb.AppendLine($"    BEQ {notPressedLabel}");
            _currentSb.AppendLine($"    LDA #$01");
            _currentSb.AppendLine($"    JMP {endLabel}");
            _currentSb.AppendLine($"{notPressedLabel}:");
            _currentSb.AppendLine($"    LDA #$00");
            _currentSb.AppendLine($"{endLabel}:");
        }

        private void GenerateArrayAccessLoad(AstNode node)
        {
            var arrayName = node.Children[0].Value;
            var indexNode = node.Children[1];

            GenerateExpression(indexNode);

            _currentSb.AppendLine($"    TAY");
            _currentSb.AppendLine($"    LDA #<{arrayName}");
            _currentSb.AppendLine($"    STA {arrayName}_ptr");
            _currentSb.AppendLine($"    LDA #>{arrayName}");
            _currentSb.AppendLine($"    STA {arrayName}_ptr+1");
            _currentSb.AppendLine($"    LDA ({arrayName}_ptr),Y");
        }

        private void GenerateLengthAccess(AstNode node)
        {
            var arrayName = node.Children[0].Value;
            _currentSb.AppendLine($"    LDA {arrayName}_size");
        }

        /// <summary>
        /// Recursively builds a dotted member path from a MemberAccess or Identifier node.
        /// e.g. Input.GetKey -> "Input.GetKey", KeyCode.Player1.Right -> "KeyCode.Player1.Right"
        /// </summary>
        private string BuildMemberPath(AstNode node)
        {
            if (node.Type == NodeType.Identifier)
                return node.Value;
            if (node.Type == NodeType.MemberAccess)
                return $"{BuildMemberPath(node.Children[0])}.{node.Children[1].Value}";
            throw new Exception($"Unexpected node type when building member path: {node.Type}");
        }

        private void GenerateIfStatement(AstNode node)
        {
            var condition = node.Children[0];
            var trueBlock = node.Children[1];
            var falseBlock = node.Children.Count > 2 ? node.Children[2] : null;

            GenerateExpression(condition);

            var elseLabel = $"ELSE{_labelCounter}";
            var endIfLabel = $"ENDIF{_labelCounter}";
            var skipToElseLabel = $"SKIP_TO_ELSE{_labelCounter++}";

            _currentSb.AppendLine("    CMP #$00");
            _currentSb.AppendLine($"    BNE {skipToElseLabel}");

            _currentSb.AppendLine(falseBlock != null
                ? $"    JMP {elseLabel}"
                : $"    JMP {endIfLabel}");

            _currentSb.AppendLine($"{skipToElseLabel}:");
            GenerateNode(trueBlock);
            _currentSb.AppendLine($"    JMP {endIfLabel}");

            if (falseBlock != null)
            {
                _currentSb.AppendLine($"{elseLabel}:");
                GenerateNode(falseBlock);
            }

            _currentSb.AppendLine($"{endIfLabel}:");
        }

        private void GenerateWhileStatement(AstNode node)
        {
            var condition = node.Children[0];
            var body = node.Children[1];

            var startLabel = $"WHILE_START_{_labelCounter}";
            var endLabel = $"WHILE_END_{_labelCounter++}";

            _currentSb.AppendLine($"{startLabel}:");
            GenerateExpression(condition);
            _currentSb.AppendLine("    CMP #$00");
            _currentSb.AppendLine($"    BEQ {endLabel}");

            GenerateNode(body);
            _currentSb.AppendLine($"    JMP {startLabel}");
            _currentSb.AppendLine($"{endLabel}:");
        }
    }
}
