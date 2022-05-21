#  TODO: Add tests for the lemma first, then means-statemt.
#  TODO: Add tests for the given statement.
#  TODO: Add tests for the conjecture.
@testthis
@Ready
Feature: Status Statements for Executable code

  TrueJ provides several statements that declare the state of the program's data at that point. We
  use the terminology _status statements_ to distinguish them from command statements. These status
  statements show that change made by commands as the relationship between the object's state at the
  beginning of those commands' execution and the state at the end. The three status statements that
  capture these changes are the means-statement, carrying the bulk of the load for specifying,
  summarizing, or clarifying the preceding code in a way that the compiler can verify; the _lemma_,
  playing a supporting role for the means-statement; and the _conjecture_, providing runtime
  verification of facts when the compiler is unable to verify them. This feature only covers the use
  of these statements in a section of executable code. In another feature we cover the use of those
  statements that constrain or summarize the resting state of an object.

  Both the lemma and the means-statement summarize the meaning of the preceding code, that is the
  changes to data that the code causes, and the claims of both kinds of statements are verified by
  the compiler. However, the means-statement also claims that its meaning is sufficient for all the
  following code. The means-statement is used in a block of code to summarize those facts of _all_
  preceding code that is needed in _any_ of the following code inside the same block, allowing
  the programmer to state consequential facts and omit details about how these facts were
  established. And if a means-statement omits any fact about the data that is needed by that
  following code, the compiler generates an error.

Rule: A means-statement or lemma summarizes the preceding executable code

Example: Using a lemma or a means-statement to restate the meaning of preceding commands

  * a valid compile unit is
    """
    class Status1 {

    int 'a, 'b;

    void swap() {
      int startingA' = 'a;
      a' = 'b;
      lemma: startingA' = 'a & a' = 'b;
      b' = startingA';
      means: a' = 'b & b' = 'a;
    }

    } // end class
    """

Example: An error because a lemma must follow from the preceding code

  When an invalid compile unit is
    """
    class Status1 {

    int 'a, 'b;

    void swap() {
      int startingA' = 'a;
      a' = 'b;
      lemma: a' = 'b & b' = 'a;
      b' = startingA';
    }

    } // end class
    """
  Then the error messages contain
    """
    The code does not support the proof of the statement: b' = 'a
    """


Rule: The means-statement can be used to safely forget details of calculations

  The _means_-statement is used to summarize, refactor, or reformulate the meaning of all the
  preceding statements of the code block and its enclosing blocks. At the point that it is coded, the
  _means_-statement completely replaces the meaning of the preceding code. But the _means_-statement
  can't introduce anything that is new; the compiler
  will only accept _means_-statements that are logically entailed by the meaning of the statements
  that it summarizes. Thus, a programmer reading the block of code can use the means statement to
  understand the intent of all preceding statements. Also, in order to understand the overall
  meaning of a block, the programmer can start reading at the bottommost means statement. If a
  programmer places a means-statement at the very end of a complicated block of code, we can see
  what the block accomplishes just by reading that _means_-statement, without reading the code.

Example: Using a means-statement to forget code that has served its purpose

  * a valid compile unit is
    """
    class Status1 {

    int 'a, 'b;
    boolean 'isSwapped = false;

    void swap() {
      int startingA' = 'a;
      a' = 'b;
      b' = startingA';
      means: a' = 'b & b' = 'a; // we no longer need startingA' and the fact that startingA' = 'a
      isSwapped' = true;
    }

    } // end class
    """


Example: Using a final means-statement to show the intent of the commands in a block

  * a valid compile unit is
    """
    class Status2 {

    int 'a, 'b;
    boolean 'isSwapped = false;

    void swap() {
      { int startingA' = 'a;
        a' = 'b;
        b' = startingA';
        means: a' = 'b & b' = 'a; // summarizes the effect of the block
      }
      isSwapped' = true;
    }

    } // end class
    """


Rule: A block forgets operations and value-names from before a means-statement

  The _means_-statement summarizes all the information from the preceding executable statements that
  is needed in order to understand the following code in the block; only the facts mentioned by the
  _means_-statement are needed. To ensure that the programmer can rely on the _means_-statement ,
  the compiler forgets all of the operational facts about the values created above the
  _means_-statement.

  Note that the current value of a local variable may be forgotten after a _means_-statement, but
  the type of that variable is still available to allow definition of a new value for it.

Example: A value-name must be referenced in a means-statement to be meaningful in following code

  The meaning of a value name is eclipsed when it is not included in a following _means_-statement,
  so it cannot be used in any following commands or status statements.

  When an invalid compile unit is
    """
    class Status3 {

    int 'a, 'b;

    void swap() {
      int startingA' = 'a;
      a' = 'b;
      means: a' = 'b;           // Oops, we are now forgetting the value of startingA' and 'a
      b' = startingA';          // So we can't use startingA' here
      means: a' = 'b & b' = 'a; // Or 'a here
    }

    } // end class
    """
  Then the error messages contain
    """
    line 9:7 for <startingA'>: The value name startingA' is not available in this scope (perhaps it needs to be included in the means statement at line 8)
    10:24 for <'a>: The value name 'a is not available in this scope (perhaps it needs to be included in the means statement at line 8)
    """

Example: A means-statement can eclipse facts that are then unavailable in following code

  The compiler can also forget a fact that it needs about a value name while remembering that the
  value name exists. This happens when the programmer references some other fact about the value
  name in a means statement, but not the fact that they need in order to support following
  statements. We show this in an example that uses transitivity in the equivalence chain

      b' = startingA' = 'a

  to prove

      b' = 'a

  but the proof fails because the compiler has forgotten the first part of the chained equality

      b' = startingA'

  Rather than give a more complicated example where this happens, here we force the
  compiler to remember the existence of `b'` with the silly statement:

      b' = b'

  When an invalid compile unit is
    """
    class Status2 {

    int 'a, 'b;

    void swap() {
      int startingA' = 'a;
      a' = 'b;
      b' = startingA';

      means: startingA' = 'a & a' = 'b & b' = b';
        // We trivially mention b', but eclipse the fact that b' = startingA'

      means: a' = 'b & b' = 'a;
    }

    } // end class
    """
  Then the error messages contain
    """
    line 13:19 for <b'>: The code does not support the proof of the statement: b' = 'a
    """


Rule: The compiler remembers type information for a variable after a _means_-statement

  TODO: Create code to show success and failure because it remembers the type of a variable.

  Because the scope of a _variable_ reaches to the end of the block, new values can be assigned to
  the variable after a _means_-statement. To ensure that those values have the correct type, the
  type of the variable is remembered after a _means_-statement.

Example: A new value for a variable can be defined after a means-statement

  References can be eclipsed by a means statement, but the type of a variable is remembered, so that
  new values for that variable can be defined. In this example we eclipse the initial value of the
  variable startingB, but we are still able to define the new value startingB'.

  * a valid compile unit is
    """
    class BlockMeaning2a {

    int 'a, 'b;

    void swap() {
      int startingA' = 'a;
      int 'startingB = 'b + 'a;
      int tempB' = 'b;
      means: startingA' = 'a & tempB' = 'b; // <==== start reading here, eclipsing 'startingB
      startingB' = 'b;                       // a new value for variable startingB
      a' = startingB';
      b' = startingA';
      means: a' = 'b & b' = 'a;
    }

    } // end class
    """

Example: A previously declared variable cannot be redeclared after a means statement

  When an invalid compile unit is

    """
    class BlockMeaning2a {

    int 'a, 'b;

    void swap() {
      int startingA' = 'a;
      int 'startingB = 'b + 'a;
      int tempB' = 'b;
      means: startingA' = 'a & tempB' = 'b; // <==== start reading here, eclipsing 'startingB
      int startingB' = 'b;                       // a new value for variable startingB
      a' = startingB';
      b' = startingA';
      means: a' = 'b & b' = 'a;
    }

    } // end class
    """
  Then the error messages contain
    """
    for <startingB'>: Attempted to declare variable startingB, but it was already declared at line 7
    """


Rule: The compiler remembers facts from a surrounding block once it returns to that block

Example: Reusing a fact from before an enclosed block

  The _means_-statement only eclipses facts and value names within the current scope.

  * a valid compile unit is
    """
    class BlockMeaning5 {

    int 'a, 'b;

    void swap() {
      int startingA' = 'a;

      { int startingB' = 'b;
        a' = startingB';
        means: a' = 'b;
      }

      b' = startingA'; // the compiler remembers startingA' = 'a from before the block
      means: a' = 'b & b' = 'a;
    }

    } // end class
    """

# @InProgress
Rule: Object fields that are modified must have a final value for security

  Because the _means_-statement is expected to summarize the code above it, a security review should
  be possible by looking only at _means_-statements where they exist. To prevent malicious or
  accidental ommision of modifications of an object, TrueJ requires that a _means_-statement must
  define the value of any of the object's fields that are modified in the code above it. We allow
  lenient security for a field with little security implications, such as a usage counter or log, by
  marking it with the modifier _lenient_.


Rule: The conjecture allows run-time verification when compile-time verification fails

  Programmers should work to avoid using the conjecture. When the compiler cannot prove that a
  _means_-statement or _lemma_ statement is supported by its preceding code, programmers will look
  for an error in their logic. But if they find no errors and are convinced that the problem is a
  weak prover, they should, ideally, attempt to simplify the prover's work by adding preceding
  lemmas or outlining a proof in a _because_ expression. They may uncover their faulty logic while
  doing this, or they may still be convinced of the statement's truth. As a final stopgap, in order
  to proceed with development, the programmer may change the statement to a _conjecture_. Sometimes
  the proof of a statement would elude all the mathematical geniuses of the world for generations,
  but the program is needed next week. Still, we wouldn't want a programmer to fall back on the
  _conjecture_ as an easy out for the work of writing correct programs, so there are safeguards that
  we will discuss; for now, we briefly note that conjectures are tested at runtime, so that they are
  in a proven to be true, but only for that execution of the program. In addition, the confidence
  that the programmer asssigns to conjectures is bounded, tracked, and reported, in purposefully
  annoying ways.

# Conjectures have an expense and a confidence. They are executed if their expense is less than an
#   expense limit that can be specifed at runtime.
# Classes may state a lower bound in class syntax for confidence. Every class that contains a
#   conjecture or calls a method with a conjecture must contain the lower bound syntax. Even if the
#   lower bound is met, the class still gets a
#   report about the lowest and highest confidence conjectures and an overall confidence that treats
#   confidence as though it were a probability. The report also includes the highest expense
#   conjectures and the total expense of its conjectures.
