# YourNes - NES Game Compiler

A compiler for creating Nintendo Entertainment System (NES) games using a custom high-level language.

## Project Structure

```
YourNes/
├── src/                    # Source code
│   ├── Program.cs          # Main entry point
│   ├── Lexer.cs            # Tokenization
│   ├── Parser.cs           # AST generation
│   ├── CodeGenerator.cs    # 6502 assembly generation
│   └── Token.cs            # Token definitions
├── examples/               # Example programs
│   ├── Default.den         # Default demo (platformer game)
│   ├── test_sprites.den    # Sprite movement test
│   ├── test_arithmetic.den # Arithmetic operations test
│   ├── test_comparisons.den# Comparison operators test
│   ├── test_while_loop.den # While loop test
│   ├── test_arrays.den     # Array operations test
│   ├── test_input.den      # Controller input test
│   ├── test_boolean.den    # Boolean logic test
│   ├── test_if_else.den    # If-else statements test
│   └── test_complex.den    # Complex game demo
├── docs/                   # Documentation
│   ├── README_SPEC.md      # Language specification
│   └── TESTS.md            # Test programs documentation
├── NesTemplates/           # NES assembly templates
│   ├── gametemplate.asm    # Base template
│   └── defaultchar.chr     # Default character set
├── NesTools/               # NES build tools
│   └── generate_nes.bat    # Assembly to .nes conversion
├── NesOutput/              # Generated files (gitignored)
├── NesCompiler.csproj      # C# project file
├── NesCompiler.sln         # Visual Studio solution
└── README.md               # This file
```

## Quick Start

### Prerequisites

- .NET 8.0 SDK or later
- **cc65 toolchain** (ca65 + ld65 assembler/linker)
- NES emulator (FCEUX, Mesen, etc.)

**📖 See [docs/SETUP.md](docs/SETUP.md) for detailed installation instructions**

### Building the Compiler

```bash
dotnet build
```

### Compiling a YourNes Program

```bash
# Compile specific file
dotnet run examples/test_sprites.den

# Or if no argument provided, compiles examples/Default.den
dotnet run
```

This will:
1. Parse the .den file
2. Generate 6502 assembly (.asm)
3. Assemble to .nes ROM file in `NesOutput/`
4. Output is ready to load in your NES emulator

### Running Examples

```bash
# Try different test programs
dotnet run examples/test_arithmetic.den
dotnet run examples/test_comparisons.den
dotnet run examples/test_complex.den
```

Load the generated `.nes` file from `NesOutput/` in your emulator.

## Language Features

YourNes is a simple language designed for NES development:

### Data Types
- `byte` - 8-bit unsigned integer
- `bool` - Boolean (true/false)
- `Sprite` - NES hardware sprite
- `byte[]` - Byte arrays

### Control Flow
- `if` / `else` statements
- `while` loops
- Comparison operators: `==`, `!=`, `>`, `<`

### Functions
- `void` functions (no return values yet)
- Special functions: `Start()` and `Update()`

### Built-in Functions
- `CreateSprite(x, y, tile, attribute)` - Create a sprite
- `Input.GetKey(KeyCode.Player1.Button)` - Read controller input

### Example Program

```yournes
byte playerX = 100;
byte playerY = 100;
Sprite player;

void Start() {
    player = CreateSprite(playerX, playerY, 1, 0);
}

void Update() {
    if(Input.GetKey(KeyCode.Player1.Right)) {
        playerX = playerX + 1;
    }

    if(Input.GetKey(KeyCode.Player1.Left)) {
        playerX = playerX - 1;
    }

    player.X = playerX;
    player.Y = playerY;
}
```

## Documentation

- **[Language Specification](docs/README_SPEC.md)** - Complete language reference
- **[Test Programs Guide](docs/TESTS.md)** - Detailed guide to all test programs

## Current Limitations

- No multiplication/division operators (tokenized but not implemented)
- No operator precedence (left-to-right evaluation)
- No `for` loops (use `while` instead)
- No function parameters/return values
- No local variables (all variables are global)
- Single global scope

See [docs/README_SPEC.md](docs/README_SPEC.md) for complete details.

## Development

### Project Configuration

The project uses:
- .NET 8.0 SDK-style project
- Source files in `src/`
- Examples in `examples/`
- Build output in `bin/` and `obj/` (gitignored)
- Generated NES files in `NesOutput/` (gitignored)

### VSCode Configuration

The `.vscode/` directory contains:
- Build tasks
- Launch configurations
- Recommended extensions

### Adding New Examples

1. Create a `.den` file in `examples/`
2. Write your YourNes code
3. Compile with `dotnet run examples/yourfile.den`
4. Test in NES emulator

## Contributing

When contributing:
1. Add tests for new features in `examples/`
2. Update language spec in `docs/README_SPEC.md`
3. Update test documentation in `docs/TESTS.md`
4. Follow existing code style

## License

See the main YourNes repository for license information.

## Acknowledgments

- Uses cc65 toolchain (ca65/ld65) for 6502 assembly
- Template based on standard NES development patterns
- Inspired by classic NES homebrew development
