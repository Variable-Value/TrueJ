@Ready
Feature: Value names are decorated variable names - TrueJ 0.1

  TrueJ directs the programmer's attention to the changing state of the program's data as each
  statement is executed. To do this, TrueJ provides a way for each value contained in each variable
  to be explicitly named. In order to allow the programmer to express their thoughts about how a
  section of code changes the state, we provide the means-statement, which gives the concrete
  semantics of a program's execution up to that point in terms of the names of the values that it
  has referenced and created. The correctness of the semantics is checked with a relatively
  simple prover.

  Because we want programmers to easily make the transition to focusing more on the state's values
  and less on the variables, we need to resist the temptations to make other changes, unless they
  directly affect the programmers ability to think clearly about the desired state.

Rule: Values have names

  TrueJ represents state by adding a syntax for naming the values that are held by variables. We add
  a distinct decoration to a variable's name for each of the values that it stores, keeping the
  variable's name as part of the value name to allow the programmer to control details of the
  procedural programming. Within the scope of each executable, The name of the initial value that a
  variable holds is the variable name pre-decorated with an apostrophe, and the name of the ending
  value is the variable name post-decorated with an apostrophe. For example, the initial value of
  the variable z is named 'z and the final value is named z'. We can read 'z as "initial-z" and z'
  as "z-final".

  Once we make this transition from variable names to value names, we can show facts about program
  state as statements about values. In a sense, the meaning of a sequence of program commands is the
  state of the data that they produce. Therefore, we introduce a new statement, the means-statement,
  where we can summarize all the interesting facts that have been established in the state by the
  preceding operations.

Example: The means-statement summarizes the above operational statements

  The means-statement does not need to mention type information, for instance, the `int` in

    int startingA' = 'a

  but it does need to mention the important value names and their relationships.

  * A valid compile unit is
    """
    class Swapper {

    int 'a = 1, 'b = 2;

    void swap() {
      int startingA' = 'a;
      a' = 'b;
      b' = startingA';
      means: startingA' = 'a && a' = 'b && b' = startingA';
    }
    means: a' = 'b && b' = 'a;

    } // end class
    """

Example: Notes

  Three comments about TrueJ's syntax and semantics will help the reader understand the example
  program above. The first is that in TrueJ, the syntax for the assignment statement is almost
  exactly the same as the notation for its semantics. For instance, when making claims about the
  program state after the assignment:

      a' = 'b;

  we use the state expression:

      a' = 'b

  and because they are essentially identical the programmer can choose to read off the meaning of
  the statement instead of its operational action. That is, instead of reading "copy the value in
  variable b to a", or "the variable a gets the value in b", or "the variable a now has the same
  value as the variable b", or "the variable a can now be substituted for the expression b in
  prior statements", the programmer can now abandon mechanical metaphors, transient truths about
  variables, and substitution of variables and expressions, and instead think about unchanging
  truths about values, reading off the meaning of the statement `a' = 'b;` as "a-final equals
  initial-b".

  The second comment is that TrueJ gives up Java's ability to include a side-effect-like internal
  assignment inside an arbitrary expression in exchange for unifying the syntax of three uses of
  equality:

  - equality resulting from an assigment statement
  - equality tests in conditional expressions
  - equality in claims about program state

  They all use the single equal sign '='. It will have to be emphasized to new programmers that
  the new value name must be on the left-hand side of an assigment, and no new value names may
  occur on the right-hand side. It is an empirical question as to which will weigh the most: the
  confusion caused by this operational vs. semantic asymmetry/symmetry, or the simplified
  understanding from using the equality symbol to point to the meaning of the assignment. The
  uncomfortable itch that some of us feel in overloading the same symbol for these distinct uses
  is one clue, but the satisfaction in easily reading off the meaning of the assignment is
  another. I hesitate to begin exploring the other solution, which is to allow the assignment
  statement to be symmetrical, because it moves further down the slippery slope that takes us away
  from Java.

  The third, and more dramatic, comment is that working with a consistent name for each value
  simplifies our understanding of the overall program's meaning. As you might have noted, in the
  code inside the swap() method, the means-statement is wasted verbage:

      int startingA' = 'a;
      a' = 'b;
      b' = startingA';

      means: startingA' = 'a && a' = 'b && b' = startingA';

  It is simply the meaning of each of the statements, combined with an "and". Once we use values
  instead of variables, the semantics of a program's top-level sequential statements is
  conjunction.

  This brings us closer to our goal of helping programmers think in terms of state as well as
  operations because the conjunction of statements over values provides a simple semantics for
  understanding the cumulative change in state created by those operations. People understand
  conjuction, so we will attempt to dispense with a discussion of inference rules for combining
  statements in all but the most advanced discussions of TrueJ. Of course, we appreciate the
  clarity that we gain from formal mathematical descriptions of the use of variables or machine
  storage locations during program execution; we only claim that this simpler mathematics is more
  helpful for writing programs.

  Functional and logic programming languages also focus on values, but at the expense of
  increasing the conceptual distance from the procedural instructions of the programmers mental
  model of the underlying machine that runs the programs (but see Chisnall, 2018).

  A careful look at the above program also raises the issue of the scope of
  the value names. Within the means-statements we use the initial value 'a,
  even though that value is no longer present in any variable -- it has been
  overwritten by the statement

     a' = 'b;

  So it seems that the scope of a value has to continue after the value ceases to exist, at least
  for logic statements. Should we allow the overwritten value to be used in the logic statements,
  but not the operational statements? We seem to have two uncomfortable options. The first is that
  we make sure that programmers understand that only values that exist can be mentioned in
  operational statements, but that values that no longer exist can be mentioned in logic. The
  alternative, and the option that TrueJ uses, is to allow the values to be reused in both code
  and descriptions of state. We make this explicit in the following scenario.

  * end note


Rule: The scope of a value name ends with the scope of its variable

  Normally in a procedural language, the value held by a variable disappears
  when you overwrite it with a new value, but not in TrueJ. If you need a value
  whose variable is still in scope, the compiler will make sure the value
  still exists. Obviously, the implementation must keep a copy of any
  overwritten values that are needed for later statements.

  The link between variables and their values becomes more abstract, but we
  hope to wave that issue away for beginning programmers by saying,
  "Obviously, the implementation must keep a copy of any overwritten values
  that are needed for later statements".

  The reason that we go to the trouble to allow the use of overwritten values in TrueJ is that our
  state-based focus will often require us to make claims about how the current state relates to an
  earlier one, and we don't want to confuse beginning programmers with a different rule about
  using value names in operational statements vs. using them in claims about state. TrueJ makes
  the scope of overwritten values the same in both logic statements and operational statements by
  introducing the rule that the scope of a value begins with its definition and ends with the end
  of the scope of its variable.

  This feature embarasses me a little because, above, I was fussy over the conceptual distance of
  functional and logic languages from the procedural nature of the computer, and here we are,
  hiding a variable to hold the copy of the overwritten value and hiding the copy operation
  itself. My only defense is that it seems the best compromise if our primary goal is to integrate
  state and process.

  The ability to refer back to values that have been overwritten will only simplify program code a
  little, but the readability of programs is so important that this bit of simplification is still
  a worthwhile contribution of TrueJ. At any rate, for some programs, reusing old values does
  wonders. For instance, the semantics of the swap() method becomes so obvious from the code that
  writing it out as a separate means-statement adds useless verbage and detracts from its
  readability; instead, we just let the compiler infer the meaning of the method.

Example: Reusing an "overwritten" value when its variable is still in scope

  * A valid compile unit is
    """
    class Swapper2 {

    int 'a = 1, 'b = 2;

    void swap() {
      a' = 'b;
      b' = 'a;   // OK to use value 'a because the variable a is still in scope
    }

    } // end class
    """

Example: Notes

  Some other languages gain a similar simplification by allowing assignment of
  multiple values to corresponding variables in a single assignment statement.
  For example,

      a, b := b, a;

  which also requires a hidden copying of values.
  * end note

Example: We cannot refer to a value whose variable is out of scope

  When an invalid compile unit is
    """
    class Swapper3 {

    int 'a = 1, 'b = 2;

    void swap() {
      int startingA' = 'a;
      a' = 'b;
      b' = startingA';
    }
    means: startingA' = 'a && a' = 'b && b' = startingA';
       // startingA' value is out of scope here, outside the method's block,
       // because its variable startingA is declared inside the block

    } // end class
    """

  Then the only error message contains
    """
    Variable startingA has not been defined in this scope
    """


Rule: Intermediate value names use middle decoration

  Because the value of a variable may change more than once in a method, a way of naming the
  intermediate values is needed. This is accomplished by appending an apostrophe and additional name
  continuation characters to the variable name. The decorator is the apostrophe and all the
  following characters, but we use the term "middle-decorated" because of the apostrophe in the
  middle of other name characters. For instance lovely'14, lovely'temp2, or lovely'Mary could all be
  middle-decorated intermediate values of the variable named "lovely".

  We end up with the pleasant conceit that a variable's pre-execution value is pre-decorated, any
  mid-execution values are mid-decorated, and its post- execution value is post-decorated.

Example: Using middle-decorated value names

  * A valid compile unit is
    """
    class AllTrue {

    boolean 'a = true, 'b = true, 'c = false;

    boolean 'allTrue = false;

    void checkAll() {
      allTrue'reset = true;
      allTrue'thruA = (allTrue'reset && 'a);
      allTrue'thruB = (allTrue'thruA && 'b);
      allTrue'      = (allTrue'thruB && 'c);
    }
    means: allTrue' = ('a && 'b && 'c);    // equality is stickier than &&

    } // end class
    """


Rule: Using value names allows proving logical statements

  A means-statement is a first-order predicate logic statement, using value names, that summarizes
  everything the programmer needs to know about the code above it in order to understand the code
  that follows it. It is one of several statements that we call "status statements", because they
  reveal facts about the _state_ of the program at a specific point in its execution. From a code
  execution point of view, by the time any execution path through the code reaches it, the
  means-statement must be true.

  Other types of status statements will be introduced to let the programmer show why an otherwise
  mysterious means-statement is true and to ease the job of the prover. Constraints that are placed
  on a prover to make automated proofs useful to programmers and compilers will be covered as
  separate features.

  The means-statement is not just for helping programmers understand a program, it may assert only
  things that can be proven from the preceeding code or the compiler will mark it as an error. The
  prover has verified that all means statements in the above examples were accurate without
  mentioning it to the programmer, but we need an example where the prover finds an error.

Example: A means statement that is false

  When an invalid compile unit is
    """
    class Swapper4 {

    int 'a, 'b;

    void swap() {
      int startingA' = 'a;
      a' = 'b;
      b' = startingA';
    }
    means: a' = 'b && b' = 'b; // error here

    } // end class
    """

  Then the only error message contains
    """
    The code does not support the proof of the statement: b' = 'b
    """

Example: Notes

  <h3>Previous Research</h3>

  The use of Tony Hoare's logic (1969) to prove the correctness of programs often uses proof
  outlines, that is, assertions embedded in code -- not to check for errors during program
  execution, like the Java assert-statement, but to aid the construction of a proof of correctness
  and help programmers see the correctness as they read the code. These assertions were used soon
  after Hoare's logic paper, for instance (Hoare, 1971). The name "proof outline" seems to have
  been first used in publication by Owicki and Gries (1976). Fred Schneider (1995) gives a thorough
  explanation of them and summarizes their history. The means-statement of TrueJ was originally
  developed as a way to include proof outlines as an integral part of a language. This would
  balance the lopsided view of procedural programming languages as just a sequence of operations
  and encourage the programmer to focus just as much on the state as on the procedural operations.
  Because the Java assert-statement has a purely operational meaning, "means" was chosen to name
  the assertions, to call attention to the semantics of operations as changes to the state. But it
  quickly became clear that inserting a means-statement between every pair of operations just
  repeated the meaning of the operations, and in addition trivially repeated most of the syntax of
  the operations. Combined with a reading of Hener (1984), this led to thinking of each operation
  as having a predicate-calculus meaning, which led to backfitting the variable decorators from the
  means-statements into the operations in order to expose the fact that operations are also
  expressions in the predicate-calculus, which only worked when a naming convention was found that
  completely distinguished value names from variable names. This led to code syntax that encouraged
  a statement-by-statement focus on the changing state of the executing program. Non-operational
  logic statements are only needed in TrueJ when the facts that are stated by the operations need to
  be clarified, summarized, or restated as new concepts.

  Rigid variables, also called fixed variables, hold the initial value of changable variables for
  use in proofs and have become a standard part of proving program correctness (Hoare, 1969; Gries,
  19??; Schneider, 19??; Gries, 19??; Dijkstra, ????). A separate name for the initial values of
  variables is needed because specifications and other predicates describe the relationship between
  the initial and later states of the program's data. Whereas the common practice for rigid
  variables is to use a capitalized form of the variable that originally held the value of the rigid
  variable, initial values in TrueJ use predecorated forms of the variable names. However, previous
  work has only used rigid variables in comments and accompanying proofs of correctness, whereas
  value names are included as part of the TrueJ syntax for both operational code and logic, and are
  used to draw the attention of the programmer to changes in state as part of the normal coding
  process.

  Decorated variables have been used to identify a particular value of the variable by almost every
  computer scientist who has struggled with program semantics (and long before that by
  mathematicians and physicists describing change). A post-decorated variable name has been used to
  denote the initial value of a variable by some and the final value by others, leaving the other
  value to be denoted by the variable name without any decoration. The Eifel language (19??) also
  includes a syntax for the initial value of a variable in post-conditions of methods. This
  overloaded use of one name for both a variable and one of its values causes no problems when
  describing a single state of the program. In order to describe states across multiple points in
  the code, TrueJ clearly distinguishes between variables and values and brings the decoration
  tactic into the syntax of the language.

  Ward Maurer found a way to use the simple conjunction of statements in his
  modification index method (1977). He noted the advantage of post-decorating
  storage location names and variable names with integers to distinguish all the
  values of a variable while proving program correctness. The consistency of the
  relationship between a decorated name and a value throughout a program allowed
  Maurer to simplify construction of verification conditions for proofs using
  ordinary conjunction. Of course, program proof and program semantics are
  intertwined concepts, but Mauer never seems to have reflected on the
  implications of his work for program semantics. As in Maurer's work, TrueJ
  takes advantage of the use of values in interacting with a prover.

  Single assignment languages identify the concepts of variable and value by requiring a new
  variable name at each assignment (Tesler and Enea, 1968), whereas TrueJ requires a new value name
  to be associated with a variable at each assignment. Some single assignment languages allow
  statements to be entered in any order, since the unique variable names can be used to sort
  statements into a correct execution order, but TrueJ requires the programmer to specify the
  execution order and merely checks that no names are used out of order.

  The static single assignment (SSA) intermediate representation for languages assigns a modified
  variable name to every unique value of a variable. It is used in compiler writing (Rosen, et. al,
  1988) to simplify static analysis for code optimization. One might think of TrueJ as repurposing
  SSA for program understanding in order to simplify the job of programmers instead of compilers.

  Eric Hehner showed that programs are predicates (Hehner, 19??; Hoare and Hanna, 19??; Hoare,
  19??). TrueJ explores this idea with a first-order predicate logic that uses only value names,
  abandoning the complications of programming variables that can change value in the middle of
  solving a problem. Hehner (??? part I) uses a syntax for initial and and final decoration of
  variables similar to TrueJ, but with the apostrophes over the variable names. This is a naming
  convention that is not congenial to the current convention of code as ASCII text, but he avoids
  using it in code by defining the standard operations that we see in computer code as equivalent to
  predicates over these values. His focus is on showing that the code we normally see in computer
  programs can be defined in a form of predicate logic, so that there is truly no difference between
  computer programs and predicate logic, with no need for syllogisms that show how to work in both
  languages at once. TrueJ carries this thinking a step further by making every operational code
  statement into an explicit predicate logic statement over the values names, so that the steps of
  proofs are written in the code.

  Hoare logic and the "programs are predicates" approach provides a firm mathematical foundation for
  understanding programming variables. The tradition in this type of mathematical analysis is to use
  the same name for a variable and for one of its values, which works well for stating predicates
  that only refer to a single state, but complicates the formalization of assignment and of
  sequential composition of separately analyzed program sections. The added complication for
  sequential composition is that renaming is required in order to synchronize the variable/value
  names after one operation with the beginning of the next, which requires additional proof steps.
  The use of value names in TrueJ makes this additional mental baggage disappear. However, as we
  explore more features of TrueJ, we will require the programmer to name the initial and final
  values for variables that change within a method or programming construct, and there is a sense in
  which this use of TrueJ's value names are simply a way of solving the equations for sequential
  composition that are given by Hehner and Hoare. And this is exactly what we expect it to be as its
  all just mathematics. We merely wish to pose the empirical hypothesis that TrueJ's notation will
  help the programmer see what is true about the state as the program executes, that is, see what
  the program means.


  <h3>Conclusion</h3>

  TrueJ provides a syntax for naming values as well as variables in a
  Java-like programming language. Because the syntax of an operation is
  expressed with named constant values, we do not need to invent a special logic
  to help us keep track of the changing values held by variables. This allows
  the programmer to see that every operation is itself a logic statement which
  relates the state before the operation to the state after. And because
  operations are predicates, we are able to see that the meaning of a sequence
  of operations is simply their conjunction.

  It can be hoped that using value names to draw the attention of the programmer to changes in state
  and integrating a prover into the compiler will lead to a practical fulfillment of the idea of
  constructing programs in parallel with their proofs of correctness (?Dijktra?, ????). Indeed, it
  looks like they are they are one and the same task, and TrueJ can be thought of as a syntax that
  shows that programs are proofs (????).

  Ah, well, we do realize that we have demonstrated this grand idea only for those programs that are
  a simple sequence of assignments -- we will cover the complications introduced by control
  structures, method calls, object orientation, aliasing, concurrency, proofs of correctness, and
  the use of interfaces for program specification in separate feature descriptions.


  <h3>Thanks</h3>

  TrueJ builds upon the considerable orderly thinking that underlies
  the complexity of the Java language. Many thanks to the creators of Java, to
  the Sun and Oracle corporations for developing and supporting it, and to the
  Java Community for their work through the years.


  <h3>References</h3>

    David Chisnall. 2018. C Is Not a Low-level Language. Queue Vol. 16, No. 2, April, 2018.
    DOI: https://doi.org/10.1145/3212477.3212479

    David Gries and Fred B. Schneider, A Logical Approach to Discrete Math, Springer-Verlog, 1993.

    Hehner, A Practical Theory of Programming, 1984.

    C. A. R. Hoare, "An Axiomatic Basis for Computer Programming",
    Communications of the ACM, Vol. 12, No. 10, Oct., 1969.

    C. A. R. Hoare and F. K. Hanna, "Programs are Predicates", Philosophical
    Transactions of the Royal Society of London. Series A, Mathematical and
    Physical Sciences, Vol. 312, No. 1522, Mathematical Logic and Programming
    Languages (Oct. 1, 1984), pp. 475-489

    C. A. R. Hoare, "Proof of a program: Find", Communications of the ACM, Vol.
    14, No. 1, Jan., 1971.

    W. D. Maurer. 1977. "The modification index method of generating verification conditions". In
    Proceedings of the 15th annual Southeast regional conference (ACM-SE 15). ACM, New York, NY,
    USA, 426-440. DOI=http://dx.doi.org/10.1145/1795396.1795456

    Susan Owicki and David Gries, "An axiomatic proof technique for parallel
    programs I", Acta Informatica, Vol. 6, pp. 319-340, 1976.

    Barry Rosen; Mark N. Wegman; F. Kenneth Zadeck, 1988. "Global value numbers
    and redundant computations". In Proceedings of the 15th ACM SIGPLAN-SIGACT
    symposium on Principles of programming languages. ACM, New York, NY, USA,
    12-27. DOI=http://dx.doi.org/10.1145/73560.73562

    Fred B. Schneider, "Notes on Proof Outline Logic", Technical Report, Cornell
    University, Ithaca, NY, 1995.

    L. G. Tesler and H. J. Enea. 1968. A language design for concurrent
    processes. In Proceedings of the April 30--May 2, 1968, spring joint
    computer conference (AFIPS '68 (Spring)). ACM, New York, NY, USA, 403-408.
    DOI=http://dx.doi.org/10.1145/1468075.1468134


  <h4>Copyright (c) 2017, George S. Cowan<h4>
  * end notes
