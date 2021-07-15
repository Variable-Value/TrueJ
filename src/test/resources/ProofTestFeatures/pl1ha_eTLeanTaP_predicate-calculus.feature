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

Rule: Arbitrary statements are not likely to be valid theorems

Example: A simple non-theorem

  We can'tknow that this first-order predicate (FOP) is true for all `Y` and all `X` because there
  might be a counterexample, values where we are claiming that `false ==> true`.

  When the FOP is "all(Y, all(X,   p(Y) ==> p(X)   ))"
  Then it is not a theorem


Rule: Quantified variables may be given new names

  The `all` and `ex` statements bind variables locally, and the names used for
  these variables may be chosen arbitrarily, as long as the name is not
  used in an unbound sense in the enclosed expression.

Example: Renaming in a for-all statement
  * Formula "all(X, p(X)) === all(Y, p(Y))" is a theorem

Example: Renaming in a there-exists statement
  * Formula "ex(X, p(X)) ===  ex(Y, p(Y))" is a theorem

Example: Renaming when the variable is bound at a higher level

  Even though `X` is bound at the level of the outer there-exists expression, that binding of `X` is not used in the inner one, `ex(Y, p(Y))`, so `X` is available for substitution for the
  `Y` in that innermost there-exists expression.

  * Formula "ex(X, (p(X)===(X=X))   ==>   ex(Y, p(Y)) )" is a theorem
  * Formula "ex(X, (p(X)===(X=X))   ==>   ex(X, p(X)) )" is a theorem


Rule: Universally quantified variables may be instantiated to any constant or free variable

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

Example: But we can just name a different element
  * Formula "(a#=b) ==> ex(X,(a#=X))" is a theorem

Example: Or we can specify the existence of a different element without naming it
  * Formula "ex(Y,a#=Y) ==> ex(X,(a#=X))" is a theorem

Example: However, an equivalent element does exist
  Because `a=X` does not require that `X` be a different element, `X` can be `a`, and `a=a`.

  * formula "ex(X,(a=X))" is a theorem

Example: An object can have two different names
  Or you can think of them as being two objects which should be treated the same in the problem area
  that you are working on.

  * formula "(a=b) ==> ex(X, (a=X))" is a theorem


Rule: We can only quantify objects, not logical statements

  Um, apparently we can do _some_ second-order logic, but please don't -- the
  system is not tested for that.

  In first order logic, operators like ==> (implies), - (not), and \/ (or) may only be used with
  logical statements and not with quantified objects. But in second order logic, we can have
  statements about quantified statements. In the example for our rule below, the first
  formula is to be read as "for all statements `X` and `Y` such that statement `X` implies
  statement `Y`, statement `X` is false or statement `Y` is true".

Example: A confusing example of what NOT to do
  * Formula "all(X,all(Y,X ==> Y,-X \/ Y))" is not a theorem
  But Formula "(X ==> Y)  ==>  (-X \/ Y)" is a theorem


Rule: Quantifier axioms and theorems from Gries & Sneider (1993, p.148-152)

  We are not able to test the quantifier axioms and theorems themselves because they are stated in a
  general form, covering all expressions and predicates, but we do provide examples of the them for
  the for-all and there-exists expressions.

  We use X, Y, and Z for our quantified variables; a, b, and c for our constant elements from the
  domain; f for expressions or functions over the elements of the domain, as in f(a), f(X), or
  f(X,a); and p, q, r for predicates over the elements, as in p, p(X), q(f(X), b).

Example: Substitution in the range (Leibniz) (8.12)

  Given assumption
    """
    p_range === q_range
    """
  Then the following theorems hold
    """
    all(X, p_range, body) === all(X, q_range, body)
     ex(X, p_range, body) ===  ex(X, q_range, body)
    """

Example: Substitution in the body (Leibniz) (8.12)

  Given assumption
    """
    r_range ==> (p_body === q_body)
    """
  Then the following theorems hold
    """
    all(X, r_range, p_body) === all(X, r_range, q_body)
     ex(X, r_range, p_body) ===  ex(X, r_range, q_body)
    """

Scenario Outline: Simple examples

  When the FOP is "<Statement>"
  Then it is a "<Result>"
  * Note that "<Note>"

  Examples:
    | Result    | Statement                          | Note                       |
   #|-----------|------------------------------------|----------------------------|
    | theorem   | all(X,false, p) === true           | Empty Range (8.13)         |
    | theorem   |  ex(X,false, p) === false          | Empty Range (8.13)         |
    | theorem   | all(X, (X=f(a)), p(X)) === p(f(a)) | One Point Rule (8.14)      |
    | theorem   |  ex(X, (X=f(a)), p(X)) === p(f(a)) | One Point Rule (8.14)      |

# *******************************************
# ************** WORKING HERE ***************
# *******************************************

#    | theorem   |  ex(X,false, p) === false | Empty Range (8.13)         |
#    | theorem   |  ex(X,false, p) === false | Empty Range (8.13)         |
#    | theorem   |  ex(X,false, p) === false | Empty Range (8.13)         |
#    | theorem   |  ex(X,false, p) === false | Empty Range (8.13)         |
#    | theorem   |  ex(X,false, p) === false | Empty Range (8.13)         |
#    | theorem   |  ex(X,false, p) === false | Empty Range (8.13)         |
#    | theorem   |  ex(X,false, p) === false | Empty Range (8.13)         |


  # TODO: enter tests for the rest of the G&S predicate calculus theorems




Rule: Logical quantifiers distribute over their base operators (8.15)

  Forall distributes over /\ and forsome distributes over \/. Note that both /\ and \/ are
  symetric (commutative) and associative with an identity element. So distributing the forall quantifier over /\ is just rearranging the order of its base operator /\, and likewise for the forsome quantifier.

Example: Axiom 8.15 of Gries & Schneider (1993) applied to the logical quantifiers.

  *   Formula "all(X, p(X) /\ q(X) ) === all(X, p(X)) /\ all(X, q(X))" is a theorem
  And Formula "all(X, p(X) /\ q(X) ) === all(Y, p(Y)) /\ all(Z, q(Z))" is a theorem

  And Formula "ex(X, p(X) \/ q(X) ) === ex(X, p(X)) \/ ex(X, q(X))" is a theorem
  And Formula "ex(X, p(X) \/ q(X) ) === ex(Y, p(Y)) \/ ex(Z, q(Z))" is a theorem

  But Formula "all(X, p(X) /\ q(X) ) === all(X, p(X)) \/ all(X, q(X))" is not a theorem
  And Formula  "ex(X, p(X) \/ q(X) ) ===  ex(X, p(X)) /\  ex(X, q(X))" is not a theorem


Rule: A prover can always halt for a finite domain

  Smullyan (2014, p. 159) shows that his tableau proof method can always generate all possible elementary
  propositions relevant to a proof in a finite domain, allowing us to see that if we have not yet
  reached a proof then the conclusion is not supported by the given premise. But it seems he never
  modified his method to take advantage of it, instead relying on a person visually searching up the
  tree of a branch and recognizing that all the possibilities have been tried.

  TrueJ's prover keeps track of enough information to recognize and report that all possibilities
  have been exhausted. It does this by tracking the domain elements that are used to instantiate a
  for-all statement. If the instance of a for-all statement is never used, then nothing will be
  accomplished by instantiating that statement for that element again. to make sure that the
  instantiated statements are used before instantiating them again for that element.

  Once we introduce the integers, we will explore the conditions for creating an infinite loop in
  the prover, so that it stops only when it reaches its depth limit.

Example: The counting numbers aren't infinite

  This example is taken from Zegarelli (2007, p.295-297).

Example:
  The second
  example is from Smullyan (1971, p.63). The idea in both is that the axioms for
  less-than in the natural numbers are known to be consistent; therefore, we
  should not be able to prove them false. Smullyan's example requires that we
  add the fact that every natural number has a successor and a definition for
  less-than or it runs into the problem of trying to claim something about an
  object which has no support for even existing.

    * The conjunction of these formulas is underspecified
      """
      all(X1,ex(Y1,lt(X1,Y1)))
      -ex(X2,lt(X2,X2))
      all(X3, all(Y3, all(Z3, (lt(X3,Y3) /\ lt(Y3,Z3)) ==> lt(X3,Z3) )))
      """
  * The conjunction of these formulas is underspecified
      """
      all(X1,ex(Y1,lt(X1,Y1)))
      -ex(X2,lt(X2,X2))
      """
  * Formula "all(X,ex(Y,lt(X,Y)))" is underspecified

  * Formula "-ex(X,lt(X,X))" is underspecified

  * Formula "all(X, all(Y, all(Z, (lt(X,Y) /\ lt(Y,Z)) ==> lt(X,Z) )))" is underspecified

  * Formula "-lt(inf,Y)" is not a theorem

  * Formula "lt(argh,argh)" is not a theorem

  * Formula "lt(a,b) /\ lt(b,c) /\ -lt(a,c)" is not a theorem

#  * The disjunction of these formulas is underspecified
#      """
#      -lt(inf,Y)
#      lt(argh,argh)
#      (lt(a,b) /\ lt(b,c) /\ -lt(a,c) )
#      """

Rule: If new elements of the domain are generated, then the prover may reach its limits

  For instance in the Integral Domain, there is always another integer, so it is possible for an
  attempted proof to go on forever unless limits of search depth, memory usage, or time are set.



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
