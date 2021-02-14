Feature: Status Statements for Executable code

  As code executes, it shifts the object from one state to the next. There are several TrueJ
  statements that can summarize the state required or created. These are the _means-statement_, the
  _lemma_, the _given-statement_, and the _conjecture_. There are also status statements that
  constrain or summarize the resting state of an object before and after methods are run, which are
  covered in another feature.

  TODO: Add tests for the lemma.
  TODO: Add tests for the given statement.
  TODO: Add tests for the conjecture.

Rule: The means-statement summarizes the preceeding executable code

  The means-statement is used to summarize, refactor, or reformulate the meaning of all the
  preceding statements of the block, replacing them with the predicate of the means-statement. The
  compiler will only accept means statements that are logically entailed by the meaning of the
  statements that it summarizes. Thus, a programmer reading the block of code can use the means
  statement to understand the intent of the preceding statements. Also, in order to understand the
  overall meaning of a block, the programmer can start reading at the bottommost means statement. If
  a programmer places a final-means statement at the end of a nontrivial block, we can see what the
  block accomplishes just by reading that means-statement, without reading the code.

@Ready
Example: Using a final means-statement to show the intent of the commands in a block

  * a valid run unit is
    """
    class BlockMeaning2 {

    int a, b;

    void swap() {
      int startingA' = 'a;
      a' = 'b;
      b' = startingA';
      means(a' = 'b & b' = 'a);
    }

    } // end class
    """

@InProgress
Scenario: A block forgets operations from before a _means-statement_

  The _means-statement_ summarizes all the information from the preceding executable statements that
  is needed in order to understand the following code in the block; only the facts mentioned by the
  _means-statement_ are needed. To ensure that the programmer can rely on the _means-statement_ ,
  the compiler forgets all of the operational facts about the values created above the
  _means-statement_.

  Note that the current value of a local variable may be forgotten after a
  means-statement, but its type is still available to allow definition of a new value for it.

  Here is an example that shows an error caused by an attempt to refer back to a forgotten fact.

  When an invalid run unit is
    """
    class BlockMeaning3 {

    int a, b;

    void swap() {
      int startingA' = 'a;
      a' = 'b;
      means (a' = 'b);          // Oops, we are now forgetting that startingA' = 'a
      b' = startingA';          // We generate code, but we don't track what that code means
      means(a' = 'b & b' = 'a); // So we can't see that    startingA' = 'a
    }

    } // end class
    """
  Then an error message contains
    """
    The code does not support the proof of the statement: b' = 'a
    """
  And an error message contains
    """
    The means-statement at line 8 might be the problem.
    """

@InProgress
Scenario: The compiler remembers type information for a variable after a _means-statement_

  TODO: Create code to show success and falure because it remembers the type of a variable.

  Because the scope of a variable reaches to the end of the block, new values can be assigned to it
  after a _means-statement_. To ensure that those values have the correct type, the type of the
  variable is remembered after a _means-statement_.

@Ready
Scenario: The compiler remembers facts from surrounding blocks after a means-statement

  * a valid run unit is
    """
    class BlockMeaning5 {

    int a, b;

    void swap() {
      int startingA' = 'a;
      { int startingB' = 'b;
        a' = startingB';
        means (a' = 'b);
        b' = startingA';
        means (a' = 'b & b' = 'a);
      }
    }

    } // end class
    """

  * a valid run unit is
    """
    class BlockMeaning2a {

    int a, b;

    void swap() {
      int startingA' = 'a;
      int 'startingB = 'b;
      a' = 'startingB;
      means (startingA' = 'a & a' = 'b); // forget 'startingB = 'b & a' = 'startingB
      b' = startingA';
      means (a' = 'b & b' = 'a);
    }

    } // end class
    """

  * a valid run unit is
    """
    class BlockMeaning2a {

    int a, b;

    void swap() {
      int startingA' = 'a;
      int 'startingB = 'b + 'a;
      means (startingA' = 'a); // <==== start reading here
      startingB' = 'b;         // we can create a new value for variable startingB
      a' = startingB';
      b' = startingA';
    }
    means (a' = 'b & b' = 'a);

    } // end class
    """

@InProgress
Example: A value name is forgotten if a means statement does not mention it

  Sometimes error messages help the programmer locate the problem when proofs fail because of facts
  that they left out of a means-statement.

  When an invalid run unit is
    """
    class BlockMeaning2b {

    int a, b, c;

    void rotateLeft() {
      int startingA' = 'a;
      a' = 'b;
      means a' = 'b;   // forget startingA' = 'a
      b' = 'c;
      c' = startingA'; // error because the value of startingA' is forgotten
      means a' = 'b & b' = 'c & c' = 'a;
    }

    } // end class
    """
  Then an error message contains
    """
    The value of startingA' was eclipsed by the means statement at line 8
    """
  And an error message contains
    """
    The code does not support the proof of the statement: c' = 'a
    """

@InProgress
Scenario: Object fields that are modified must have a final value for security

  Because the _means-statement_ is expected to summarize the code above it, a security review should
  be possible by looking only at _means-statement_s where they exist. To prevent malicious or
  accidental ommision of modifications of an object, TrueJ requires that a _means-statement_ must
  define the value of any of the object's fields that are modified in the code above it. We allow
  lenient security for a field with little security implications, such as a usage counter or log, by
  marking it with the modifier _lenient_.

  * an error message contains
    """
    TODO: Code the examples.
    """
