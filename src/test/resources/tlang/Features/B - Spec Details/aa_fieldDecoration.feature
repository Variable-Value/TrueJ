@Ready
@InProgress
Feature: A value name is used to declare a field (TrueJ 0.1)

  All fields must be given a value either in an initialization, in an initializer block, or in every
  constructor. Value names with an initial decoration but no initialization, such as,

      int 'a;

  default to an arbitrary initialization.

  We use either an undecorated or final decorated value name for the final value of a variable in
  executable code. Therefore, when declaring a variable `a`,

      int a;

  or

      int a';

  declares the variable as final, with its value to be provided before the end of object
  construction.

      int 'a = 2; // the value of the variable a is 2, but it can change

      int 'a;     // the value of the variable a is unknown, but it can change

      int b' = 5; // final value, so variable b cannot be modified
      int b = 5;  // equivalent to b' = 5

      int c;      // the value of variable c cannot change once the value is provided;
      or          // and that final value must be provided
      int c';     // during construction

  Using the undecorated form of value names for final values, rather than the explicit
  post-decorated names, makes the code look less cluttered for readability, but runs the risk of
  having beginners, and programmers that primarily work in other procedural languages, misinterpret
  an undecorated final value name for a variable name; for example, the code

      i = 0;

  should be read, not as meaning that the variable `i` gets the value `0`, but as a definition of a
  name for a final value of `0`, that holds for the rest of the scope of the variable `i`. If the
  programmer tries to reuse a value name that they mistake for a variable name, the compiler will
  issue an error, but these errors might be frustrating to the programmer until they reorient their
  thinking. The important thing to remember is that in TrueJ, the variable name is never used except
  as a part of a value name, so if you start to think its a variable name, it is really the name of
  a value that never changes: the variable's final value.

  For beginners, and programmers that primarily work in other procedural languages, there is a
  command-line flag that they may find useful, `-decorateFinal`, to force use of final decoration
  for final values. In that case, undecorated values are forbidden, and

      int b;

  generates an error message at its declaration rather than when its value is modified.


Rule: Final values can be assigned to an undecorated value name

Example: Using undedorated final value names in executable code

  We use the undecorated names `startingA`, `a`, and `b` in the swap() method.

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

Example: But decoration of the names can be forced with an option

  We use the same program as above, but with the command line option `-decorateFinal` to generate an
  error when undecorated value names are coded.

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
  And the error messages are
    """
    line 6:6 for <startingA>: Initialized variable declarations must be decorated
    8:6 for <startingA>: A reference to a value must be a value name: startingA must be decorated
    """

Rule: The scope of a value name ends with the scope of its variable

Example: Using a value name that has been overwritten with another value

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

  Given decorated final value names are required

  Then an invalid compile unit is
    """
    class Swapper2_error {

    int a, b;

    void swap() {
      a = 'b;
      b = 'a;   // OK to use value 'a because the variable a is still in scope
    }

    } // end class
    """
  And the following are in the error messages
    """
    a must be decorated
    b must be decorated
    """

  When an invalid compile unit is
    """
    class Swapper3 {

    int a, b;

    void swap() {
      int startingA = 'a;
      a = 'b;
      b = startingA;
    }
    means: (startingA = 'a && a = 'b && b = startingA;
       // startingA value is out of scope here, outside the method's block,
       // because its variable startingA is declared inside the block

    } // end class
    """

  Then an error message contains
    """
    Variable startingA has not been defined in this scope
    """

  Given decorated final value names are required
  When an invalid compile unit is
    """
    class Swapper3 {

    int a, b;

    void swap() {
      int startingA = 'a;
      a = 'b;
      b = startingA;
    }
    means: startingA = 'a && a = 'b && b = startingA;
       // startingA value is out of scope here, outside the method's block,
       // because its variable startingA is declared inside the block

    } // end class
    """
  Then the following are in the error messages
    """
    <startingA>: Initialized variable declarations must be decorated
    a must be decorated
    8:6 for <startingA>: A reference to a value must be a value name: startingA must be decorated
    b must be decorated
    Variable startingA has not been defined in this scope
    A reference to a value must be a value name: startingA must be decorated
    """

Scenario: A final value defined with one decoration cannot be used with the other

  When an invalid compile unit is
    """
    class DecorationErr1 {

    int a, b;

    void swap() {
      int startingA = 'a;
      a = 'b;
      b = startingA';
      means: startingA' = 'a && a = 'b && b = startingA';
    }
    means: a' = 'b && b = 'a;

    } // end class
    """
   Then the following are in the error messages
    """
    line 8:6 for <startingA'>: A different final decoration, startingA, was defined at line 6
    line 11:6 for <a'>: A different final decoration, a, was defined at line 7
    """

  When an invalid compile unit is
    """
    class DecorationErr2 {

    int a, b;

    void swap() {
      int startingA' = 'a;
      a' = 'b;
      b' = startingA;
      means: startingA = 'a && a = 'b && b' = startingA;
    }
    means: a = 'b && b' = 'a;

    } // end class
    """
  Then the following are in the error messages
    """
    line 8:7 for <startingA>: A different final decoration, startingA', was defined at line 6
    line 9:26 for <a>: A different final decoration, a', was defined at line 7
    """

  When an invalid compile unit is
    """
    class DecorationErr3 {

    int a, b;
    int startingA = 'a;
    int startingB' = 'b;

    void swap() {
      a = startingB;
      b = startingA';
      means: startingA' = 'a && a = startingB && b = startingA';
    }
    means: a = 'b && b = 'a;

    } // end class
    """
   Then the following are in the error messages
    """
    line 8:6 for <startingB>: A different final decoration, startingB', was defined at line 5
    line 9:6 for <startingA'>: A different final decoration, startingA, was defined at line 4
    """

  When An invalid compile unit is
    """
    class RedefinitionErr1 {

    int a, b = 3, c' = 4;

    void swap() {
      a' = b;
      a = 2;
      b = 'a;
      c = 1;
      means: b = 'a && a = 'b;
    }
    means: a' = 'b && b = 'a;

    } // end class
    """
   Then the following are in the error messages
    """
    line 7:2 for <a>: A different final decoration, a', was defined at line 6
    line 8:2 for <b>: The value b has already been defined on line 3
    line 9:2 for <c>: A different final decoration, c', was defined at line 3
    10:22 for <'b>: Value 'b has not been defined for the variable b that was declared at line 3
    """

    When An invalid compile unit is
    """
    class RedefinitionErr2 {

    int a, b;

    void swap() {
      int starting = 'b;
      a = starting;
      starting' = 'a;
      b = starting';
      means: starting' = 'a && a = 'b && b = starting;
    }
    means: a = 'b && b = 'a;

    } // end class
    """
    Then the following are in the error messages
    """
    line 8:2 for <starting'>: A different final decoration, starting, was defined at line 6
    """

  When An invalid compile unit is
    """
    class Swapper_3 {

    int a;
    int b;

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
    Then the following are in the error messages
    """
    19:4 for <a>: Value name a must also be defined in the initial branch
    20:4 for <b'>: Value name b' must also be defined in the initial branch
    21:2 for <}>: The value name b was not defined in the else-clause
    21:2 for <}>: The value name a' was not defined in the else-clause
    23:6 for <a'>: Value a' has not been defined for the variable a that was declared at line 3
    """

  When An invalid compile unit is
    """
    class Swapper_3 {

    int a;
    int b;

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
        a' = a'temp2;
        b = b'temp2;
      }
    }
    means: a = 'b & b' = 'a;

    } // end class
    """
    Then the following are in the error messages
    """
    23:6 for <a>: A different final decoration, a', was defined at line 19
    23:15 for <b'>: A different final decoration, b, was defined at line 20
    """
