# brainf-ck-haskell
A brainf*ck interpreter created using haskell

---

## Usage:

```runhaskell project.hs <filename.bf>```

within ghci: 

```:main <filename.bf>```

With ```<filename.bf>``` being the file containing your brainf*ck code within the same directory.

---

## Language

Brainf*ck is an esoteric language with only 8 commands, with a program being a sequence of these commands. 

A program in Brainf*ck operates on a one-dimentional memory tape of cells, unbounded to the right. Each cell contains an 8-bit unsigned integer (0-255) and is initialised at 0. Arithmetic on cells is modulo 256, so incrementing 255 produces 0, and decrementing 0 produces 255.

A data pointer indicates the current active cell on the tape, can move left or right and is initialised at the leftmost cell. Moving to the left of the first cell produces an error.

### Commands 

| Command | Description |
| :---: | :--- |
| `+` | Increase current value (modulo 256) |||||||||||||||
| `-` | Decrease current value (modulo 256) |
| `>` | Move pointer one value to the right |
| `<` | Move pointer one value to the left |
| `[` | Begin loop (jumps past matching `]` if the current value is 0) |
| `]` | End loop (jumps back to matching `[` if the current value is not 0) |
| `,` | Input a character into the current value, overrides any existing value |
| `.` | Output the current value as a character |

Any other character in the file is simply ignored and doesn't affect the program in any way.

The current value refers to the current cell the data pointer is on.

Input and output uses the ASCII character encoding.

### Loops

Loops can be made in the following way: ```[ <code to loop> ]```. 

This checks if the current cell is zero. If not, it will excecute the loop, and if the current cell after everythig within the loop excecuted is not zero, it jumps back to the opening ```[``` and repeats.

If the current cell is 0 when the opening bracket is checked, the loop will not excecute and the program pointer will instead jump to the end of the block, skipping it entirely.

A nice consequence of this is that since every cell is initialised to be 0, you can have an "initial comment loop" as your first instruction in a file i.e. an initial comment/paragraph enclosed within ```[ ]```. This means you don't have to worry about any command characters accidentally excecuting, since the entire loop will be skipped.

---

## Design 

The architecture of the implementation is divided into three phases:

- **Parsing:** Translates raw text into a heirarchical Abstract Syntax Tree, as well as validating loops (producing an error if there are any unmatched brackets)
- **Memory Simulation:** Simulates an "infinite" storage tape with the active pointer
- **Evaluation** Takes a parsed program and excecutes each command/loop

#### Parsing 

The parser recurses over the string, taking each individual command and identifying and seperating loops into standalone blocks.

The program is then stored as follows:

```Haskell
data Instruction = Single Char | Block [Instruction]
type Program = [Instruction]
```

```Single char``` represents a single command (+, -, <, >, ., ,)

```Block [Inst]``` represents a loop block. Recursively wraps a nested child program

#### Data Tape

This implementation utilises a List Zipper to track the memory and the active cell in constant time.

```haskell
data Tape = Tape [Int] Int [Int]
```

The **Left list** ```[Int]``` holds all cells to the left of the active cell, initially empty.

The **Focus** ```Int``` represents the value in the current active cell.

The **Right list** ```[Int]``` holds all cells to the right of the active cell. It is lazily initiated as an infinite list of zeros (```repeat 0```)

The tape is also has a defined Show functionality, in which it will show the seperation of the Left list, focus and the Right list. Despite being stored in memory in reversed order (to save lookup time), the Show function flips it to show correct logical positioning.

For example:

**Program:** 
``` 
++>>>+<<+++ 
```
Corresponding Tape:
```Hs
[2]<3>[0,1,0,0,0]...
```


#### Evaluating

The evaluator handles lists of instructions sequentially. It evaluates the current instruction, returns the updated tape and passes this to the remaining recursive evaluators.

When evaluating a ```Block innerProgram```, the current focus is checked if it is 0 and executes/discards ```innerProgram``` until the focus is 0.

---

### Error handling

The interpreter is able to catch the following:

- (Compile time) **Unmatched brackets (```[]```)** 


By using an ```Either String (Program, String)``` return type, it allows the parser to find errors, and returun a string describing them, pushing it up the recursion layers to immediatly halt and display it.

If no error occurs, it returns the current parsed Program block and a string representing the remaining commands to be parsed.



- (Run time) **Memory errors** 

Going out of bounds on the left side of the tape is handled during tape traversal


