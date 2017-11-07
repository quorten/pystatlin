/* To show how awesome our code compactness is, we won't include any
   header files at all.  */
#define EOF (-1)
int getchar (void);
int putchar (int c);
void abort (void);
#define ABS(x) (((x) < 0) ? -(x) : (x))

/* Simple infix notation calculator with operator precedence and
   parenthetical groupings.  Uses only integer arithmetic and no
   dynamic memory allocation.

   This file is in the public domain.

   Compile with `-DDEBUG' to show the internal stack manipulation used
   to perform the computation.

   Note that you'll need a C99 compiler to be able to compile the
   parse patterns structure, as it uses union member initializers.
   Otherwise, you may end up converting it to a hexidecimal table by
   hand.

   This program is also a great example of the kinds of things that
   can be done in C without `malloc ()'.  On one hand, yeah, not much,
   but on the other hand, it's good enough to be able to write a
   rudimentary compiler.  (It's also straightforward to write this
   program in assembly language/machine code, though straightforward
   does not mean easy.)  */

/********************************************************************/
/* The following definitions are of most interest for those seeking to
   expand the memory capabilities of this calculator.  Index/memory
   types must be declared to be large enough to contain their
   associated maximum values.  */

/* "calculator long," supposed to be 32 bits by default.  The actual
   calculator reserves one bit for control information and only uses
   31 bits for numeric representation.  */
typedef int CLong;
typedef unsigned int UCLong;

/* Maximum number of digits (i.e. in base 10) that a "calculator long"
   may contain.  The printed output may have this many digits,
   inclusive.  However, the input must not meet or exceed this number
   of digits.  */
#define MAX_DIGITS (10)
typedef unsigned char DigitsIdx;

/* STACK_MAX = one beyond the maximum number of elements the stack can
   contain.  Must be a power of two for the sake using STACK_MASK for
   simple memory bounds computation.  Note that the only cause of
   stack overflows is the use of too many parentheses, so a calculator
   without support for parentheses is also a calculator that cannot
   get a stack overflow.  */
#define STACK_MAX (32)
#define STACK_MASK (STACK_MAX - 1)
typedef unsigned char StackIdx;

typedef struct StackMem_tag {
  CLong is_op : 1;
  CLong val : 31;
} StackMem;

StackMem stack[STACK_MAX];
StackIdx stack_size = 0;

/********************************************************************/

typedef unsigned char BoolMem;

typedef enum OpType_tag {
  OP_ADD = 1,
  OP_SUB = 2,
  OP_MUL = 4,
  OP_DIV = 8,
  OP_PSH = 16, /* push */
  OP_POP = 32,
  OP_OUT = 64,
  /* operator classes */
  OP_PHP = OP_PSH | OP_POP, /* push and pop operators */
  OP_UNA = OP_PHP | OP_OUT, /* unary operators */
  OP_TRM = OP_ADD | OP_SUB, /* term operators */
  OP_FAC = OP_MUL | OP_DIV, /* factor operators */
  OP_BIN = OP_TRM | OP_FAC, /* binary operators */
  OP_ALL = OP_UNA | OP_BIN,
} OpType;
typedef unsigned char OpTypeMem;

/* These separate enumerations for reduction operations are here only
   for the sake of efficiency.  */
typedef enum ReduceOp_tag {
  R_OUT,
  R_FAC,
  R_TRM,
} ReduceOp;

typedef struct OpTblMem_tag {
  char c;
  OpTypeMem op;
} OpTblMem;

#define OP_TBL_SZ (7)
typedef unsigned char OpTblIdx;
const OpTblMem op_tbl[OP_TBL_SZ] = {
  { '+', OP_ADD },
  { '-', OP_SUB },
  { '*', OP_MUL },
  { '/', OP_DIV },
  { '(', OP_PSH },
  { ')', OP_POP },
  { '=', OP_OUT },
};

enum ParseOp_tag {
   /* "Ignore" matching pattern, which means wait for more input
      before an actual action can be performed.  */
  PAR_IGNORE = 1,
  /* Delete elements from matching pattern.  Often times this means
     that some invalid syntax has been found, and the deletes are one
     way to transform it into correct syntax.

     Delete uses bitfields from `parse_op' to specify symbols to
     delete.  1 = first from left, 2 = second from left, 4 = third
     from left, and so on.  */
  PAR_DELETE,
  /* Pass control to a syntax subprocessor for more detailed
     evaluation.  The index of the subprocessor is specified in
     `parse_op'.  */
  PAR_SUBPROC,
  /* Perform a "reduction computation" on a matched pattern, resulting
     in less symbols on the stack.  The index of the function to
     perform is specified in `parse_op'.  This can be thought of as a
     combination of computation and deletion.  */
  PAR_REDUCE,
  /* Insert symbols onto the stack, often times to correct incorrect
     grammar.  This may require prompting the user to resolve
     ambiguity.  This is never actually used in the calculator
     program.  */
  PAR_INSERT,
  /* "exact" rules: These rules must match the entire contents of the
     stack, not just the top, unlike the previous rule types that
     could simply match the shortest pattern that satisfies the
     rules.  */
  PAR_EXACT = 8,
  PAR_EIGNORE = 9,
  PAR_EDELETE,
  PAR_ESUBPROC,
  PAR_EREDUCE,
  PAR_EINSERT,
};
typedef unsigned char ParseOpMem;

typedef struct ParseHeader_tag {
  UCLong pattern_len : 3;
  UCLong parse_op : 4;
  UCLong op_params : 8;
  /* UCLong padding : 17; */
} ParseHeader;

typedef union ParseMem_tag {
  ParseHeader h; /* header */
  StackMem p; /* pattern */
} ParseMem;

/* Warning: Putting parentheses around these expressions is likely to
   break them.  I haven't tried doing so myself, though.  */
#define H(a,b,c) {.h={a,b,c}}
#define NUMBER {.p={0,0}}
#define P(a) {.p={1,a}}

/* Now, you're wondering, why are these pattern tables so complicated
   for such a simple grammar?  Well, I'll tell you precisely the
   answer.  In conventional parsers that are generated from grammars,
   if there are any deviations from the correct grammar, the parser is
   written to just "throw its hands up in the air" and say "Oh, I
   can't continue."  I cannot understate this fact, that makes the
   generated code A LOT simpler.  It also makes error messages coming
   from the compiler much less insightful.  Also note that this makes
   the grammar response more similar to that of a simple pocket
   calculator where typing a second operator in a row overrides the
   previous operator.

   In our particular case, we only use the extra rules to delete
   invalid syntax early on so that the later parsing stages only need
   to consider valid syntax along with a few invalid syntaxes.  An
   invariant, so to say.  A common alternative is to bail out as soon
   as a syntax error is found.

   Also, sorting the matching rules to put invalid rules at the end
   and frequent valid rules near the top can speed up general parsing.

   The patterns must be sorted in ascending order of length in order
   for the parsing machinery to process the rules correctly.

   Note: See the comment on the `parse_stack_top ()' function for
   additional explanation.  */

#define NUM_PARSE_PATTERNS (33)
#define PARSE_TBL_SIZE (100)
typedef unsigned char ParseIdx;
const ParseMem parse_patterns[] = {
  /* subproc #0 (top level) */
  H(1,PAR_SUBPROC,1), NUMBER,
  H(1,PAR_SUBPROC,2), P(OP_BIN),
  H(1,PAR_SUBPROC,3), P(OP_PSH),
  H(1,PAR_SUBPROC,4), P(OP_POP),
  H(1,PAR_SUBPROC,5), P(OP_OUT),

  /* subproc #1 NUMBER */
  H(1,PAR_EIGNORE,0), NUMBER,
  H(2,PAR_IGNORE,0), P(OP_PSH), NUMBER,
  H(2,PAR_DELETE,1), NUMBER, NUMBER,
  H(3,PAR_IGNORE,0), NUMBER, P(OP_TRM), NUMBER,
  H(3,PAR_REDUCE,R_FAC), NUMBER, P(OP_FAC), NUMBER, /* -> NUMBER */

  /* subproc #2 P(OP_BIN) */
  H(1,PAR_EDELETE,1), P(OP_BIN),
  H(2,PAR_EIGNORE,0), NUMBER, P(OP_TRM),
  H(2,PAR_IGNORE,0), NUMBER, P(OP_FAC),
  H(2,PAR_DELETE,2), P(OP_PSH), P(OP_BIN),
  H(2,PAR_DELETE,1), P(OP_BIN), P(OP_BIN),
  H(3,PAR_IGNORE,0), P(OP_PSH), NUMBER, P(OP_TRM),
  H(4,PAR_REDUCE,R_TRM), NUMBER, P(OP_TRM), NUMBER, P(OP_TRM),
    /* -> NUMBER, P(OP_TRM) */

  /* subproc #3 P(OP_PSH) */
  H(1,PAR_EIGNORE,0), P(OP_PSH),
  H(2,PAR_IGNORE,0), P(OP_BIN), P(OP_PSH),
  H(2,PAR_IGNORE,0), P(OP_PSH), P(OP_PSH),
  H(2,PAR_DELETE,2), NUMBER, P(OP_PSH),

  /* subproc #4 P(OP_POP) */
  H(1,PAR_EDELETE,1), P(OP_POP),
  H(2,PAR_EDELETE,2), NUMBER, P(OP_POP),
  H(2,PAR_DELETE,1|2), P(OP_PSH), P(OP_POP), /* valid! */
  H(2,PAR_DELETE,1), P(OP_BIN), P(OP_POP),
  H(3,PAR_DELETE,1|4), P(OP_PSH), NUMBER, P(OP_POP), /* valid! */
  H(4,PAR_REDUCE,R_TRM), NUMBER, P(OP_TRM), NUMBER, P(OP_POP),
    /* -> NUMBER, P(OP_POP) */

  /* subproc #5 P(OP_OUT) */
  H(1,PAR_EDELETE,1), P(OP_OUT),
  H(2,PAR_EREDUCE,R_OUT), NUMBER, P(OP_OUT), /* clears stack */
  H(2,PAR_DELETE,1), P(OP_PSH), P(OP_OUT),
  H(2,PAR_DELETE,1), P(OP_BIN), P(OP_OUT),
  H(3,PAR_DELETE,1), P(OP_PSH), NUMBER, P(OP_OUT),
  H(4,PAR_REDUCE,R_TRM), NUMBER, P(OP_TRM), NUMBER, P(OP_OUT),

};

/* Indices to the beginning of the subprocess patterns corresponding
   to the index of this table.  The very last index simply marks the
   limit of the last table, that is, one index beyond its last
   element.  */
const ParseIdx subproc_tbl[] = {
  0, 10, 26, 49, 60, 80, 100
};

#undef H
#undef NUMBER
#undef P

/********************************************************************/

void putnum (CLong num);
void check_stack_overflow (void);
void debug_stack (void);
void lex_input (void);
void parse_stack_top (void);
void exec_reduction (const ParseHeader header);

int
main (void)
{
  lex_input ();
  return 0;
}

void
putnum (CLong num)
{
  char outbuf[MAX_DIGITS];
  register DigitsIdx i = MAX_DIGITS;
  if (num < 0) putchar ('-');
  do {
    register const short digit = num % 10;
    i--;
    outbuf[i] = '0' + ABS(digit);
    num = (num - digit) / 10;
  } while (num != 0 && i > 0);
  while (i < MAX_DIGITS)
    putchar (outbuf[i++]);
}

void
check_stack_overflow (void)
{
  stack_size &= STACK_MASK;
  if (stack_size == 0)
    { putchar ('A'); abort (); }
}

void
debug_stack (void)
{
  register StackIdx i;
  putchar ('#');
  for (i = 0; i < stack_size; i++) {
    putchar (' ');
    if (stack[i].is_op) {
      register OpTblIdx j;
      for (j = 0; j < OP_TBL_SZ; j++) {
        if (op_tbl[j].op == stack[i].val)
          { putchar (op_tbl[j].c); break; }
      }
    } else
      putnum (stack[i].val);
  }
  putchar ('\n');
}

/* Lexical analyze standard input, push tokens onto the token stack,
   and invoke `parse_stack_top ()' every time a token has been
   successfully read.  */
void
lex_input (void)
{
  register int c;
  CLong read_num = 0;
  DigitsIdx read_num_mult = 0;
  while ((c = getchar ()) != EOF) {
    if (c >= '0' && c <= '9') { /* digit */
      /* read_num *= 10; */
      read_num = (read_num << 3) + (read_num << 1);
      read_num += c - '0';
      read_num_mult++;
      if (read_num_mult >= MAX_DIGITS)
        { putchar ('B'); abort (); }
      continue;
    } else if (read_num_mult > 0) {
      stack[stack_size].is_op = 0;
      stack[stack_size++].val = read_num;
      check_stack_overflow ();
      read_num = 0; read_num_mult = 0;
      parse_stack_top ();
    }
    if (c == ' ' || c == '\t' || c == '\n') /* whitespace */
      continue;
    {
      register OpTblIdx i;
      for (i = 0; i < OP_TBL_SZ; i++) {
        if (c == op_tbl[i].c) {
          stack[stack_size].is_op = 1;
          stack[stack_size++].val = op_tbl[i].op;
          check_stack_overflow ();
          parse_stack_top ();
          break;
        }
      }
    }
    /* else */
    /* ignore, discard unknown symbols */
  }
}

/* Parse and pattern match on the top of the stack, then execute
   commands from matched rules.  Since only shallow patterns are
   parsed off the top of the stack, this function must be called every
   time a token is successfully read.

   General idea of the parser: You start by looking for a rule match,
   and if one is found, you perform the corresponding action.  Then
   you repeat in a loop to match as many rules as possible until there
   are no more actions you can perform.  For example:

   1 + 3 * (4
   1 + 3 * (4 + 5
   1 + 3 * (4 + 5)
   1 + 3 * (9)
   1 + 3 * 9
   1 + 27
   1 + 27 =
   28 =
   [NIL]

   This means you'll either end up with an empty stack or the last
   possible rule you could execute was an "ignore" rule, meaning you
   have to fetch more input to continue.  Valid grammar strings will
   tend to have their elements ignored when the input is in progress,
   until the input is sufficiently long for the pattern to be matched
   and computed on.  You should never match two ignore rules within
   the same iteration.  If you do, that's an internal error.
   Likewise, you should never end an iteration with no rule matches if
   there are still symbols on the stack.  Again, that's another
   internal error.  */
void
parse_stack_top (void)
{
  ParseIdx num_ignores = 0;
#ifdef DEBUG
  debug_stack ();
#endif
  while (stack_size > 0 && num_ignores == 0) {
#ifdef DEBUG
    BoolMem stack_changed = 0;
#endif
    BoolMem pattern_matched = 0;
    ParseIdx i = 0;
    ParseIdx parse_tbl_limit = subproc_tbl[1];
    num_ignores = 0;
    /* Note that the commented out condition is indeed a loop
       condition, but it is already enforced efficiently by the code
       internal to the loop.  */
    while (/* !pattern_matched && */ i < parse_tbl_limit) {
      const ParseHeader header = parse_patterns[i++].h;
      const ParseOpMem simple_parse_op = header.parse_op & ~PAR_EXACT;
      const ParseIdx j = i + header.pattern_len;
      StackIdx spos = stack_size - header.pattern_len;
      if (header.pattern_len > stack_size)
        break; /* The pattern is larger than the stack contents.  */
      if ((header.parse_op & PAR_EXACT) &&
          header.pattern_len != stack_size)
        { i = j; continue; }
      pattern_matched = 1;
      for (; i < j; i++, spos++) {
        const StackMem pat = parse_patterns[i].p;
        const StackMem smem = stack[spos];
        if ((pat.is_op != smem.is_op) ||
            (pat.is_op && !(pat.val & smem.val)))
          { pattern_matched = 0; break; }
      }
      if (!pattern_matched)
        { i = j; continue; }
      switch (simple_parse_op) {
      case PAR_IGNORE:
        num_ignores++;
        break;
      case PAR_DELETE:
        {
          register StackIdx i, j;
          register StackIdx spos = stack_size - header.pattern_len;
          for (i = 0, j = 0; i < header.pattern_len; i++) {
            if (j != i)
              stack[spos+j] = stack[spos+i];
            if (!(header.op_params & (1 << i)))
              j++;
          }
          stack_size = spos + j;
#ifdef DEBUG
          stack_changed = 1;
#endif
          break;
        }
      case PAR_SUBPROC:
        i = subproc_tbl[header.op_params];
        parse_tbl_limit = subproc_tbl[header.op_params+1];
        /* Matching a PAR_SUBPROC pattern does not count as it is only
           a sub-match.  */
        pattern_matched = 0;
        continue;
      case PAR_REDUCE:
        exec_reduction (header);
#ifdef DEBUG
        stack_changed = 1;
#endif
        break;
      case PAR_INSERT:
        putchar ('C'); abort (); /* not implemented */
        break;
      default:
        putchar ('D'); abort (); /* This should never happen.  */
        break;
      }
      break;
    }
#ifdef DEBUG
    if (stack_changed) debug_stack ();
#endif
    if (!pattern_matched || num_ignores > 1) {
      /* Internal patterns error detected.  This should not happen
         when the patterns are properly defined to cover all
         possibilities and only match once for each.  */
      putnum (i); putchar (' ');
      putnum (pattern_matched); putchar (' ');
      putnum (num_ignores); putchar (' ');
      putchar ('E'); abort ();
    }
  }
}

/* Execute a matched reduction, i.e. computation.  */
void
exec_reduction (const ParseHeader header)
{
  switch (header.op_params) {
  case R_OUT:
    if (stack[0].is_op)
      { putchar ('F'); abort (); } /* This should never happen with
                                      correct parse patterns.  */
    putnum (stack[0].val); putchar ('\n');
    stack_size = 0;
    break;
  case R_FAC:
    {
      if (!stack[stack_size-2].is_op)
        { putchar ('G'); abort (); } /* This should never happen with
                                        correct parse patterns.  */
      {
	const OpTypeMem op = stack[stack_size-2].val;
	if (op == OP_MUL)
	  stack[stack_size-3].val *= stack[stack_size-1].val;
	else if (op == OP_DIV) /* ignore (i.e. blow up) on errors */
	  stack[stack_size-3].val /= stack[stack_size-1].val;
	else { putchar ('H'); abort (); } /* This should never happen.  */
	stack_size -= 2;
      }
      break;
    }
  case R_TRM:
    {
      if (!stack[stack_size-3].is_op)
        { putchar ('I'); abort (); } /* This should never happen with
                                        correct parse patterns.  */
      {
	const OpTypeMem op = stack[stack_size-3].val;
	if (op == OP_ADD)
	  stack[stack_size-4].val += stack[stack_size-2].val;
	else if (op == OP_SUB)
	  stack[stack_size-4].val -= stack[stack_size-2].val;
	else { putchar ('J'); abort (); } /* This should never happen.  */
	stack[stack_size-3] = stack[stack_size-1];
	stack_size -= 2;
      }
      break;
    }
  default:
    putchar ('K'); abort (); /* This should never happen.  */
    break;
  }
}
