# YourNes Test Programs

This directory contains a comprehensive suite of test programs demonstrating all features of the YourNes language. Each test is designed to provide **visual feedback** in a NES emulator so you can immediately see if features are working correctly.

## How to Run Tests

1. Compile a test file: `NesCompiler.exe test_sprites.den`
2. Load the generated `.nes` file in your NES emulator
3. Observe the visual behavior described below

## Test Files

### test_sprites.den
**Tests:** Basic sprite creation and movement

**What you'll see:**
- 4 sprites in different colors on screen
- Red sprite continuously moves right (wraps around screen)
- Green sprite continuously moves left (wraps around screen)
- Blue sprite continuously moves down (wraps around screen)
- Yellow sprite continuously moves up (wraps around screen)

**Tests these features:**
- Sprite creation with `CreateSprite()`
- Sprite.X and Sprite.Y property assignment
- Basic arithmetic (+, -)
- Comparison operators (>, <)
- Automatic wrapping logic

---

### test_arithmetic.den
**Tests:** Arithmetic operations (addition and subtraction)

**What you'll see:**
- Single sprite that bounces horizontally left and right
- Sprite also oscillates up and down in a wave pattern
- Movement is calculated using addition and subtraction

**Tests these features:**
- Addition operator (+)
- Subtraction operator (-)
- Variable assignment with arithmetic results
- Comparison operators used with calculated values

---

### test_comparisons.den
**Tests:** All comparison operators (==, !=, >, <)

**What you'll see:**
- Left sprite changes color from green to red as counter increases
- Left sprite moves down when counter > 127
- Right sprite jumps to different X positions at specific counter values (64, 128, 192)
- Right sprite jumps up when counter reaches 255, then resets

**Tests these features:**
- Less than operator (<)
- Greater than operator (>)
- Equality operator (==)
- Inequality operator (!=)
- Using comparisons to control sprite appearance

---

### test_while_loop.den
**Tests:** While loop functionality

**What you'll see:**
- 8 sprites on screen
- **Press A button:** Sprites arrange in horizontal line (green color)
- **Press B button:** Sprites arrange in vertical line (blue color)
- **Press Select button:** Sprites arrange in 4x2 grid pattern (yellow color)

**Tests these features:**
- While loops with counter variables
- Loop conditions (<)
- Loop body execution
- Nested while loops (grid pattern)
- Variable increment inside loops

---

### test_arrays.den
**Tests:** Array declaration, indexing, read/write operations

**What you'll see:**
- 5 sprites in a horizontal row
- **Press Right:** All sprites shift right continuously
- **Press Left:** Sprites reset to original positions
- **Press Up:** All sprites move up
- **Press Down:** All sprites move down
- **Press A button:** Sprite colors cycle/rotate

**Tests these features:**
- Array declaration with size: `byte[] arrayName = [size]`
- Array write operations: `array[index] = value`
- Array read operations: `value = array[index]`
- Using arrays in loops
- Temporary variable swapping with arrays

---

### test_input.den
**Tests:** Input handling for all controller buttons

**What you'll see:**
- Single sprite that responds to all controller inputs
- **D-pad:** Moves sprite in 4 directions (wraps around screen edges)
- **A button:** Changes to green palette, tile 41
- **B button:** Changes to red palette, tile 42
- **Start button:** Changes to blue palette, tile 50
- **Select button:** Changes to yellow palette, tile 51

**Tests these features:**
- `Input.GetKey(KeyCode.Player1.Right)`
- `Input.GetKey(KeyCode.Player1.Left)`
- `Input.GetKey(KeyCode.Player1.Up)`
- `Input.GetKey(KeyCode.Player1.Down)`
- `Input.GetKey(KeyCode.Player1.A)`
- `Input.GetKey(KeyCode.Player1.B)`
- `Input.GetKey(KeyCode.Player1.Start)`
- `Input.GetKey(KeyCode.Player1.Select)`
- Sprite.Tile property assignment

---

### test_boolean.den
**Tests:** Boolean type and boolean logic

**What you'll see:**
- Single sprite that bounces left and right
- **Press A button:** Starts sprite movement
- **Press B button:** Stops sprite movement
- Sprite color changes between green (active) and red (inactive) based on position
- **Press Select:** Disables bouncing (sprite goes right continuously)
- **Press Start:** Re-enables bouncing

**Tests these features:**
- Boolean variable declarations: `bool isMoving = false`
- Boolean literals: `true` and `false`
- Boolean in if conditions
- Boolean assignment from conditions
- Boolean comparison: `if(isActive == false)`

---

### test_if_else.den
**Tests:** If-else statements with various conditions

**What you'll see:**
- Two sprites on screen
- **Left sprite (player-controlled):**
  - D-pad controls movement
  - Color changes based on direction (green=right, blue=left, red=idle)
  - Special tiles appear at top/bottom boundaries
- **Right sprite (automatic):**
  - Follows a 4-state pattern that changes every 60 frames
  - Different color for each state
  - Moves in square pattern

**Tests these features:**
- If-else statements
- Nested if-else chains
- Else branches
- State machine implementation
- Multiple conditional branches

---

### test_complex.den
**Tests:** Complex program combining multiple features

**What you'll see:**
- Player-controlled sprite (use D-pad to move)
- 3 collectible items (yellow sprites)
- 2 moving enemies (red sprites)
- **Gameplay:**
  - Move player sprite to collect yellow items (they disappear)
  - Avoid red enemies that move in patterns
  - Player turns red when touching enemy
  - Enemies move horizontally and vertically
- **Press Start:** Reset game (items reappear)

**Tests these features:**
- Multiple sprite management
- Collision detection logic
- Distance calculation using arithmetic
- Conditional visibility (hiding collected items)
- State tracking (active/collected items)
- Complex if-else logic
- Boolean flags for game state
- Timer variables

---

## Feature Coverage Summary

| Feature | Test Files |
|---------|-----------|
| Sprite creation | All |
| Sprite properties (X, Y, Tile, Attribute) | All |
| Arithmetic (+, -) | test_arithmetic, test_arrays, test_complex |
| Comparisons (>, <, ==, !=) | test_comparisons, test_if_else |
| While loops | test_while_loop, test_arrays |
| Arrays | test_arrays, test_complex |
| Boolean type | test_boolean, test_complex |
| If statements | All |
| If-else statements | test_if_else, test_complex |
| Input handling | test_input, test_arrays, test_boolean, test_if_else, test_complex |
| Byte variables | All |
| Variable assignment | All |

## Known Limitations Tested

These tests work within the current YourNes language limitations:

- **No multiplication/division** - Tests avoid these operators
- **No operator precedence** - Complex expressions are broken into steps
- **No for loops** - Tests use while loops instead
- **No function parameters** - Functions don't pass/return values
- **No local variables** - All variables are global
- **Simple collision detection** - No built-in physics, implemented manually

## Visual Debug Tips

Since YourNes can't output text yet, these visual patterns help debug:

1. **Position changes** = Logic is executing
2. **Color changes** = Conditional branches working
3. **Sprite disappearing** = Move to Y=250 (off-screen)
4. **Wrapping behavior** = Boundary conditions working
5. **Regular patterns** = Loops executing correctly

## Troubleshooting

If a test doesn't work as expected:

1. Check if the .asm file was generated in NesOutput/
2. Look for compilation errors in console
3. Verify the .nes file was created
4. Check that your emulator can run basic NES ROMs
5. Review the generated assembly for the specific feature being tested

## Next Steps

After verifying all tests work:
1. Try modifying test programs to experiment
2. Combine features from different tests
3. Create your own test programs
4. Report any bugs or unexpected behavior
