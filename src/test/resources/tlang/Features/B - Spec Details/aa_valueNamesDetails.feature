@Ready
Feature: Value names - end to end details test (T Language 0.1)

  This feature specification tests additional cases and options of the features
  as specified in the file aa2_valueNamesEndToEnd.feature. That file tests all
  the major facilities for the feature aa_valueNames. This one contains extra
  tests that clarify more of the details of the way things will and will not
  work.

Scenario: The string of characters $T$ is not allowed in identifiers

    In order to translate the T language to Java, we must have the ability to
    create names and other character sequences that do not duplicate those that
    the programmer writes. Therefore, we forbid a particular string of
    characters, $T$, from ever being used in the T language, freeing us to
    generate names and any other sequences of Java code without worry.

  When an invalid compile unit is
    """
    class Swap$T$Error {

    int 'a, 'b;

    void swap() {
      int startingA' = 'a;
      a' = 'b;
      b' = startingA';
    }
    means: a' = 'b && b' = 'a;

    } // end class
    """

  Then the only error message contains
  """
  error at line 1:6 for <Swap$T$Error>: $T$ is reserved for T language internal use only
  """


  When an invalid compile unit is
  """
  class SwapError1 {

  int 'a, 'b;

  void swap() {
    int 'starting = 'a;
    starting'$T$ = 'b;
    b' = 'starting;
    starting' = starting'$T$;
    a' = starting';
  }
  means: a' = 'b && b' = 'a;

  } // end class
  """

  Then the error messages contain
    """
    7:2 for <starting'$T$>: $T$ is reserved for T language internal use only
    9:14 for <starting'$T$>: $T$ is reserved for T language internal use only

    """

  When an invalid compile unit is
    """
    class SwapError2 {

    int 'a$T$=0, 'b=1;

    void swap() {
      int startingA' = 'a$T$;
      a$T$' = 'b;
      b' = startingA';
    }
    means: a$T$' = 'b && b' = 'a$T$;

    } // end class
    """
  Then the error messages contain
    """
    line 3:4 for <'a$T$>: $T$ is reserved for T language internal use only
    6:19 for <'a$T$>: $T$ is reserved for T language internal use only
    7:2 for <a$T$'>: $T$ is reserved for T language internal use only
    10:7 for <a$T$'>: $T$ is reserved for T language internal use only
    10:26 for <'a$T$>: $T$ is reserved for T language internal use only
    """

Scenario: A Type name cannot be decorated when it is declared

  Declaration of classes and other types must not be decorated because the definition of a type
  can never change. This error leads to a cascade of other errors as the parser attempts to locate
  a valid starting point for processing.

  When an invalid compile unit is
  """
  class SwapError2' {

  int 'a, 'b;

  void swap() {
    int starting' = 'a;
    a' = 'b;
    b' = starting';
  }
  means: a' = 'b && b' = 'a;

  } // end class
  """

  Then the error messages contain
    """
    mismatched input 'SwapError2'' expecting UndecoratedIdentifier in rule t_classDeclaration
    line 5:0 for <[@14,34:37='void',<60>,5:0]>: extraneous input 'void'
    line 7:2 for <[@31,72:73='a'',<74>,7:2]>: extraneous input 'a''
    line 8:2 for <[@38,83:84='b'',<74>,8:2]>: extraneous input 'b''
    line 9:0 for <[@45,99:99='}',<85>,9:0]>: extraneous input '}'
    line 12:0 for <[@65,129:129='}',<85>,12:0]>: extraneous input '}'
    """
#TODO
#Scenario:  All static fields must be final.
#
#  This is because all instances of a class can access its static fields, making a classes mutable
#  static fields a part of the state of its instances. In the future, we might make allowance for
#  mutable static fields that are irrelevant to the objects purpose, with only operational or
#  non-functional purposes, such as logging, or reordering items in a list.

Scenario: Initial values of a variable must be correctly decorated

    In order to provide consistency throughout the various places that methods may be declared and
    defined, the initial value of any fields must be pre-decorated. Note that objects are always
    created as consistent so its fields always have values; even optional fields have a null value.
    That means that even if a new value is assigned to one of them before the value at entry is
    used, the assigned value will always be middle- or post-decorated. (When we get to construtors,
    we will even insist on this when setting the value of a final field.)

  When an invalid compile unit is
    """
    class SwapError3 {

    int 'a, 'b;

    void swap() {
      int startingA' = a'current; // invalid because the initial value of a is 'a
      b' = startingA';
      a' = 'a;
      means: startingA' = 'a && a' = 'b && b' = startingA';
    }
    means: a' = 'b && b' = 'a;

    } // end class

    """
  Then the only error message contains
    """
    Value a'current has not been defined
    """

  When an invalid compile unit is
    """
    class SwapError4 {

    int 'a, 'b;

    void swap() {
      int startingA' = 'a;
      'a = 'b; // cannot change initial value 'a because fields already have a value
      b' = startingA';
      means: startingA' = 'a && a' = 'b && b' = startingA';
    }
    means: a' = 'b && b' = 'a;

    } // end class

    """
  Then the only error message contains
    """
    The value 'a has already been defined on line 3
    """

### TODO: Scenario: The final value name of all fields must be final-decorated
  #
  #  To ensure that a method's final meaning can be used in calling programs and consistently compared
  #  against requirements imposed in super classes and interfaces, we insist that all field value names
  #  be final-decorated at the end of the method. To be more specific, every field must have a
  #  final-decorated value name by the termination point of every path through the program unless an
  #  Exception is thrown.
  #
  #  When an invalid compile unit is
  #  """
  #  class SwapErrorXXX {
  #
  #  int a, b;
  #
  #  void swap() {
  #    int startingA' = 'a;
  #    a' = 'b;
  #    b'last = startingA';
  #    means: startingA' = 'a && a' = 'b && b'last = startingA';
  #  }
  #  means: a' = 'b && b'last = 'a;
  #
  #  } // end class
  #
  #  """
  #  ### TODO: RED/GREEN TEST
  #    Then the only error message contains
  #    """
  #    The final value of field b must be b'
  #  """

Rule: Value names may only refer to one value within their scope

    Within its scope, we need all uses of a single value-name to refer to a
    single value, so it may not be assigned new values as though it were a
    variable name.

Example: Attempting to give two values to the value-name allTrue'temp

  When an invalid compile unit is
    """
    class AllTrue2 { // invalid class

    boolean 'a, 'b, 'c;

    boolean 'allTrue;

    void checkAll() {
      allTrue'reset = true;
      allTrue'temp  = allTrue'reset && 'a;
      allTrue'temp  = allTrue'temp  && 'b; // error here
      allTrue'      = allTrue'temp  && 'c;
    }
    means: allTrue' = 'a && 'b && 'c;

    } // end class
    """

  Then the only error message contains "allTrue'temp has already been defined on line 9"

Scenario: A single valid fact can be proven

  * A valid compile unit is
    """
    class SwapAgain1 {

    int 'a, 'b;

    void swap() {
      int startingA' = 'a;
      a' = 'b;
      b' = startingA';
    }
    means:  b' = 'a;

    } // end class
    """


Scenario: The prover detects a single invalid fact

  When an invalid compile unit is
    """
    class SwapAgain2 {

    int 'a, 'b;

    void swap() {
      int startingA' = 'a;
      a' = 'b;
      b' = a'; // should be startingA', not a', so expect an error
    }
    means:  b' = 'a;

    } // end class
    """

  Then the only error message contains
    """
    The code does not support the proof of the statement: b' = 'a
    """


Scenario: Priority (stikiness) of && and || translate to the Prover correctly

    Make sure that the need for parentheses for conjunctions and disjunctions do not cause any
    problems when sending code to the prover. Because the prover is written in Prolog and the
    priorities of the /\ and \/ operators are user defined there, we need to ensure that the
    semantics of the code remains the same. We must either code the provers operator priority for /\
    and \/ carefully or insert extra parentheses before sending code to the prover.

  * A valid compile unit is
    """
    class SwapAgain3 {

    int 'a, 'b;

    void swap() {
      int startingA' = 'a;
      a' = 'b;
      b' = a'; // should be = startingA'; so expect an error
    }
    means: true || a' = 'b && b' = 'b;
      /* In TrueJ, like Java, this is interpreted as
           true || ( a' = 'b && b' = 'b ) which is always true even though b' = 'b is false

         If the statement were interpreted by the prover as
         ( true || a' = 'b ) && b' = 'b it would be false
      */

    } // end class
    """

Scenario: TODO: Assignment of an equality test requires the equality test to be parenthesized

  The use of the equality symbol = for both assignment and equality testing is normally clear, but
  because assignment is right-associative and equality is left-associative there is a possibility
  for confusion when assigning the result of an equality test.

      boolean a = b = c    could be misinterpreted as chained assignment or conjunctive equality
      boolean a = (b = c)  is required in this case

  Presently equality is treated as left associative, but we will require parenthesization in order
  to avoid confusion with conjunctive use. Later we hope to introduce conjunctive relational
  expressions such as "if (a = b = c) ..." testing for the equality of all of the operands. Then we
  will relax the constraint on parenthesizing equality tests, but still keep the parentheses for the
  equalities on the right-hand-side of assignment statements.

  When an invalid compile unit is
    """
    class assignmentVsEquality {

    int 'a, 'b;

    void test() {
      boolean fact2' = 'a = 'b;    // Parentheses required for bool assignment: fact2' = ('a = 'b)
      means:  fact2' = ('a = 'b);  // does this have to be fact2' === 'a = 'b ?
    }

    } // end class
    """

    Then the only error message contains
      """
      The right-hand side must be parenthesized to keep the assignment from looking like part of a conjunctive relational expression
      """

  When an invalid compile unit is
    """
    class assignmentVsEquality {

    int 'a, 'b;

    void test() {
      boolean fact2' = ('a = 'b);
      means:  fact2' === 'a = 'b;  // Use this one
      means:  fact2' = ('a = 'b);  //   or this one
      means:  fact2' = 'a = 'b;    // would be parsed as (fact' = 'a) & ('a = 'b),
                                   //   so one of the above is required
    }

    } // end class
    """

    Then the only error message contains
      """
      The code does not support the proof of the statement: fact2' = 'a = 'b
      """

Scenario: The scope of value names

  We wish to ensure that a final means-statement summarizes executable code in a way that we can use
  it to understand that code without investigating the code. (By executable code we mean methods,
  constructors, and initialization blocks). Initial value names for fields and final value names for
  fields are easy to understand, and they are allowed, but other value names must be explicitly
  constructed in the means-statement so that their meaning is clear. These other value names will be
  explained in the specification of methods.

  On the other hand, within the definition of executable code intermediate (mid-decorated) value
  names for both fields and local variables may be assigned values and their scope does not end
  until the scope of the variable ends. But these mid-decorated value names for a field do not keep
  their meaning outside the excutable code, and the final means-statements are consider to be
  outside of the code.

  Therefore in the following example, the intermediate value a'start is defined in the method and
  can be used in the internal means statement, but not the final means statement.

  When an invalid compile unit is
    """
    class SwapError5 {

    int 'a, 'b;

    void swap1() {
      a'start = 'a;
      a' = 'b;
      b' = a'start;
      means: a'start = 'a && a' = 'b && b' = a'start;
    }
    means: a'start = 'a && a' = 'b && b' = a'start;

    void swap2() {
      a'start = 'a;
      a' = 'b;
      b' = a'start;
      means: a'start = 'a && a' = 'b && b' = a'start;
      final means: a'start = 'a && a' = 'b && b' = a'start;
    }

    } // end class

    """
  Then the error messages contain
    """
    line 11:7 for <a'start>: Mid-decorated value names are not allowed in a final means-statement
    11:39 for <a'start>: Mid-decorated value names are not allowed in a final means-statement
    18:15 for <a'start>: Mid-decorated value names are not allowed in a final means-statement
    18:47 for <a'start>: Mid-decorated value names are not allowed in a final means-statement
    """

When an invalid compile unit is
  """
  class SwapError6 {

    int 'a, 'b;

    void swap1() {
      a'start = 'a;
      b' = a'start;
      final means: b' = 'a;
      b'start = 'b;
      a' = b'start;
    }
  }
  """
Then the error messages contain
  """
  line 9:4 for <b'start>: All statements must come before the final means
  9:14 for <'b>: The value name 'b is not available in this scope (perhaps it needs to be included in the means statement at line 8)
  9:4 for <b'start>: b' received a final value at line 7, so it cannot receive a new value
  10:9 for <b'start>: Value b'start has not been defined for the variable b that was declared at line 3
  """

Scenario: TODO: Back translation of comments requires absence of reserved characters

  Generation of executable Java from the T language requires translating all
  non-command statements to comments. Although we have not implemented a
  back-translator from the generated Java to the T language that would generate
  it, we hope that these special comments will allow such a translator to be
  built, especially for back-translating Java error messages into T language
  error messages. In order to mark parts of a generated comment that need to be
  uncommented or not, the character string $T$ is used. To avoid confusing any
  attempt at back-translation, that string needs to be prohibited within the
  original T language comments.

  Also, we must prohibit the comment /*'*/ because it is used is used to mark decorators in
  generated code, e.g., value' is translated into value/*'*/.

  # TODO: implement the $T$ and /*'*/ prohibition in comments
    #  When an invalid compile unit is
    #    """
    #    class SwapError5 {
    #
    #    /* no comment may contain $T$, like this one does */
    #
    #    int a, b;
    #
    #    void swap() {
    #      int startingA' = 'a;
    #      a' = 'b;
    #      b' = startingA';
    #    }
    #    means: a' = 'b && b' = 'a;
    #
    #    } // end class
    #    """
    #
    #  Then the only error message contains
    #  """
    #  ???
    #  """
