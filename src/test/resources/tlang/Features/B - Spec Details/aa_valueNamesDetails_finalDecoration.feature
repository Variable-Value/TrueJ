@Ready
Feature: Final value names may be left undecorated (TrueJ 0.1)

  In this feature we introduce a simpler notation, allowing either `aName'` or `aName` as value
  names to represent the final value of the variable named `aName`. This makes it clear that there
  are no _naked_ variable names at all. Value names are built on variable names, but all names are
  value names. In an object's field declarations, either

      int a;

  or

      int a';

  just declares the variable as final with the default value for an int of zero. We must
  pre-decorate the variable to make it mutable:

      int 'a = 2; // the value of the variable a can change

      int b' = 5; // the value of variable b cannot change
      int b = 5;  // equivalent to b' = 5

  Occasionally, we wish to declare an immutable field whose value is decided later in an
  initializer or constructor. In that case we declare it as mutable but with the `final` modifier:

      final int 'a;

  or

      final int 'a = 1;

  To help programmers get used to the fact that there are no variable names in TrueJ, there is a
  command-line flag, `-decorateFinal`, to force use of final decoration for final values. In that
  case,

      int b;

  generates an error message. Instead, it must be coded as

      int b';

  Using the undecorated form of value names for final values rather than the more explicit
  post-decorated names makes the code look less cluttered, increasing readability, but runs the
  risk of having beginners and programmers that primarily work in other procedural languages
  misinterpret an undecorated final value name for a variable name; for example, the code

      i = 0;

  should be read, not as meaning that the variable `i` gets the value `0`, but as a definition of a
  name for a final value of `0`, and no more variable names can be defined for the scope of the
  variable `i`. The programmer can reference any of the values of `i` that have been defined, but
  if they try to define a new value for `i`, the compiler will issue an error. The important thing
  to remember is that in TrueJ, the variable name is never used except as a part of a value name,
  so if it looks like a variable name it is really the name of a value that never changes, the
  variable's final value.

Rule: Final value names in methods may be either final decorated or undecorated

Example: Final value names in methods may be undecorated

  * A valid compile unit is
    """
    class Swapper {

    int 'a, 'b;

    void swap() {
      int startingA = 'a;
      a = 'b;
      b = startingA;
      means: startingA = 'a && a = 'b && b = startingA;
    }
    means: a = 'b && b = 'a;

    } // end class
    """

  Example: But the identical program gives errors when final decoration is required

    Using the `-decorateFinal` command-line flag requires every final value name to be final decorated, even though the program would otherwise be correct.

  Given decorated final value names are required
  Then an invalid compile unit is
    """
    class Swapper_error {

    int 'a, 'b;

    void swap() {
      int startingA = 'a;
      a = 'b;
      b = startingA;
      means: startingA = 'a && a = 'b && b = startingA;
    }
    means: a = 'b && b = 'a;

    } // end class
    """
  And the error messages contain
    """
    6:6 for <startingA>: This name must be decorated because of the command line option -decorateFinal
    7:2 for <a>: This name must be decorated because of the command line option -decorateFinal
    8:6 for <startingA>: This name must be decorated because of the command line option -decorateFinal
    8:2 for <b>: This name must be decorated because of the command line option -decorateFinal
    9:9 for <startingA>: This name must be decorated because of the command line option -decorateFinal
    9:27 for <a>: This name must be decorated because of the command line option -decorateFinal
    9:37 for <b>: This name must be decorated because of the command line option -decorateFinal
    9:41 for <startingA>: This name must be decorated because of the command line option -decorateFinal
    11:7 for <a>: This name must be decorated because of the command line option -decorateFinal
    11:17 for <b>: This name must be decorated because of the command line option -decorateFinal
    """

Example: Final value names in methods may be final decorated

  * A valid compile unit is
    """
    class Swapper {

    int 'a, 'b;

    void swap() {
      int startingA' = 'a;
      a' = 'b;
      b' = startingA';
      means: startingA' = 'a && a' = 'b && b' = startingA';
    }
    means: a' = 'b && b' = 'a;

    } // end class
    """

Example: The identical program gives no error when final decoration is required

  If final decoration is used for all final values, the program is correct with or without the use of `-decorateFinal` as a command-line flag.

  Given decorated final value names are required
  Then a valid compile unit is
    """
    class Swapper {

    int 'a, 'b;

    void swap() {
      int startingA' = 'a;
      a' = 'b;
      b' = startingA';
      means: startingA' = 'a && a' = 'b && b' = startingA';
    }
    means: a' = 'b && b' = 'a;

    } // end class
    """


Rule: Variable scope does not interfere with final value name decoration

  The scope of a value name starts at its definition and ends at the end of the block where the
  variable was declared. Here we establish that different forms of final decoration are independent
  of that scope.

Example: We reference a field's initial value after overwriting it with undecorated finals

  * A valid compile unit is
    """
    class Swapper2 {

    int 'a, 'b;

    void swap() {
      a = 'b;
      b = 'a;   // OK to use value 'a because the variable a is still in scope
    }

    } // end class
    """

Example: We reference a field's initial value after overwriting it while using final decoration

  Given decorated final value names are required
  * A valid compile unit is
    """
    class Swapper2_error {

    int 'a, 'b;

    void swap() {
      a' = 'b;
      b' = 'a;   // OK to use value 'a because the variable a is still in scope
    }

    } // end class
    """

Example: Scope errors are identified with either decorated or undecorated finals

  When an invalid compile unit is
    """
    class Swapper3 {

    int 'a, 'b;

    void swap() {
      int startingA = 'a;
      a = 'b;
      b = startingA;
    }
    means: startingA = 'a && a = 'b && b = startingA;
       // the value name startingA is out of scope here, outside of the method's block,
       // because its variable is declared inside the block

    } // end class
    """

  Then the error messages contain
    """
    line 10:7 for <startingA>: Variable startingA has not been defined in this scope
    """

  Given decorated final value names are required
  When an invalid compile unit is
    """
    class Swapper3 {

    int 'a, 'b;

    void swap() {
      int startingA' = 'a;
      a' = 'b;
      b' = startingA';
    }
    means: startingA' = 'a && a' = 'b && b' = startingA';
       // the value name startingA' is out of scope here, outside of the method's block,
       // because its variable is declared inside the block

    } // end class
    """
  Then the error messages contain
    """
    line 10:7 for <startingA'>: Variable startingA has not been defined in this scope
    """

Rule: The first definition of a final value sets the required form for all final value names

Example: Simple incorrect final value decorations with fields and local variables

  When an invalid compile unit is
    """
    class DecorationErr2 {

    int 'a, 'b;

    void swap() {
      int startingA' = 'a;
      a' = 'b;
      b' = startingA;
    }
    means: a = 'b && b' = 'a;

    } // end class
    """
  Then the error messages contain
    """
    line 8:7 for <startingA>: A different final decoration startingA' was used at line 6
    10:7 for <a>: A different decoration for final values was used in line 6 for the final value name startingA'
    """

  When an invalid compile unit is
    """
    class DecorationErr3 {

    int 'a, 'b;
    int startingA' = 'a;
    int startingB' = 'b;

    void swap() {
      a' = startingB;
      b' = startingA';
      means: startingA' = 'a && a' = startingB' && b' = startingA;
    }
    means: a' = 'b && b' = 'a;

    } // end class
    """
   Then the error messages contain
    """
    line 8:7 for <startingB>: A different decoration for final values was used in line 4 for the final value name startingA'
    10:52 for <startingA>: A different decoration for final values was used in line 4 for the final value name startingA'
    """

Example: Undecorated final values are incorrectly referenced with decorations

  When an invalid compile unit is
    """
    class DecorationErr1 {

    int 'a, 'b;

    void swap() {
      int startingA = 'a;
      a = 'b;
      b = startingA';
      means: startingA = 'a && a = 'b && b = startingA;
    }
    means: a' = 'b && b = 'a;

    } // end class
    """
   Then the error messages contain
    """
    line 8:6 for <startingA'>: A different decoration for final values was used in line 6 for the final value name startingA
    11:7 for <a'>: A different decoration for final values was used in line 6 for the final value name startingA
    """

Example: A final value is overwritten with the wrong final decoration

  When An invalid compile unit is
    """
    class RedefinitionErr1 {

    int 'a, b' = 3, c' = 4;

    void swap() {
      a' = b';
      a = 2;
      b' = 'a;
      c = 1;
      means: b = 'a && a = 'b;
    }
    means: a' = 'b && b = 'a;

    } // end class
    """
   Then the error messages contain
    """
    line 7:2 for <a>: a' received a final value at line 6, so it cannot receive a new value
    8:2 for <b'>: The value b' has already been defined on line 3
    9:2 for <c>: c' received a final value at line 3, so it cannot receive a new value
    10:9 for <b>: A different decoration for final values was used in line 3 for the final value name b'
    10:19 for <a>: A different decoration for final values was used in line 3 for the final value name b'
    10:23 for <'b>: Value 'b has not been defined for the variable b that was declared at line 3
    12:12 for <'b>: Value 'b has not been defined for the variable b that was declared at line 3
    12:18 for <b>: A different decoration for final values was used in line 3 for the final value name b'
    """

Example: Local variables are referenced with the wrong final decoration

    When An invalid compile unit is
    """
    class RedefinitionErr2 {

    int a, b;

    void swap() {
      int starting = b;
      starting' = a;
      means: starting' = a;
    }

    }
    """
    Then the error messages contain
    """
    line 7:2 for <starting'>: starting received a final value at line 6, so it cannot receive a new value
    8:9 for <starting'>: A different decoration for final values was used in line 3 for the final value name a
    """

Example: Conditionals give the correct error messages

  When An invalid compile unit is
    """
    class Swapper_3 {

    int 'a;
    int 'b;

    void validSwap() {
      if ('a = 'b) {
        a'temp1 = 'b;
        a' = a'temp1;
        b = a'temp1;
      } else {
        a'temp1 = 'b;
        a' = a'temp1;
        b = 'a;
      }
    }
    means: a = 'b & b' = 'a;

    } // end class
    """
    Then the error messages contain
    """
    line 10:4 for <b>: A different decoration for final values was used in line 9 for the final value name a'
    14:4 for <b>: A different decoration for final values was used in line 9 for the final value name a'
    17:7 for <a>: A different decoration for final values was used in line 9 for the final value name a'
    """

Example: A more complicated if-then-else example

  When An invalid compile unit is
    """
    class Swapper_3 {

    int 'a;
    int 'b;

    void validSwap() {
      if ('a = 'b) {
        a'temp1 = 'b;
        a'temp2 = a'temp1;
        b'temp1 = 'a;
        b'temp2 = b'temp1;
        a' = a'temp2;
        b = b'temp2;
      } else {
        a'temp2 = 'b; // note the different order of assignment here to the variables a and b
        a'temp1 = a'temp2;
        b'temp2 = 'a;
        b'temp1 = b'temp2;
        a = a'temp2;
        b' = b'temp2;
      }
    }
    means: a' = 'b && b' = 'a;

    } // end class
    """
    Then the error messages contain
    """
    line 13:4 for <b>: A different decoration for final values was used in line 12 for the final value name a'
    19:4 for <a>: A different decoration for final values was used in line 12 for the final value name a'
    19:4 for <a>: Value name a must also be defined in the initial branch of the conditional statement
    20:4 for <b'>: Value name b' must also be defined in the initial branch of the conditional statement
    21:2 for <}>: The value name b was not defined in the else-clause
    21:2 for <}>: The value name a' was not defined in the else-clause
    23:18 for <b'>: The value name b' is not available in this scope (variable b has the value named $T$ at this point)
    """

Example: Invalid reference to a final value in an if-then-else then means statement

  When An invalid compile unit is
    """
    class CheckMeans {

    int 'a;
    int 'b;

    void validSwap() {
      if ('a = 'b) {
        a' = 3;
        b = 3;
      } else {
        a = 4;
        b = 4;
      }
    }
    means: a = 'b & b = 'a;

    } // end class
    """
    Then the error messages contain
    """
    line 9:4 for <b>: A different decoration for final values was used in line 8 for the final value name a'
    11:4 for <a>: A different decoration for final values was used in line 8 for the final value name a'
    11:4 for <a>: Value name a must also be defined in the initial branch of the conditional statement
    12:4 for <b>: A different decoration for final values was used in line 8 for the final value name a'
    13:2 for <}>: The value name a' was not defined in the else-clause
    15:7 for <a>: A different decoration for final values was used in line 8 for the final value name a'
    15:16 for <b>: A different decoration for final values was used in line 8 for the final value name a'
    """

Example: Complex if-then-else with errors in final means

  When An invalid compile unit is
    """
    class Swapper_3 {

    int 'a;
    int 'b;

    void validSwap() {
      if ('a = 'b) {
        a'temp1 = 'b;
        a'temp2 = a'temp1;
        b'temp1 = 'a;
        b'temp2 = b'temp1;
        a' = a'temp2;
        b = b'temp2;
      } else {
        a'temp2 = 'b; // note the different order of assignment here to the variables a and b
        a'temp1 = a'temp2;
        b'temp2 = 'a;
        b'temp1 = b'temp2;
        a = a'temp2;
        b = b'temp2;
      }
    }
    means: a = 'b & b = 'a;

    } // end class
    """
    Then the error messages contain
    """
    line 13:4 for <b>: A different decoration for final values was used in line 12 for the final value name a'
    19:4 for <a>: A different decoration for final values was used in line 12 for the final value name a'
    19:4 for <a>: Value name a must also be defined in the initial branch of the conditional statement
    20:4 for <b>: A different decoration for final values was used in line 12 for the final value name a'
    21:2 for <}>: The value name a' was not defined in the else-clause
    23:7 for <a>: A different decoration for final values was used in line 12 for the final value name a'
    23:16 for <b>: A different decoration for final values was used in line 12 for the final value name a'
    """

Example: Assorted final value name problems

  When An invalid compile unit is
    """
    class AllTrue {

    boolean 'a;
    boolean 'b;
    boolean 'c;

    boolean allTrue';

    void checkAll() {
      allTrue'reset = true;
      allTrue'thruA = allTrue'reset && a';
      allTrue'thruB = allTrue'thruA && b;
      allTrue       = allTrue'thruB && c;
    }
    means: allTrue = (a && b && c);

    } // end class
    """
    Then the error messages contain
    """
    line 10:2 for <allTrue'reset>: allTrue' received a final value at line 7, so it cannot receive a new value
    11:18 for <allTrue'reset>: Value allTrue'reset has not been defined for the variable allTrue that was declared at line 7
    11:2 for <allTrue'thruA>: allTrue' received a final value at line 7, so it cannot receive a new value
    12:18 for <allTrue'thruA>: Value allTrue'thruA has not been defined for the variable allTrue that was declared at line 7
    12:35 for <b>: A different decoration for final values was used in line 7 for the final value name allTrue'
    12:2 for <allTrue'thruB>: allTrue' received a final value at line 7, so it cannot receive a new value
    13:18 for <allTrue'thruB>: Value allTrue'thruB has not been defined for the variable allTrue that was declared at line 7
    13:35 for <c>: A different decoration for final values was used in line 7 for the final value name allTrue'
    13:2 for <allTrue>: allTrue' received a final value at line 7, so it cannot receive a new value
    15:7 for <allTrue>: A different decoration for final values was used in line 7 for the final value name allTrue'
    15:18 for <a>: A different decoration for final values was used in line 7 for the final value name allTrue'
    15:23 for <b>: A different decoration for final values was used in line 7 for the final value name allTrue'
    15:28 for <c>: A different decoration for final values was used in line 7 for the final value name allTrue'
    """


Rule: An intial-decorated field may be final-decorated in a methods first reference to it

Example: Undecorated final values may be the first reference to an initial-decorated field

  * a valid compile unit is
    """
    class TestUndecoratedInitialField {

    int 'a = 3;
    int 'b;

    void testUndecorated() {
      int i = a;
      int j = b;
    }

    }
    """

Example: Decorated final values may be the first reference to an initial-decorated field

  * a valid compile unit is
    """
    class TestUndecoratedInitialField {

    int 'a = 3;
    int 'b;

    void testUndecorated() {
      int i' = a';
      int j' = b';
    }

    }
    """

Example: The decoration of a final field's first use must match that of its declaration

  When An invalid compile unit is
    """
    class FirstUseMissmatch1 {

    int a;

    void test() {
      int newA = 'a;
    }

    } // end class
    """
    Then the error messages contain
    """
    Value 'a has not been defined for the variable a that was declared at line 3
    """
