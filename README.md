# YourNes Language Specification (Derived from Compiler Code)

This document describes the YourNes language based on the implementation found in `Lexer.cs`, `Parser.cs`, and `CodeGenerator.cs`. It is intended for creating applications for the Nintendo Entertainment System (NES).

## 1. Lexical Structure

### 1.1. Whitespace
Spaces (` `), newlines (`\n`), and carriage returns (`\r`) are ignored between tokens.

### 1.2. Comments
- Single-line comments start with `//` and extend to the end of the line.
- Multi-line comments (`/* ... */`) are not supported.

### 1.3. Identifiers
- Must start with a letter (`a-z`, `A-Z`) or underscore (`_`).
- Can contain letters, numbers (`0-9`), and underscores.
- Case-sensitive (implied by C# implementation).

### 1.4. Keywords & Recognized Symbols
The compiler explicitly recognizes the following based on their context:
- Types: `byte`, `Sprite`, `bool` (used in declarations/parameters)
- Control Flow: `if`, `else`, `while`
- Functions: `void` (as return type), `return`
- Literals: `true`, `false`

Other potential keywords (like `for`, `struct`, `const`) are not handled by the current compiler and would be treated as generic identifiers ("symbols").

### 1.5. Literals
- **Integer:** Sequences of digits (e.g., `123`). Hexadecimal or other bases are not supported by the lexer. Represented as 8-bit values in generated code (`LDA #value`).
- **Boolean:** `true`, `false`. Represented as `$01` and `$00` respectively in generated code.
- **String:** Enclosed in double quotes (`"`). Recognized by the lexer but not used in expressions by the parser or code generator.

### 1.6. Operators
- Assignment: `=`
- Arithmetic: `+`, `-` (Implemented via `JSR add`, `JSR subtract`)
- Comparison: `==`, `!=`, `>`, `<` (Implemented via `JSR equal`, `JSR notEqual`, `JSR greaterThan`, `JSR lowerThan`)
- *Note:* `*`, `/`, `>=`, `<=` are tokenized but not implemented in the code generator. Bitwise shifts (`<<`, `>>`) and logical not (`!`) are also tokenized but not implemented.

### 1.7. Punctuation
- Parentheses: `()` (Function calls, `if`/`while` conditions)
- Braces: `{}` (Code blocks)
- Brackets: `[]` (Array type declaration, array access, array size definition)
- Semicolon: `;` (Statement terminator)
- Comma: `,` (Separating parameters/arguments)
- Dot: `.` (Member access)

## 2. Program Structure
- A program is a sequence of top-level declarations.
- Allowed top-level declarations:
    - `byte` variable/array declarations.
    - `Sprite` variable declarations.
    - `void` function declarations.
- **Special Functions:** `Start()` and `Update()` are required. Their code is placed into specific sections of the final assembly output.

## 3. Data Types
- **`byte`**: 8-bit unsigned integer type. Allocated 1 byte in zero-page memory.
- **`Sprite`**: Represents an NES hardware sprite. Allocated 1 byte in zero-page memory, likely holding an OAM index. Managed via `CreateSprite`. Has implicit members `X`, `Y`, `Tile`, `Attribute`.
- **`bool`**: Boolean type (`true`/`false`).

## 4. Declarations

### 4.1. Variable Declaration
- **Syntax:** `type identifier [ = expression ];`
- **Example:**
  ```yournes
  byte counter;
  byte flags = 0; // Initialization code placed in Start()
  Sprite playerSprite;
  bool isActive = true; // Initialization code placed in Start()
  ```
- Must end with a semicolon (`;`).
- Variables are allocated in zero-page memory.

### 4.2. Array Declaration (byte only)
- **Syntax:** `byte[] identifier = [ size ];`
- **Example:**
  ```yournes
  byte[] palette = [16];
  byte[] nametable = [1024];
  ```
- `size` must be an integer literal.
- Allocates memory for the array data, a 2-byte pointer (`identifier_ptr`), and a 1-byte size (`identifier_size`) in zero-page. Pointer and size are initialized in `Start()`.
- Initialization of array elements is not supported at declaration.
- Must end with a semicolon (`;`).

### 4.3. Function Declaration
- **Syntax:** `void identifier ( [parameter_list] ) { statement_block }`
- **Return Type:** Only `void` is supported.
- **Parameters:** `type identifier [, type identifier ...]`
    - Allowed types: `byte`, `Sprite`, `bool`. Parameter passing mechanism is not explicitly defined/used in the current generator.
- **Special Functions:** `Start()` and `Update()` are generated without labels or `RTS`. Other functions are generated with a label and end with `RTS`.
- **Example:**
  ```yournes
  // Required functions
  void Start() {
      // Initialization code
  }

  void Update() {
      // Main loop code
  }

  // User-defined function
  void SetPosition(byte x, byte y) {
      playerSprite.X = x; // Example usage
      playerSprite.Y = y;
  }
  ```

## 5. Statements

Statements are found within function bodies or statement blocks.

### 5.1. Statement Block
- **Syntax:** `{ [statement ...] }`
- Groups zero or more statements.

### 5.2. If Statement
- **Syntax:** `if ( expression ) statement_block [ else statement_block ]`
- Condition expression must evaluate to a boolean (`true`/`$01` or `false`/`$00`).
- Uses `CMP #$00`, `BNE`, `BEQ`, `JMP` for branching.

### 5.3. While Statement
- **Syntax:** `while ( expression ) statement_block`
- Condition expression must evaluate to a boolean.
- Uses labels, `CMP #$00`, `BEQ`, `JMP` for looping.

### 5.4. Return Statement
- **Syntax:** `return [ expression ];`
- Exits the current `void` function. The optional expression is evaluated but its value is ignored.
- Not typically needed in `Start` or `Update`. Generates `RTS` in other functions.
- Must end with a semicolon (`;`).

### 5.5. Expression Statement
- **Syntax:** `expression ;`
- An expression evaluated for its side effects (e.g., assignment, function call).
- Must end with a semicolon (`;`).
- **Example:**
  ```yournes
  x = y + 1;
  DoSomething();
  playerSprite.X = 100;
  ```

## 6. Expressions

Expressions evaluate to a value, typically left in the Accumulator (A register).

### 6.1. Literals
- Integer literals (e.g., `10`, `255`) -> `LDA #value`
- Boolean literals (`true`, `false`) -> `LDA #$01` or `LDA #$00`

### 6.2. Identifiers
- Referencing variables -> `LDA identifier`

### 6.3. Binary Operations
- **Syntax:** `expression operator expression`
- **Operators:** `+`, `-`, `==`, `!=`, `>`, `<`. Operands are pushed to stack, a `JSR` to a corresponding routine is performed, result expected in A.
- *Note:* Operator precedence is not explicitly handled; likely simple left-to-right evaluation. Parentheses for explicit grouping are not parsed into the AST structure.

### 6.4. Assignment
- **Syntax:** `lvalue = expression`
- `lvalue` can be an identifier, array access, or member access.
- Right side is evaluated (result in A), then stored using `STA identifier` or `STA (pointer), Y`.

### 6.5. Function Call
- **Syntax:** `identifier ( [expression [, expression ...]] )` or `namespace.identifier ( ... )`
- **Built-ins:**
    - `CreateSprite(byte x, byte y, byte tile, byte attribute)`: Calls `JSR CreateSprite` after pushing args to stack. Returns sprite handle in A.
    - `Input.GetKey(KeyCode.PlayerX.Button)`: Generates inline code to check controller state (`pad1`/`pad2`) and returns `1` or `0` in A. `KeyCode.Player1` and `KeyCode.Player2` with `Right`, `Left`, `Down`, `Up`, `Start`, `Select`, `B`, `A` are supported.
- **User Functions:** `JSR functionName`. Argument passing not implemented.

### 6.6. Member Access
- **Syntax:** `expression . identifier`
- Only implemented for `Sprite` type variables.
- `sprite.X` -> Accesses OAM byte at offset 3 from sprite's base OAM address.
- `sprite.Y` -> Accesses OAM byte at offset 0.
- `sprite.Tile` -> Accesses OAM byte at offset 1.
- `sprite.Attribute` -> Accesses OAM byte at offset 2.
- Uses indirect indexed addressing: `LDY #offset`, `LDX sprite_var`, `STX temp`, `LDA (temp), Y`.

### 6.7. Array Access
- **Syntax:** `expression [ expression ]`
- Only implemented for `byte[]`.
- Index expression is evaluated (result in A), transferred to Y (`TAY`).
- Array base address loaded into `arrayName_ptr`.
- Element accessed using `LDA (arrayName_ptr), Y`.

## 7. Built-in Dependencies
The generated code relies on an assembly template and external definitions:
- **Subroutines:** `add`, `subtract`, `equal`, `notEqual`, `greaterThan`, `lowerThan`, `CreateSprite`.
- **Zero-Page Variables:** `temp`, `temp2` (used for indirect addressing), `pad1`, `pad2` (controller state).
- **Constants:** `BTN_RIGHT`, `BTN_LEFT`, `BTN_DOWN`, `BTN_UP`, `BTN_START`, `BTN_SELECT`, `BTN_B`, `BTN_A` (button masks).

## 8. Notes & Limitations
- **Operator Precedence/Grouping:** Not handled; evaluation is likely left-to-right for sequences of operators. Use explicit assignments to temporary variables for complex calculations.
- **Scope:** Single global scope implied. No local variables within functions unless implemented via zero-page reuse manually.
- **Type System:** Very basic. No implicit casting. Type mismatches are likely caught at code generation (if at all) or result in runtime errors.
- **Missing Features:** No `for` loops, user-defined `struct`s, `const` declarations, pointers (other than implicit array/sprite pointers), explicit type casting, modules, non-`void` functions, multiplication/division.