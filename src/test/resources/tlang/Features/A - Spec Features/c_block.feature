@Ready
Feature: Blocks delimit the scope of variable names

  A block is compound statement that organizes a list of statements together into a single unit and
  provides a syntactic scope for variables and their values. We code a block by inclosing a sequence
  of statements between curly braces. All of an object's procedural code is contained in blocks,
  either method bodies, constructor bodies, or initializer blocks.

Scenario: The meaning of a block is the conjunction of the meanings of its sequence of statements

  If there is no top-level means-statement, then the meaning of a block is the conjunction of the
  meaning of all of its top level statements. We illustrate this with a method block that contains
  no means statements. We can see that the meaning of the method block is the conjunction of the
  meaning of its statements by comparing it with the means statement for the entire method
  definition.

  * a valid compile unit is
    """
    class BlockMeaning1 {

    int a, b;
    int startingA;

    void swap() {
      startingA' = 'a;
      a' = 'b;
      b' = startingA';
    }
    means(startingA' = 'a & a' = 'b & b' = startingA');

    } // end class
    """


Scenario: Blocks may be nested

  A block may be nested in another block's sequential code or used as part of a complex control
  statement, such as being one branch of a conditional statement. When a block is nested within
  another block, the inside block is treated as a single compound statement of the enclosing block
  with its own meaning that can be given in a single statement. When a block is part of a complex
  control statement, the meaning of the block plays one part of the more complex meaning of the
  control statement. We will treat the conditional and iterative statements that may contain blocks
  in a separate feature descriptions.

  * a valid compile unit is
    """
    class BlockMeaning3 {

    int a, b;

    void swap() {
      int startingA' = 'a;
      { int startingB' = 'b;
        a' = startingB';
        means (a' = 'b);
      }
      b' = startingA';
    }
    means (a' = 'b & b' = 'a);

    } // end class
    """

Scenario: A variable's scope encloses the scopes of all its values

  The relationship of local variables and blocks is consistent with Java. To review: the scope of a
  variable, which is the set of code statements where values of the variable may be defined or used,
  extends from the variable's declaration to the end of the block where it is declared, and includes
  any nested blocks. A block's variables must have names that do not shadow those that were already
  declared in an enclosing scope. This includes method parameter names; however, field names may be
  shadowed with a new variable name, requiring access to the field to be dot-prefixed with either
  'super' or 'this'. A separate, non-overlapping, block may use the same name for one of its
  variables, but having the same name does not indicate any relationship between the variables --
  they are entirely separate variables.

  Our example shows an attempt to use a value name that is out of scope.

  When an invalid compile unit is
    """
    class BlockMeaning4 {

    int a, b;

    void swap() {
      int startingA' = 'a;
      { // Here we will save and set b
        int startingB' = 'b;
        b' = startingA';
        means(b' = 'a);
      }
      a' = startingB'; // Oops, the variable startingB is out of scope
    }
    means(a' = 'b & b' = 'a);

    } // end class
    """
  Then an error message contains
    """
    Variable startingB has not been defined in this scope
    """
