# Description
This is zLox-bytecode. My implementation of
[Crafting Interpreter](https://craftinginterpreters.com)'s cLox interpreter in Zig.

Compared to jLox there are fewer differences due to Zig's semantics mapping pretty well to C's
semantics (can literally transpile to/from C with Zig).


# Completed chapters
- Chapter 14: Chunks of Bytecode


# Major changes compared to cLox
- Some SCREAMING_SNAKE_CASE_NAMES are now just snake_case_names namely from the OpCode and
    TokenType enums.
- File names. I am keeping a general adherence to them, but I am making them more in line with what
    I would consider good code style.
- Dynamic arrays. I am writing my own, but using generics and a custom allocator interface.
- The entire allocation strategy. It requires all things to go through it, but it does not implement
    Zig's allocator interface. This it to make it easier to intertwine the objects and collector,
    but does mean I have to reinvent a lot more code to go with it. That isn't a big deal though
    because the book reinvents the wheel a lot too.
