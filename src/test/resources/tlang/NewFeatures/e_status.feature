Feature: Status Statements for Executable code

  As code executes, it shifts the object from one state to the next. There are several TrueJ
  statements that can summarize the state required or created. These are the _given-statement_, the
  _means-statement_, the _lemma_, and the <em>conjecture</em>. The use of status statements to
  constrain or summarize the resting state of an object is covered in another feature.

  TODO: Add tests for the lemma.
  TODO: Add tests for the given statement.
  TODO: Add tests for the conjecture.

Scenario: A block forgets operations from before a _means-statement_

  The _means-statement_ summarizes all the information from the preceding executable statements that
  is needed in order to understand the following code in the block; only the facts mentioned by the
  _means-statement_ are needed. To ensure that the programmer can rely on the _means-statement_ ,
  the compiler forgets all of the operational facts about the values created above the
  _means-statement_.

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

Scenario: The compiler remembers type information for a variable after a _means-statement_

  TODO: Create code to show success and falure because it remembers the type of a variable.

  Because the scope of a variable reaches to the end of the block, new values can be assigned to it
  after a _means-statement_. To ensure that those values have the correct type, the type of the
  variable is remembered after a _means-statement_.

Scenario: The compiler remembers facts from surrounding blocks after a _means-statement_

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

Scenario: Object fields that are modified must have a final value for security

  TODO: Code the examples.

  Because the _means-statement_ is expected to summarize the code above it, a security review should
  be possible by looking only at _means-statement_s where they exist. To prevent malicious or
  accidental ommision of modifications of an object, TrueJ requires that a _means-statement_ must
  define the value of any of the object's fields that are modified in the code above it. We allow
  lenient security for a field with little security implications, such as a usage counter or log, by
  marking it with the modifier _lenient_.
