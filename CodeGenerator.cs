using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;

namespace NesCompiler
{
    public class CodeGenerator
    {
        private AstNode _root;
        private StringBuilder _currentSb;
        private StringBuilder _zeroPageSb;
        private StringBuilder _startMethodSb;
        private StringBuilder _updateMethodSb;
        private StringBuilder _codeSb;

        private Dictionary<string, string> _symbolTable;
        private int _labelCounter; 
        private int _nextFreeMemoryAddress = 0;
        private string _templateCode;


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

            var result = string.Format(_templateCode, _zeroPageSb, _startMethodSb, _updateMethodSb);

            return result;
        }

        private void GenerateNode(AstNode node)
        {
            switch (node.Type)
            {
                case "root":
                    foreach (var child in node.Children)
                    {
                        GenerateNode(child);
                    }
                    break;
                case "FunctionDeclaration":
                    GenerateFunctionDeclaration(node);
                    break;
                case "ByteDeclaration":
                    _currentSb = _zeroPageSb;
                    GenerateByteDeclaration(node);
                    _currentSb = _codeSb;
                    break;
                case "SpriteDeclaration":
                    _currentSb = _zeroPageSb;
                    GenerateSpriteDeclaration(node);
                    _currentSb = _codeSb;
                    break;
                case "Statement":
                    GenerateStatement(node);
                    break;
                case "Expression":
                    GenerateExpression(node);
                    break;
                case "Block":
                case "FunctionBody":
                    GenerateBlockOrBody(node);
                    break;
                case "Expression Statement":
                    GenerateExpressionStatement(node);
                    break;
                case "Assignment":
                    GenerateAssignment(node);
                    break;
                case "IfStatement":
                    GenerateIfStatement(node);
                    break;
                default:
                    throw new Exception("Unrecognized node type: " + node.Type);
            }
        }

        private void GenerateAssignment(AstNode node)
        {
            throw new NotImplementedException();
        }


        private void GenerateExpressionStatement(AstNode node)
        {
            GenerateExpression(node.Children[0]);
        }

        private void GenerateFunctionDeclaration(AstNode node)
        {
            var functionName = node.Children[1].Value;
            bool specialFunction = true;
            if(functionName == "Start")
            {
                _currentSb = _startMethodSb;
            }
            else if(functionName == "Update")
            {
                _currentSb = _updateMethodSb;
            }
            else
            {
                specialFunction = false;
                _currentSb.AppendLine(functionName + ":");
            }
            _symbolTable[functionName] = "function";

            GenerateNode(node.Children[3]);


            if (!specialFunction)
            {
                _currentSb.AppendLine("RTS");
            } else
            {
                _currentSb = _codeSb;
            }
        }

        private void GenerateBlockOrBody(AstNode node)
        {
            foreach (var child in node.Children)
            {
                GenerateNode(child);
            }
        }

        private void GenerateByteDeclaration(AstNode node)
        {
            var name = node.Children[1].Value;
            var value = node.Children[2].Children[0].Value;
            _symbolTable[name] = "byte";

            _currentSb.AppendLine("; Byte declaration: " + name + " = " + value);
            _currentSb.AppendLine($"{name}: .res 1");

            _startMethodSb.AppendLine($"; initialization of {name} with {value}");
            _startMethodSb.AppendLine($"LDA #{value}");
            _startMethodSb.AppendLine($"STA {name}");
        }

        private void GenerateSpriteDeclaration(AstNode node)
        {
            var name = node.Children[1].Value;

            _symbolTable[name] = "Sprite";

            _currentSb.AppendLine("; Sprite declaration: " + name);
            _currentSb.AppendLine($"{name}: .res 1");

        }

        private void GenerateStatement(AstNode node)
        {
            GenerateNode(node.Children[0]);

            _currentSb.AppendLine("    STA $2003");
            _currentSb.AppendLine("    LDA #$01");
            _currentSb.AppendLine("    STA $4014");
        }

        private void GenerateExpression(AstNode node)
        {
            if (node.Children[0].Type == "Constant")
            {
                var value = node.Children[0].Value;
                _currentSb.AppendLine($"    LDA #{value}");
            } 
            else if(node.Children[0].Type == "Boolean")
            {
                // Assuming true is represented as 1 and false as 0 in your target assembly language
                var boolValue = node.Children[0].Value == "true" ? "1" : "0";
                _currentSb.AppendLine($"    LDA #{boolValue}");
            }
            else if (node.Children[0].Type == "Identifier")
            {
                var name = node.Children[0].Value;
                if (_symbolTable.ContainsKey(name))
                {
                    _currentSb.AppendLine($"    LDA {name}");
                }
                else
                {
                    throw new Exception("Undefined symbol: " + name);
                }
            }
            else if (node.Children[0].Type == "MemberAccess")
            {
                var memberAccess = node.Children[0];
                var identifier = memberAccess.Children[0];
                var member = memberAccess.Children[1];
                //todo check if identifier has this member
                //but for now assume it is sprite
                //for a sprite we have a special case
                //identifier equals the memory address of a sprite
                //so for member X we just take this address
                //but for Y we will take address+3
                //for tile - address+1
                var offset = 0;
                if (member.Value == "X")
                {
                    offset = 3;
                }
                else if (member.Value == "Y")
                {
                    offset = 0;
                }
                else if (member.Value == "Tile")
                {
                    offset = 1;
                }
                else if(member.Value == "Attribute")
                {
                    offset = 2;
                }
                else
                {
                    throw new Exception($"no field {member.Value} in sprite");
                }
                _currentSb.AppendLine($"    LDY #{offset}");
                _currentSb.AppendLine($"    LDX {identifier.Value}");
                _currentSb.AppendLine($"    STX temp");
                _currentSb.AppendLine($"    LDX #$02");
                _currentSb.AppendLine($"    STX temp2");
                _currentSb.AppendLine($"    LDA (temp), Y");
            }
            else if (node.Children[0].Type == "Declaration")
            {
                // Allocate memory for the local variable
                var typeNode = node.Children[0];
                var type = typeNode.Value;
                var size = GetSizeForType(type);
                var nameNode = node.Children[1];
                var name = nameNode.Value;
                var address = AllocateMemory(size);
                _symbolTable[name] = type;

                // Generate code to evaluate the expression on the right-hand side of the assignment
                var assignmentNode = node.Children[2];
                GenerateExpression(assignmentNode.Children[1]);

                // Store the result in the memory location for the local variable
                _currentSb.AppendLine("    STA " + address.ToString("X4"));

                throw new NotImplementedException();
                return;
            }
            else if(node.Children[0].Type == "Assignment")
            {
                var assignee = node.Children[0].Children[0];
                var expression = node.Children[0].Children[1];
                GenerateExpression(expression);

                if(assignee.Type == "MemberAccess")
                {
                    var identifier = assignee.Children[0];
                    var member = assignee.Children[1];
                    //todo check if identifier has this member
                    //but for now assume it is sprite
                    //for a sprite we have a special case
                    //identifier equals the memory address of a sprite
                    //so for member X we just take this address
                    //but for Y we will take address+3
                    //for tile - address+1
                    var offset = 0;
                    if(member.Value == "X")
                    {
                        offset = 3;
                    } else if(member.Value == "Y")
                    {
                        offset = 0;
                    } else if (member.Value == "Tile")
                    {
                        offset = 1;
                    } else if (member.Value == "Attribute")
                    {
                        offset = 2;
                    }
                    else
                    {
                        throw new Exception($"no field {member.Value} in sprite");
                    }
                    _currentSb.AppendLine($"    LDY #{offset}");
                    _currentSb.AppendLine($"    LDX {identifier.Value}");
                    _currentSb.AppendLine($"    STX temp");
                    _currentSb.AppendLine($"    LDX #$02");
                    _currentSb.AppendLine($"    STX temp2");
                    _currentSb.AppendLine($"    STA (temp), Y");
                } else if (assignee.Type == "Identifier")
                {
                    _currentSb.AppendLine($"    STA {assignee.Value}");
                }

            }
            else if (node.Children[0].Type == "Operation")
            {
                var operation = node.Children[0];
                var leftPart = operation.Children[0];
                var rightPart = operation.Children[1];
                GenerateNode(leftPart);
                _currentSb.AppendLine("    PHA");
                GenerateNode(rightPart);
                _currentSb.AppendLine("    PHA");

                // Определяем тип операции и вызываем соответствующую подпрограмму
                if (operation.Value.Equals("+"))
                {
                    _currentSb.AppendLine("    JSR add"); // Вызов подпрограммы сложения
                }
                else if (operation.Value.Equals("-"))
                {
                    _currentSb.AppendLine("    JSR subtract"); // Вызов подпрограммы вычитания
                }

                _currentSb.AppendLine("    PLA");
            }
            else if(node.Children[0].Type == "FunctionCall")
            {
                var functionCall = node.Children[0];
                var target = functionCall.Children[0]; // Может быть MemberAccess или Identifier
                var funcName = GetFunctionName(target); // Получаем полное имя функции

                if (funcName.Equals("CreateSprite"))
                {
                    var xExpression = functionCall.Children[1];
                    var yExpression = functionCall.Children[2];
                    var tileExpression = functionCall.Children[3];
                    var attributeExpression = functionCall.Children[4];

                    GenerateNode(xExpression);
                    _currentSb.AppendLine("    PHA");
                    GenerateNode(yExpression);
                    _currentSb.AppendLine("    PHA");
                    GenerateNode(tileExpression);
                    _currentSb.AppendLine("    PHA");
                    GenerateNode(attributeExpression);
                    _currentSb.AppendLine("    PHA");
                    _currentSb.AppendLine("    JSR CreateSprite");
                    _currentSb.AppendLine("    PLA");
                }
                else if (funcName.Equals("Input.GetKey"))
                {
                    var keyArgument = BuildKeyCodePath(functionCall.Children[1].Children[0]); // Получаем аргумент как строку
                    var player = GetPlayer(keyArgument); // Определяем, к какому игроку относится вызов
                    var keyCode = MapKeyCodeToAssemblyCode(keyArgument); // Конвертируем строку в код клавиши
                    var labelIndex = _labelCounter++; // Увеличиваем счетчик меток для уникальности

                    // Выбираем переменную состояния кнопок в зависимости от игрока
                    var padVariable = player == "Player1" ? "pad1" : "pad2";

                    // Генерируем код для проверки состояния клавиши
                    _currentSb.AppendLine($"    LDA {padVariable} ; Загрузка состояния кнопок для {player}");
                    _currentSb.AppendLine($"    AND #{keyCode} ; Маскирование для проверки кнопки");

                    // Генерируем код с использованием уникальных меток на основе счетчика
                    var notPressedLabel = $"NotPressed{labelIndex}";
                    var endLabel = $"EndCheck{labelIndex}";

                    _currentSb.AppendLine($"    BEQ {notPressedLabel} ; Если кнопка не нажата, переходим к метке {notPressedLabel}");
                    _currentSb.AppendLine($"    LDA #$01 ; Если кнопка нажата, загружаем 1");
                    _currentSb.AppendLine($"    JMP {endLabel} ; Переходим к концу проверки");
                    _currentSb.AppendLine($"{notPressedLabel}:");
                    _currentSb.AppendLine($"    LDA #$00 ; Загружаем 0, так как кнопка не нажата");
                    _currentSb.AppendLine($"{endLabel}:");
                }
            }

        }

        private string GetPlayer(string keyPath)
        {
            // Предполагаем, что keyPath имеет формат "KeyCode.PlayerX.Y", где X - номер игрока
            if (keyPath.Contains("Player1"))
            {
                return "Player1";
            }
            else if (keyPath.Contains("Player2"))
            {
                return "Player2";
            }
            else
            {
                throw new Exception($"Неизвестный игрок в пути доступа к клавише: {keyPath}");
            }
        }


        private string GetFunctionName(AstNode node)
        {
            if (node.Type == "Identifier")
            {
                return node.Value;
            }
            else if (node.Type == "MemberAccess")
            {
                // Рекурсивно собираем путь, начиная с базового объекта/пространства имен
                var basePart = GetFunctionName(node.Children[0]); // Обрабатываем левую часть доступа
                var memberPart = node.Children[1].Value; // Имя члена (функции) в правой части
                return $"{basePart}.{memberPart}"; // Собираем полный путь
            }
            throw new Exception($"Неожиданный тип узла при получении имени функции: {node.Type}");
        }


        private string MapKeyCodeToAssemblyCode(string keyPath)
        {
            // Разбор пути доступа к клавише и возвращение соответствующего битового значения
            var keyMap = new Dictionary<string, string>
            {
                {"KeyCode.Player1.Right", "BTN_RIGHT"},
                {"KeyCode.Player1.Left", "BTN_LEFT"},
                {"KeyCode.Player1.Down", "BTN_DOWN"},
                {"KeyCode.Player1.Up", "BTN_UP"},
                {"KeyCode.Player1.Start", "BTN_START"},
                {"KeyCode.Player1.Select", "BTN_SELECT"},
                {"KeyCode.Player1.B", "BTN_B"},
                {"KeyCode.Player1.A", "BTN_A"},
                // Добавьте аналогичные записи для Player2, если необходимо
            };

            // Извлекаем последнюю часть пути, которая указывает на конкретную кнопку
            var keyName = keyPath.Split('.').Last();

            // Ищем соответствие в словаре
            if (keyMap.TryGetValue(keyPath, out var keyCode))
            {
                return keyCode;
            }
            else
            {
                throw new Exception($"Неизвестная клавиша: {keyName}");
            }
        }


        private string BuildKeyCodePath(AstNode node)
        {
            if (node.Type == "Identifier")
            {
                return node.Value; // Просто возвращаем имя идентификатора, если это конец цепочки
            }
            else if (node.Type == "MemberAccess")
            {
                // Рекурсивно собираем путь к клавише
                var basePart = BuildKeyCodePath(node.Children[0]);
                var memberPart = node.Children[1].Value;
                return $"{basePart}.{memberPart}";
            }
            throw new Exception($"Неожиданный тип узла при построении пути клавиши: {node.Type}");
        }


        private void GenerateIfStatement(AstNode node)
        {
            var condition = node.Children[0];
            var trueBlock = node.Children[1];
            AstNode falseBlock = node.Children.Count > 2 ? node.Children[2] : null;

            // Генерация кода для условия
            GenerateExpression(condition);

            // Создание меток для ветвления
            string elseLabel = $"ELSE{_labelCounter}";
            string endIfLabel = $"ENDIF{_labelCounter++}";

            // Предполагаем, что результат условия находится в аккумуляторе и ветвимся, если false
            _currentSb.AppendLine("    CMP #$00"); // Сравнение с false
            if (falseBlock != null)
            {
                // Если есть блок else, ветвимся к нему, если условие ложно
                _currentSb.AppendLine($"    BEQ {elseLabel}");
            }
            else
            {
                // Если блока else нет, просто пропускаем блок if
                _currentSb.AppendLine($"    BEQ {endIfLabel}");
            }

            // Генерация кода для блока if
            GenerateNode(trueBlock);

            if (falseBlock != null)
            {
                // Если есть блок else, добавляем переход к концу if и метку для else
                _currentSb.AppendLine($"    JMP {endIfLabel}");
                _currentSb.AppendLine($"{elseLabel}:");
                GenerateNode(falseBlock);
            }

            // Метка окончания конструкции if-else
            _currentSb.AppendLine($"{endIfLabel}:");
        }



        private int GetSizeForType(string type)
        {
            switch (type)
            {
                case "byte":
                    return 1;
                // Add cases for other types (e.g. int, float, etc.)
                default:
                    throw new Exception("Unrecognized type: " + type);
            }
        }

        private int AllocateMemory(int size)
        {
            var address = _nextFreeMemoryAddress;
            _nextFreeMemoryAddress += size;
            return address;
        }


    }
}