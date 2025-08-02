const Compiler = @This();

const TokenType = enum {
    // Single-character tokens.
    LEFT_PAREN,
    RIGHT_PAREN,
    LEFT_BRACE,
    RIGHT_BRACE,
    COMMA,
    DOT,
    MINUS,
    PLUS,
    SEMICOLON,
    SLASH,
    STAR,

    // One or two character tokens.
    BANG,
    BANG_EQUAL,
    EQUAL,
    EQUAL_EQUAL,
    GREATER,
    GREATER_EQUAL,
    LESS,
    LESS_EQUAL,

    // Literals.
    IDENTIFIER,
    STRING,
    NUMBER,

    // Keywords.
    AND,
    CLASS,
    ELSE,
    FALSE,
    FOR,
    FUN,
    IF,
    NIL,
    OR,
    PRINT,
    RETURN,
    SUPER,
    THIS,
    TRUE,
    VAR,
    WHILE,

    // Special tokens
    ERROR,
    EOF,
};

const Token = struct {
    ty: TokenType,
    lexeme: []const u8,
    line: u32,
};

const Scanner = struct {
    start: []const u8,
    current: []const u8,
    line: u32,

    pub fn init(source: []const u8) @This() {
        return .{
            .start = source,
            .current = source,
            .line = 1,
        };
    }

    pub fn scanToken(self: *@This()) Token {
        self.skipWhitespace();

        self.start = self.current;
        self.start.len = 0;

        if (self.isAtEnd()) {
            return self.token(.EOF);
        }

        switch (self.advance()) {
            '(' => return self.token(.LEFT_PAREN),
            ')' => return self.token(.RIGHT_PAREN),
            '{' => return self.token(.LEFT_BRACE),
            '}' => return self.token(.RIGHT_BRACE),
            ';' => return self.token(.SEMICOLON),
            ',' => return self.token(.COMMA),
            '.' => return self.token(.DOT),
            '-' => return self.token(.MINUS),
            '+' => return self.token(.PLUS),
            '/' => return self.token(.SLASH),
            '*' => return self.token(.STAR),
            '!' => if (self.match('=')) {
                return self.token(.BANG_EQUAL);
            } else {
                return self.token(.BANG);
            },
            '=' => if (self.match('=')) {
                return self.token(.EQUAL_EQUAL);
            } else {
                return self.token(.EQUAL);
            },
            '<' => if (self.match('=')) {
                return self.token(.LESS_EQUAL);
            } else {
                return self.token(.LESS);
            },
            '>' => if (self.match('=')) {
                return self.token(.GREATER_EQUAL);
            } else {
                return self.token(.GREATER);
            },
            '"' => return self.string(),
            else => |c| {
                if (isAlpha(c)) {
                    return self.identifier();
                }
                if (isDigit(c)) {
                    return self.number();
                }
                return self.errorToken("Unexpected Character");
            },
        }
    }

    fn identifier(self: *@This()) Token {
        while (!self.isAtEnd() and isAlpha(self.current[0])) {
            _ = self.advance();
        }

        return switch (self.start[0]) {
            'a' => self.token(self.checkString("and", .AND)),
            'c' => self.token(self.checkString("class", .CLASS)),
            'e' => self.token(self.checkString("else", .ELSE)),
            'i' => self.token(self.checkString("if", .IF)),
            'n' => self.token(self.checkString("nil", .NIL)),
            'o' => self.token(self.checkString("or", .OR)),
            'p' => self.token(self.checkString("print", .PRINT)),
            'r' => self.token(self.checkString("return", .RETURN)),
            's' => self.token(self.checkString("super", .SUPER)),
            'v' => self.token(self.checkString("var", .VAR)),
            'w' => self.token(self.checkString("while", .WHILE)),
            'f' => switch (self.start[1]) {
                'a' => self.token(self.checkString("false", .FALSE)),
                'o' => self.token(self.checkString("for", .FOR)),
                'u' => self.token(self.checkString("fun", .FUN)),
                else => self.token(.IDENTIFIER),
            },
            't' => switch (self.start[1]) {
                'r' => self.token(self.checkString("true", .TRUE)),
                'h' => self.token(self.checkString("this", .THIS)),
                else => self.token(.IDENTIFIER),
            },
            else => self.token(.IDENTIFIER),
        };
    }

    fn checkString(self: *@This(), str: []const u8, ty: TokenType) TokenType {
        if (std.mem.eql(u8, self.start, str)) {
            return ty;
        } else {
            return .IDENTIFIER;
        }
    }

    fn number(self: *@This()) Token {
        while (!self.isAtEnd() and isDigit(self.current[0])) {
            _ = self.advance();
        }
        if (self.current.len > 1 and self.current[0] == '.' and isDigit(self.current[1])) {
            _ = self.advance();
            while (!self.isAtEnd() and isDigit(self.current[0])) {
                _ = self.advance();
            }
        }

        return self.token(.NUMBER);
    }

    fn string(self: *@This()) Token {
        while (!self.isAtEnd() and self.current[0] != '"') {
            if (self.current[0] == '\n') {
                self.line += 1;
            }
            _ = self.advance();
        }
        if (self.isAtEnd()) {
            return self.errorToken("Unterminated string");
        }
        _ = self.advance();
        return self.token(.STRING);
    }

    fn skipWhitespace(self: *@This()) void {
        while (!self.isAtEnd()) {
            switch (self.current[0]) { // basically self.peek()
                ' ', '\r', '\t' => _ = self.advance(),
                '\n' => {
                    self.line += 1;
                    _ = self.advance();
                },
                '/' => if (self.match('/')) {
                    while (!self.isAtEnd() and self.current[0] != '\n') {
                        _ = self.advance();
                    }
                } else {
                    return;
                },
                else => return,
            }
        }
    }

    fn match(self: *@This(), char: u8) bool {
        if (self.isAtEnd()) {
            return false;
        }
        if (self.current[0] != char) {
            return false;
        }

        _ = self.advance();
        return true;
    }

    fn advance(self: *@This()) u8 {
        const ret = self.current[0];
        self.start.len += 1;
        self.current = self.current[1..];
        return ret;
    }

    fn token(self: *@This(), ty: TokenType) Token {
        return .{
            .ty = ty,
            .line = self.line,
            .lexeme = self.start,
        };
    }

    fn errorToken(self: *@This(), msg: []const u8) Token {
        return .{
            .ty = .ERROR,
            .line = self.line,
            .lexeme = msg,
        };
    }

    fn isAtEnd(self: *@This()) bool {
        return self.current.len == 0;
    }

    fn isDigit(c: u8) bool {
        return c >= '0' and c <= '9';
    }

    fn isAlpha(c: u8) bool {
        return (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or c == '_';
    }
};

collector: *Collector,
chunk: Chunk,

pub fn init(collector: *Collector) !Compiler {
    return .{
        .collector = collector,
        .chunk = try Chunk.init(collector),
    };
}

pub fn deinit(self: *@This()) void {
    self.chunk.deinit();
}

pub fn compile(self: *Compiler, source: []const u8) !*Chunk {
    var scanner = Scanner.init(source);

    var line: u32 = 999;
    while (true) {
        const token = scanner.scanToken();
        if (token.line != line) {
            line = token.line;
            std.debug.print("{d:<4} ", .{line});
        } else {
            std.debug.print("|    ", .{});
        }
        std.debug.print("{s:<8} '{s}'\n", .{ @tagName(token.ty), token.lexeme });

        if (token.ty == .EOF) {
            break;
        }
    }

    _ = self;
    return error.CompileError;

    // return &self.chunk;
}

const std = @import("std");
const root = @import("root");

const Collector = root.Collector;
const Chunk = root.Chunk;
const OpCode = Chunk.OpCode;
const Value = root.Value;
