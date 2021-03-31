@InProgress
@Ready
Feature: Status Statements for Executable code

  As a code command executes, it manipulates the data of the object, shifting values from one state
  to the next. The meaning of the command is the relationship between the object's state at the
  beginning of the command and its state at the command's end, a relationship that can be captured
  by simple statements about how the object's values have changed. TrueJ provides provides a few
  types of statements designed for summarizing the relationship between the values of states as a
  sequence of commands execute: the _means_-statement, the _lemma_, and the _conjecture_. The
  _given_-statement is also available to summarize the beginning state of a method.

  Programming language commands have a dual nature as both instructions to do something and as
  shorthand for a predicate-logic statement of fact; that fact being the relationship between the
  object's beginning and ending state for an execution of the command. This is because as long as
  computer hardware has a steady power supply and no other (extremely rare) malfunctions, it
  operates with rigid consistency. If I issue a command to my employees, my students, my children,
  or my wife, there is no telling what the results will be. But if I use a programming language to
  issue a command to my computer, there is a well-defined result that depends only on the starting
  state when the command is executed. This is true even for commands in concurrent programming
  languages, although the statement summarizing the result may be a disjunction of the simpler facts
  that we are used to seeing in a sequential language. Because the results are so well-defined and
  the caveats so rare, we are justified in treating commands as a logical notation in themselves.

  The TrueJ language attemps to take advantage of this dual nature of commands to make programs
  easier to understand and easier to validate with automated proof of correctness. As well as
  viewing the program as a sequence of commands that continually, and sometimes confusingly, modify
  the object's hidden state, the programmer can add purely factual statements to highlight the view
  that a sequence of commands describes a fact about the resulting state. And the compiler can prove
  that these additional statements are supported by the commands that precede them because the
  implicit statements of the shorthand command language provide the premises of a proof that the
  purely factual statements are a valid conclusion of the executable code. TrueJ provides the
  _means_-statement and _lemma_ summarize the preceding commands. Both of these are validated by the
  compiler and might be termed "valid statements". Perhaps they are merely assertions when the
  programmer writes them, but by the time they survive a error-free compilation they are proven to
  be supported by the preceding commands.

  The _given_-statement guards an executable section of code, that is, a method, constructor, or
  initializer block of a class, and ensures that the executable is only invoked in a context in
  which it will be appropriate. A _given_-statement is proven to be true, not at the point at which
  it is coded, but at every point where code invokes the executable that it guards.

  A _conjecture_ statement is also available, but every programmer will work to avoid using it. When
  the compiler cannot prove that a _means_-statement or _lemma_ statement is supported by its
  preceding code, programmers will look for an error in their logic. But if they find no errors and
  are convinced that the problem is a weak prover, they should, ideally, attempt to simplify the
  prover's work by adding preceding lemmas or outlining a proof in a _because_ expression. They may
  uncover their faulty logic while doing this, or they may still be convinced of the statement's
  truth. As a final stopgap, in order to proceed with development, the programmer may change the
  statement to a _conjecture_. Sometimes the proof of a statement would elude all the mathematical
  geniuses of the world for generations, but the program is needed next week. Still, we wouldn't
  want a programmer to fall back on the _conjecture_ as an easy out for the work of writing correct
  programs, so there are safeguards that we will discuss; for now, we briefly note that conjectures
  are tested at runtime, so that they are in a sense proven to be true for each execution that
  depends on them. In addition, the confidence of conjectures is bounded, tracked, and reported, in
  purposefully annoying ways.

  This feature only covers the use of these statements in a section of executable code. In another
  feature we cover the use of status statements to constrain or summarize the resting state of an
  object before and after methods are run.

#  TODO: Add tests for the lemma.
#  TODO: Add tests for the given statement.
#  TODO: Add tests for the conjecture. With execution up to a limit and lower bounds in class syntax
#        for containing and calling classes and if a compile meets the lower bound it still gets a
#        warning reporting the lowest confidence conjecture and an overall confidence, using a
#        probabilistic combination of the conjecture individual confidences.

Rule: The means-statement summarizes the preceding executable code

  The _means_-statement is used to summarize, refactor, or reformulate the meaning of all the
  preceding statements of the block. At that point in the code, the _means_-statement completely
  replaces the meaning of the preceding code of the block. The compiler will only accept
  _means_-statements that are logically entailed by the meaning of the statements that it
  summarizes. Thus, a programmer reading the block of code can use the means statement to understand
  the intent of the preceding statements. Also, in order to understand the overall meaning of a
  block, the programmer can start reading at the bottommost means statement. If a programmer places
  a means-statement at the very end of a complicated block of code, we can see what the block
  accomplishes just by reading that _means_-statement, without reading the code.

Example: Using a final means-statement to show the intent of the commands in a block

  * a valid run unit is
    """
    class Status1 {

    int a, b;

    void swap() {
      int startingA' = 'a;
      a' = 'b;
      b' = startingA';
      means(a' = 'b & b' = 'a);
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

  When an invalid run unit is
    """
    class Status2 {

    int a, b;

    void swap() {
      int startingA' = 'a;
      a' = 'b;
      means (a' = 'b);          // Oops, we are now forgetting the value of startingA' and 'a
      b' = startingA';          // So we can't use startingA' here
      means(a' = 'b & b' = 'a); // Or 'a here
    }

    } // end class
    """
  Then the error messages contain
    """
    9:7 for <startingA'>: The value name startingA' was eclipsed by the means statement at line 8
    10:23 for <'a>: The value name 'a was eclipsed by the means statement at line 8
    """

Example: A means-statement can eclipse facts that are then unavailable in following code

  The compiler can also forget a fact that it needs about a value name while remembering that the
  value name exists. This happens when the programmer references some other fact about the value
  name in a means statement, but not the fact that they need in order to support following
  statements. We show this in an example that uses

      b' = startingA' = 'a

  to prove

      b' = 'a

  but the proof fails because the compiler has forgotten the last part of the chained equality

      startingA' = 'a

  Rather than give a more complicated example where this happens, here we force the
  compiler to remember the existence of `b'` with the silly statement:

      b' = b'

  When an invalid run unit is
    """
    class Status2 {

    int a, b;

    void swap() {
      int startingA' = 'a;
      a' = 'b;
      b' = startingA';

      means startingA' = 'a & a' = 'b & b' = b';
        // We trivially mention b', but eclipse the fact that b' = startingA'

      means(a' = 'b & b' = 'a);
    }

    } // end class
    """
  Then the error messages contain
    """
    line 13:18 for <b'>: The code does not support the proof of the statement: b' = 'a
    """


Rule: The compiler remembers type information for a variable after a _means_-statement

  TODO: Create code to show success and falure because it remembers the type of a variable.

  Because the scope of a variable reaches to the end of the block, new values can be assigned to it
  after a _means_-statement. To ensure that those values have the correct type, the type of the
  variable is remembered after a _means_-statement.

Example: A new value of a variable can be defined after a means-statement

  References can be eclipsed by a means statement, but the type of a variable is remembered, so that new values for that variable can be defined. In this example we eclipse the only value of the variable startingB, but we are still able to define the new value startingB'.

  * a valid run unit is
    """
    class BlockMeaning2a {

    int a, b;

    void swap() {
      int startingA' = 'a;
      int 'startingB = 'b + 'a;
      int tempB' = 'b;
      means (startingA' = 'a & tempB' = 'b); // <==== start reading here, eclipsing 'startingB
      startingB' = 'b;                       // a new value for variable startingB
      a' = startingB';
      b' = startingA';
      means (a' = 'b & b' = 'a);
    }

    } // end class
    """

Example: The compiler remembers facts from a surrounding block once it returns to that block

  The _means_-statement only eclipses facts and value names within the current scope.

  * a valid run unit is
    """
    class BlockMeaning5 {

    int a, b;

    void swap() {
      int startingA' = 'a;
      { int startingB' = 'b;
        a' = startingB';
        means (a' = 'b);
      }
      b' = startingA';
      means (a' = 'b & b' = 'a);
    }

    } // end class
    """

@InProgress
Scenario: Object fields that are modified must have a final value for security

  Because the _means_-statement is expected to summarize the code above it, a security review should
  be possible by looking only at _means_-statements where they exist. To prevent malicious or
  accidental ommision of modifications of an object, TrueJ requires that a _means_-statement must
  define the value of any of the object's fields that are modified in the code above it. We allow
  lenient security for a field with little security implications, such as a usage counter or log, by
  marking it with the modifier _lenient_.


