﻿using System;
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
                case "WhileStatement":
                    GenerateWhileStatement(node);
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
            var type = _symbolTable[name] = node.Children[0].Value;

            _currentSb.AppendLine("; Byte var or array declaration: " + name);

            if (type == "byte[]")
            {
                var sizeNode = node.Children[2];
                Console.Write("parsing array length: " + sizeNode.Type + ", " + sizeNode.Value);
                var size = int.Parse(sizeNode.Value);

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
                } else if (operation.Value.Equals("*"))
                {
                    throw new NotImplementedException();
                } else if (operation.Value.Equals("/"))
                {
                    throw new NotImplementedException();
                } else if (operation.Value.Equals("=="))
                {
                    _currentSb.AppendLine("    JSR equal");
                } else if (operation.Value.Equals(">"))
                {
                    _currentSb.AppendLine("    JSR greaterThan");
                } else if (operation.Value.Equals("<"))
                {
                    _currentSb.AppendLine("    JSR lowerThan");
                } else if (operation.Value.Equals("!="))
                {
                    _currentSb.AppendLine("    JSR notEqual");
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
            else if (node.Children[0].Type == "ArrayAccess")
            {
                var arrayNode = node.Children[0].Children[0];
                var indexNode = node.Children[0].Children[1];
                var arrayName = arrayNode.Value;

                // Generate code to calculate the array index
                GenerateExpression(indexNode);

                // Generate code to access the array element
                _currentSb.AppendLine($"    TAY");
                _currentSb.AppendLine($"    LDA #<{arrayName}");
                _currentSb.AppendLine($"    STA {arrayName}_ptr");
                _currentSb.AppendLine($"    LDA #>{arrayName}");
                _currentSb.AppendLine($"    STA {arrayName}_ptr+1");
                _currentSb.AppendLine($"    LDA ({arrayName}_ptr),Y");
            }
            else if (node.Children[0].Type == "Length")
            {
                var arrayNode = node.Children[0].Children[0];
                var arrayName = arrayNode.Value;

                // Generate code to load the array length
                _currentSb.AppendLine($"    LDA {arrayName}_size");
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
            string endIfLabel = $"ENDIF{_labelCounter}";
            string skipToElseLabel = $"SKIP_TO_ELSE{_labelCounter++}"; // Для обхода диапазона BEQ

            // Предполагаем, что результат условия находится в аккумуляторе и ветвимся, если false
            _currentSb.AppendLine("    CMP #$00"); // Сравнение с false
            _currentSb.AppendLine($"    BNE {skipToElseLabel}"); // Если условие истинно, пропускаем ELSE

            // Если есть блок else, ветвимся к нему, если условие ложно
            if (falseBlock != null)
            {
                _currentSb.AppendLine($"    JMP {elseLabel}");
            }
            else // Если блока else нет, прямой переход к концу блока if
            {
                _currentSb.AppendLine($"    JMP {endIfLabel}");
            }

            _currentSb.AppendLine($"{skipToElseLabel}:");
            // Генерация кода для блока if
            GenerateNode(trueBlock);

            // Добавляем переход к концу if для пропуска блока else
            _currentSb.AppendLine($"    JMP {endIfLabel}");

            if (falseBlock != null)
            {
                _currentSb.AppendLine($"{elseLabel}:");
                // Генерация кода для блока else
                GenerateNode(falseBlock);
            }

            // Метка окончания конструкции if-else
            _currentSb.AppendLine($"{endIfLabel}:");
        }

        private void GenerateWhileStatement(AstNode node)
        {
            var condition = node.Children[0];
            var body = node.Children[1];

            // Create labels for branching
            string startLabel = $"WHILE_START_{_labelCounter}";
            string endLabel = $"WHILE_END_{_labelCounter++}";

            // Generate label for the start of the loop
            _currentSb.AppendLine($"{startLabel}:");

            // Generate code for the condition
            GenerateExpression(condition);

            // If the condition is false, jump to the end of the loop
            _currentSb.AppendLine("    CMP #$00");
            _currentSb.AppendLine($"    BEQ {endLabel}");

            // Generate code for the loop body
            GenerateNode(body);

            // Jump back to the start of the loop
            _currentSb.AppendLine($"    JMP {startLabel}");

            // Generate label for the end of the loop
            _currentSb.AppendLine($"{endLabel}:");
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
    }
}