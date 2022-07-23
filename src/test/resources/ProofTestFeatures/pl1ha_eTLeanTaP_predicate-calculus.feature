Feature: Predicate Calculus     (Tests for the eLeanTaP system)
  Copyright and license information at bottom of file.

  This file contains the tests for the axioms and theorems of the predicate
  calculus. We rely on Gries & Schneider (1993) in testing a complete set of
  theorems, and parenthetic numbers are a reference to the the
  theorems collected in their final pages.

  More details on the prover and its language is in the feature file
  `a1_eLeanTap_eqivalence_truth.feature`, but here we discuss the language of quantification in the
  first-order predicate language that the prover uses.

  The universal and exitential quantifiers are represented as functions `all` and `ex`, taking
  either two or three arguments. The three-argument versions take parameters for

  1. a variable name, which must contain only letters, digits, and the underscore character, and
     must begin with a capitalized letter, such as, `X`, `Person`, or `Something_else_`,
     but not `a`, `12`, `$`, `joe` or `_Joe`.
  2. a range predicate, which restricts the range for which the body predicate holds
  3. a predicate for the body.

  The two-argument versions have only a variable and a body predicate, with no restriction in range.

  The for-all statement, or universal quantification, provides the ability to make general
  statements about the universe of entities. The two-argument statement:

      all(X, p(X))

  is read as "for all X, p(X)". For example,

      all(X, X + 0 = X)

  The three-argument for-all statement allows limiting the range of the entities that it applies to:

      all(X, range-of-X, p(X))

  which is read as "for all X such that range-of-X, p(X)". For example,

      all(X, X < 0, 2*X < X)

  The there-exists statement, or existential quantification, provides the ability to claim that
  there is at least one entity in the universe that has a property. The two-argument statement:

      ex(X, p(X))

  is read as "there exists an X such that p(X)" or "for some X, p(X)". For example,

      ex(X, X = successor(0))

  The three-argument there-exists statement allows placing an additional limit on the enitity's
  range:

      ex (X, range-of-X, p(X))

  which is read as "there exists an X where range-of-X such that p(X)". For
  example,

      ex(X, even(X), squareOf(2) = X).

  The two-argument versions can be translated into the three-argument versions by using a range that
  does not restrict the variable at all. To do this, we use `true` as the restriction, meaning that
  no matter what value you choose for the variable, the restriction will be satisfied (true) for the
  value.

      all(X,p(X)) === all(X,true, p(X))
      ex (X,p(X)) === ex(X,true, p(X))

  The three-argument versions may be translated into the two-argument versions in the following way.

    all(X,range,p(X)) === all(X,range ==> p(X))
    ex (X,range,p(X)) ===  ex(X,range /\  p(X))

  Quantified statements may be either a _valid theorem_ or _inconsistent_, or may be _unsupported_,
  that is, consistent but not valid, so that additional statements could be added to force it either
  way. In addition, the attempt to prove a quantified statement may go into a loop forcing our
  prover to give up before it runs out of memory or time.

Background: The theorem prover is loaded into a tuProlog engine
  Given a Prolog engine
  And the eTLeanTap theory is loaded
#  And Java debugging
#  And using feature "pl1ha_eTLeanTaP_predicate-calculus"

Rule: A Generalized De Morgan Axiom relates universal and existential quantification

Example: Generalized De Morgan (9.18 & 9.19)

  * the following theorems hold
    """
     ex(X,r(X),  p(X)) === -all(X, r(X), -p(X))
    -ex(X,r(X), -p(X)) ===  all(X, r(X),  p(X))
    -ex(X,r(X),  p(X)) ===  all(X, r(X), -p(X))
     ex(X,r(X), -p(X)) === -all(X, r(X),  p(X))
    """

Rule: Arbitrary statements are not likely to be valid theorems

Example: A simple non-theorem

  We can't know that this first-order predicate (FOP) is true for all `Y` and all `X` because there
  might be a counterexample: a value for `p(Y)` and `p(X)` where we are claiming that `false ==>
  true`.

  When the FOP is "all(Y, all(X,   p(Y) ==> p(X)   ))"
  Then it is not a theorem


Rule: Quantified variables may be given new names

  The `all` and `ex` statements bind variables locally, and the names used for
  these variables may be chosen arbitrarily, as long as the name is not
  used in an unbound sense in the enclosed expression.

Example: Renaming in a for-all statement (8.21)
  * Formula "all(X, p(X)) === all(Y, p(Y))" is a theorem

Example: Renaming in a there-exists statement (8.21)
  * Formula "ex(X, p(X)) ===  ex(Y, p(Y))" is a theorem

Example: Renaming when the variable is bound at a higher level

  Even though `X` is bound at the level of the outer there-exists expression, that binding of `X` is not used in the inner one, `ex(Y, p(Y))`, so `X` is available for substitution for the
  `Y` in that innermost there-exists expression.

  * Formula "ex(X, (p(X)===(X=X))   ==>   ex(Y, p(Y)) )" is a theorem
  * Formula "ex(X, (p(X)===(X=X))   ==>   ex(X, p(X)) )" is a theorem


Rule: Universally quantified variables may be instantiated to any constant or free variable

  This is Theorem (9.13) in Gries & Sneider.

Example: Examples of instantiation of a universally quantified variable

* Formula "all(X, p(X)) ==> p(a) " is a theorem

* Formula "all(X,p(X)) ==> p(a) /\ p(b) /\ p(c)" is a theorem

* Formula "all(X,p(X)) ==> p(Y)" is a theorem

* Formula "all(X,p(X)) ==> p(f(a))" is a theorem


Rule: Additional unnamed items do not necessarily exist
  Items must be mentioned in order for us to depend upon their existance. In general we cannot
  assume that things exist.

Example: A different element does not neccesarily exist
  Because no other element than `a` is mentioned, it is possible that there is no other element.

  * Formula "ex(X,(a#=X))" is not a theorem

Example: However, an equivalent element does exist
  Because `a=X` does not require that `X` be a different element, `X` can be `a`, and `a=a`.

  * formula "ex(X,(a=X))" is a theorem

Example: And we can just name a different element
  * Formula "(a#=b) ==> ex(X,(a#=X))" is a theorem

Example: Or we can specify the existence of a different element without naming it
  * Formula "ex(Y,a#=Y) ==> ex(X,(a#=X))" is a theorem


Example: An object can have two different names
  Or you can think of them as being two objects which should be treated the same in the problem area
  that you are working on.

  * formula "(a=b) ==> ex(X, (a=X))" is a theorem


Rule: A range predicate can be included

  Universal quantification with a range:

      all(Variable, range(Variable), body(Variable)

  or, a more succinct example:

      all(X, r(X), p(X))

  which is read as "For all X such that r(X), p(X)".

  An example for existential quantification:

      ex(X, r(X), p(X))

  can be read as "There exists an X such that r(X) where p(X)", or as "For some X, where r(X),
  p(X)".

Example: Moving the range into or out of the body (Trading) (9.2 and 9.19)

  The range predicate in both universal and existential quantification can be moved into the body by
  combining it with the proper operator.  Or you can consider these to be a definition of the three
  parameter quantifications, with a range predicate, in terms of two parameter quantification with
  just a variable and a body.

* the following theorems hold
  """
  all(X, r(X), p(X)) === all(X, r(X) ==> p(X))
   ex(X, r(X), p(X)) ===  ex(X, r(X) /\  p(X))
  """


Scenario Outline: Trading between the range and body(9.3, 9.4, 9.19, and 9.20)

  When the FOP is "<Statement>"
  Then it is a "<Result>"

  Examples:
    | Result    | Statement                                                           |
   #|-----------|---------------------------------------------------------------------|
    | theorem   | all(X, r(X), p(X)) === all(X, -r(X) \/ p(X))                        |
    | theorem   | all(X, r(X), p(X)) === all(X, r(X) /\ p(X) === r(X))                |
    | theorem   | all(X, r(X), p(X)) === all(X, r(X) \/ p(X) === p(X))                |

    | theorem   | all(X, q(X) /\ r(X), p(X)) === all(X, q(X),  r(X) ==> p(X))         |
    | theorem   | all(X, q(X) /\ r(X), p(X)) === all(X, q(X),  -r(X) \/ p(X))         |
    | theorem   | all(X, q(X) /\ r(X), p(X)) === all(X, q(X),  r(X) /\ p(X) === r(X)) |
    | theorem   | all(X, q(X) /\ r(X), p(X)) === all(X, q(X),  r(X) \/ p(X) === p(X)) |

    | theorem   |  ex(X, r(X), p(X)) === ex(X, r(X) /\ p(X))                         |
    | theorem   |  ex(X, q(X) /\ r(X), p(X)) === ex(X, q(X),  r(X) /\ p(X))          |



Rule: Quantifier axioms and theorems from Gries & Sneider (1993, p.148-166)

  We provide examples of the quantifier axioms and theorems for the for-all and there-exists
  expressions.

  As a convention, we use quantified variables `X`, `Y`, and `Z`; constant elements from the domain
  `a`, `b`, and `c`; expressions or functions over the elements of the domain `f` and `g`, as in
  f(a), f(X), or f(X,a); and p, q, r for predicates over the elements, as in p, p(X), q(f(X), b).
  Sometimes we will use r instead of r(X), but we intend that r might or might not refer to X.

Example: Substitution in the range (Leibniz) (8.12)

  Given assumption
    """
    all(X, p(X) === q(X))
    """
  Then the following theorems hold
    """
    all(X, p(X), body(X)) === all(X, q(X), body(X))
     ex(X, p(X), body(X)) ===  ex(X, q(X), body(X))
    """

Example: Substitution in the body (Leibniz) (8.12)

  Given assumption
    """
    all(X, range(X), (p(X) === q(X)))
    """
  Then the following theorems hold
    """
    all(X, range(X), p(X)) === all(X, range(X), p(X))
     ex(X, range(X), p(X)) ===  ex(X, range(X), q(X))
    """

Scenario Outline: Simple examples

  Examplesof Empty Range (8.13), the One Point Rule (8.14), and quantifiers distributing over their
  base operators (8.15), which could also be thought of as splitting the body of the quantifier.

  When the FOP is "<Statement>"
  Then it is a "<Result>"

  Examples:
    | Result    | Statement                                               |
   #|-----------|---------------------------------------------------------|
    | theorem   | all(X,false, p) === true                                |
    | theorem   |  ex(X,false, p) === false                               |

    | theorem   | all(X, (X=f(a)), p(X)) === p(f(a))                      |
    | theorem   |  ex(X, (X=f(a)), p(X)) === p(f(a))                      |

    | theorem   | all(X, p(X) /\ q(X) ) === all(X, p(X)) /\ all(X, q(X))  |
    | theorem   | all(X, p(X) /\ q(X) ) === all(Y, p(Y)) /\ all(Z, q(Z))  |

    | theorem   |  ex(X, p(X) \/ q(X) ) ===  ex(X, p(X)) \/ ex(X, q(X))   |
    | theorem   |  ex(X, p(X) \/ q(X) ) ===  ex(Y, p(Y)) \/ ex(Z, q(Z))   |

    |non-theorem| all(X, p(X) /\ q(X) ) === all(X, p(X)) \/ all(X, q(X))  |
    |non-theorem|  ex(X, p(X) \/ q(X) ) ===  ex(X, p(X)) /\  ex(X, q(X))  |

Example: Range split for idempotent operators (8.18)

  Because both conjunction and disjunction are idempotent, that is, `true /\ true === true` and
  `false /\ false = false`, and likewise for `\/`, and `all` and `ex` are quantifiers for `/\` and
  `\/`, we have the following simple split for disjunctions. (We don't have an example for
  Quantification Axioms (8.16) and (8.17) because this subsumes them.

  * the following theorems hold
    """
    all(X, rangeA(X) \/ rangeB(X), p(X)) === all(X, rangeA(X), p(X)) /\ all(X, rangeB(X), p(X))
     ex(X, rangeA(X) \/ rangeB(X), p(X)) ===  ex(X, rangeA(X), p(X)) \/  ex(X, rangeB(X), p(X))
    """

Example: Interchange of Quantified Variables (8.19)

  Nested quantifiers of the same type can be swapped.

  * the following theorems hold
  """
  all(X, r(X), all(Y, q(X), p(X))) === all(Y, q(X), all(X, r(X), p(X)))
   ex(X, r(X),  ex(Y, q(X), p(X))) ===  ex(Y, q(X),  ex(X, r(X), p(X)))
  """

Example: Change of Dummy (8.22)

  The general quantification theorem (8.22) in Gries and Schneider requires that the function has
  an inverse, and for the quantifiers `all` and `ex`, a similar assumption is needed.

  Given assumption unless inconsistent
  """
  all(X, ex(Y, (X = f(Y))))
  """

  Then the following theorems hold
    """
    all(X, r(X), p(X)) === all(Y, r(f(Y)), p(f(Y)))
     ex(X, r(X), p(X)) ===  ex(Y, r(f(Y)), p(f(Y)))
    """

Example: \/ distributes over `all`, /\ distributes over `ex` (9.5 and 9.21)
  As long as it does not contain the quantified variable, a predicate can be moved from a disjunct
  into and out of the body of a universal quantification, or from a conjunct into or out of an
  existential quantifier.

  * the following theorems hold
  """
  p(a) \/ all(X, r(X), q(X)) === all(X, r(X), p(a) \/ q(X))
  p(a) /\  ex(X, r(X), q(X)) ===  ex(X, r(X), p(a) /\ q(X))
  """

Example: Trading the whole body out of a logical quantifier (9.6)

  If the body does not refer to the quantified variable, then the whole body can be moved out of the
  quantification. There is a corner case about whether or not there is an element in the domain
  that is covered by the final quantifier in the formulas. We also show the how to cover the corner case with an assumption.

  * the following theorem holds
    """
    all(X, r(X), p(a)) === p(a) \/ all(X, -r(X))
     ex(X, r(X), p(a)) === p(a) /\  ex(X,  r(X))
    """

  Given assumption
    """
    ex(X, r(X))
    """
  Then the following theorems hold
    """
    all(X, r(X), p(a)) === p(a)
     ex(X, r(X), p(a)) === p(a)
    """

Example: Trading a predicate out of the body (9.7)
  A predicate can be moved into and out of the body of a quantification as long as it does not
  contain the quantified variable, and the high-level operator of the body is the base operator of
  the quantification. In addition, there must be at least one element of the domain that meets the
  constraints of the range predicate.

  Given assumption
    """
    ex(X, r)
    """
  Then the following theorems hold
    """
    p(a) /\ all(X, r, q(X)) === all(X, r, p(a) /\ q(X))
    p(a) \/  ex(X, r, q(X)) ===  ex(X, r, p(a) \/ q(X))
    """

Scenario Outline: Additional theorems for logical quantification

  When the FOP is "<Statement>"
  Then it is a "<Result>"
  And note that "<Note>"

  Examples:
    | Result    | Statement                                                    | Note   |
   #|-----------|--------------------------------------------------------------|--------|
    | theorem   | all(X, r(X),  true) === true                                 | (9.8)  |
    | theorem   |  ex(X, r(X), false) === false                                | (9.24) |

    | theorem   | all(X, r, p === q ) ==> (all(X, r, p) === all(X, r, q))      | (9.9)  |

    | theorem   | all(X, q(X) \/ r(X), p(X)) ==> all(X, q(X), p(X))            | (9.10) |
    | theorem   |  ex(X, q(X) \/ r(X), p(X)) <==  ex(X, q(X), p(X))            | (9.25) |

    | theorem   | all(X, r(X), p(X) /\ q(X)) ==> all(X, r(X), p(X))            | (9.11) |
    | theorem   |  ex(X, r(X), p(X) \/ q(X)) <==  ex(X, r(X), p(X))            | (9.26) |

    | theorem   | all(X,r,q(X) ==> p(X)) ==> (all(X,r,q(X)) ==> all(X,r,p(X))) | (9.12) |
    | theorem   | all(X,r,q(X) ==> p(X)) ==> ( ex(X,r,q(X)) ==>  ex(X,r,p(X))) | (9.27) |

    | theorem   | all(X,p(X)) ==> p(e)                                         | (9.13) |
    | theorem   |  ex(X,p(X)) <== p(e)                                         | (9.28) |

Example: Interchange of quantification (9.29)

  * the following theorem holds
    """
    ex(X, r(X), all(Y, q(Y), p(X,Y))) ==> all(Y, q(Y), ex(X, r(X), p(X,Y)))
    """

Example: Metatheorem - Witness (9.30)

  In a proof of `q` that uses `ex(X, r(X), p(X))`, we are allowed to pick a new name for the member of the domain that satisfies the existential quantification, where by "new" we mean that it
  does not occur anywhere else in the problem statement, i.e., it does not occur in `r(X)`, `p(X)`, or `q`. So, supposing we picked the name `a`, and we had a proof showing that

      ex(X, r(X), p(X)) ==> q

  then that is equivalent to

      r(a) /\ p(a) ==> q

  Theprover uses skolemization internally to do this for us. So any thing that we can prove by hand
  using a witness, our prover can prove using skolemization. But we can't show an example of picking
  the witness because we have to choose a name for the skolemization that is not present in the
  statement to be proven. Take the example

      ex(X, p(X)) === p(x1)

  This doesn't work in our prover because our name for skolemization, `x1`, is present in the example, on the
  right-hand side. Our prover does not know that it is intended as a skolemization name and
  interprets the above statement as claiming that if you choose any old member of the domain, that
  member will have the property that is true for some member. Here is an example where it is
  obviously false:

      x1 = 3 /\ (ex(X, even(X)) === p(x1))

  It should be possible to do a scan of the statement to make sure that the name is not used for
  anything that prevents it being a skolemization instance name, but our prover is not that
  complicated.

  * the following theorems hold
    """
    (ex(X, r(X), p(X)) ==> q) === all(Y, r(Y) /\ p(Y)  ==> q)
    (ex(X, r(X), p(X)) ==> q) ==>    (  (r(a) /\ p(a)) ==> q)
    """

  But the following is not a theorem
    """
    (ex(X, r(X), p(X)) ==> q) <==    (  (r(a) /\ p(a)) ==> q)
    """

Rule: We can only quantify objects, not logical statements

  (Um, apparently we can do _some_ second-order logic, but please don't -- the
  system is not tested for that.)

  In first order logic, operators like `==>` (implies), `-` (not), and `\/` (or) may only operate on
  logical statements and not variables over the domain of statements; arbitrary statements can be
  hinted at by using predicates like `p(x,y)`, where `p` indicates to us "any predicate", but we
  can't use `P(x,y)`, where the `P` is a variable over any functor, like `owns` in `owns(x,y)` or
  `=` in `x = y`. But in second order logic, we can have statements about statements, which are
  represented as quantified variables. In the example for our rule below, the first formula is to be
  read as "for all statements `X` and `Y` such that statement `X` implies statement `Y`, statement
  `X` is false or statement `Y` is true".

Example: A confusing example of what NOT to do, so don't do either of these
  * Formula "all(X,all(Y,(X ==> Y)  ==>  (-X \/ Y)))" is not a theorem
  But Formula           "(X ==> Y)  ==>  (-X \/ Y)" is a theorem


Rule: The prover may be able to halt after exploring only a finite portion of an infinite domain

  Smullyan (2014, p. 158-159) uses the concept of Hintikka sets to show that his tableau proof
  method will sometimes generate all possible elementary propositions (literals) relevant to a proof
  when only a finite portion of in infinite domain has been explored, allowing us to see that, if we
  have not yet reached a proof, then the conclusion is not supported by the given premise and
  attempts to prove it would continue forever. But it seems he never modified his method to take
  advantage of completing a Hitikka set, instead relying on a person visually searching up the path
  from the branch and recognizing that all the possibilities have been tried.
  ### WRONG
  #Our prover automates
  #this check and halts when a Hintikka set has been found, shortcircuiting many proofs that would
  #otherwise run forever, or actually, until a run limit is reached.

  #The prover keeps track of enough information to recognize and report that all possibilities
  #have been exhausted. It does this by tracking the domain elements that are used to instantiate a
  #for-all statement. If the instance of a for-all statement is never used, then nothing will be
  #accomplished by instantiating that statement for that element again.

  #The idea in both of the following examples is that the axioms for less-than are known to be
  #consistent for the natural numbers. Because we use statements that have a known interpretation, we
  #know that our attempt to prove them inconsistent should fail. Our prover catches the infinite
  #proof in a finite number of steps for the original formulation of both of the examples, but once
  #we introduce the existence of zero, our prover only stops when the imposed depth limit is reached.

###########################################
#            WORKING HERE                 #
#@testthis
#                                         #
###########################################

### TODO: How does this reach limit? Modify debugging so that it will be easier to trace!!!

Example: Smullyan (1971, p.63)
  Smullyan provides a set of statements that we know are consistent, and that his tableau method
  cannot deal with. His example is a few formulas for `n < m` for the natural numbers. Here we write
  `lt(n,m)` as the predicate for `n < m`. Our prover is able to recognize that there will be no
  solution and quits early.

  However,when we add one more line to his example, claiming that at least one number, zero,
  actually exists, our prover only stops when it reaches the depth limits that we have imposed.

    * The conjunction of these formulas is contingent
    ### Create this test after finding why the formulas run forever
    #* The following formulas reach a limit of 40

      """
      all(X1,ex(Y1,lt(X1,Y1)))
      -ex(X2,lt(X2,X2))
      all(X3, all(Y3, all(Z3, (lt(X3,Y3) /\ lt(Y3,Z3)) ==> lt(X3,Z3) )))
      """

# TODO: modify to note that the following isn't needed (Wait. isn't needed for what?)
##TODO: Turn the following back on for more work
#    * The following formulas reach a limit of 40
#      """
#      ex(Zero,all(X,(X#=Zero) ==> lt(Zero,X)))
#      all(X1,ex(Y1,lt(X1,Y1)))
#      -ex(X2,lt(X2,X2))
#      all(X3, all(Y3, all(Z3, (lt(X3,Y3) /\ lt(Y3,Z3)) ==> lt(X3,Z3) )))
#      """


Example: Zegarelli (2007, p.295-297)

  Zegarelli chooses the fact in the natural numbers that every number is less than some other
  number and attempt to prove that it is false.

  #In this case, the prover recognizes that the statement cannot match any other elementary statement
  #and immediately terminates with a recognition that it is consistent.

  # Don't we need to have it report that it is consistent

##TODO: turn this back on for more work here
#  * the following statement is contingent
#    """
#    all(X, ex(Y, lt(X,Y)))
#    """
#
#  * The conjunction of these formulas reaches the limit
#    """
#    ex(Zero,all(X,(X#=Zero) ==> lt(Zero,X)))
#    all(X, ex(Y, lt(X,Y)))
#    """



#   Ensure that debugging starts as off for any following feature tests
  * Debugging off

#<h3> But not the integers? TEMPORARY!!! </h3>
#
#  The first example is an attempt to make the prover run out of depth. We don't need
#  the following propositions.
#
#      exists(X, X=zero)
#      all(X, X #= zero, exists(Y, X=successor(Y)))
#
#  * Debugging on
#  * Using feature "pl1ha_eTLeanTaP_predicate-calculus - A difficult example for some provers"
#  Given assumptions
#    """
#    naturalNumber(one)
#    all(X, naturalNumber(X) === naturalNumber(successor(X)))
#    all(X, -(successor(X) = one))
#    all(X, all(Y, (successor(X) = successor(Y))  ==> (X = Y)))
#    other(one) /\ all(X, other(X) ==> other(successor(X)) ==> all(X, other(X) === naturalNumber(X)))
#    """
#  Then the proof of this statement reaches the depth limit
#    """
#    all(X, -(successor(successor(X)) = one))
#    """



Example: REFERENCES

  David Gries & Fred B. Schneider, _A Logical Approach to Discrete Math_,
  Springer-Verlag, 1993.

  Raymond M. Smullyan, _

  Raymond M. Smullyan, _A Beginner's Guide to Mathematical Logic_,
  Dover, 2014.

Example: COPYRIGHT

  Copyright George S. Cowan, June 2016. Licensed under the BSD 3-clause
  License which can be found packaged with the eLeanTaP system or at

      <https://opensource.org/licenses/BSD-3-Clause>
