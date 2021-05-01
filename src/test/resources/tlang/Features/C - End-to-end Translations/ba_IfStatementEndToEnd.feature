@Ready
@SmokeTest
Feature: The if-statement - end to end test

    This feature specification is for the end to end testing of the features specified in the file
    ab_IfStatement.feature. That file specifies the visible aspects of the if-statement and offers
    more complete explanations of its use. This file shows generated Java code for compilation.

Rule: Value names defined in one branch must be defined in all branches

Example: Trivial assignments are often ignored in generated code

  Notice that in the first branch of this example, trivial assignments are made to new value names.
  They have no effect since they are assignments from a variable to itself. But they are necessary
  because when we prove the means statement we must know that it is true in both conditions. The
  means statement for the method assumes that any unmentioned variables keep the same value, but all
  mentioned variables must have an assignment to a final value under all conditions. In the
  generated code, you can see that the assignment to `b` is ignored by turning it into a comment.
  You will also see that the copy of `'a` that is needed later is made in a very conservative
  location, preventing us from ignoring the assignment to the variable `a`.

  * a valid compile unit is
    """
    class Swapper_2 {

    int a;
    int b;

    void validSwap() {
      if ('a = 'b) {
        a' = 'a;
        b' = 'b; // the compiler often generates a null operation for the assignments
      } else {
        a' = 'b;
        b' = 'a;
      }
    }
    means(a' = 'b && b' = 'a);

    } // end class
    """

  And the Java operational compile unit is
    """
    import tlang.runtime.*; @TType class Swapper_2 {

    int a;
    int b;

    void validSwap() { int $T$a = /*'*/a;
      if ($T$a == /*'*/b) {
        a/*'*/ = $T$a;
        /*$T$* b' = 'b; *$T$*/ // the compiler often generates a null operation for the assignments
      } else {
        a/*'*/ = /*'*/b;
        b/*'*/ = $T$a;
      }
    }
    /*$T$* means(a' = 'b && b' = 'a); *$T$*/

    } // end class
    """

Example: Value names do not need to be defined in the same order in all branches

  Here the temp1 and temp2 values are defined in different orders. Note that all the generateed
  holding values are caused by reusing overwritten values, not by reordering assignment.

  * a valid compile unit is
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
      } else {
        a'temp2 = 'b; // note the different order of assignment to the variables a and b here
        a'temp1 = a'temp2;
        b'temp2 = 'a;
        b'temp1 = b'temp2;
      }
      a' = a'temp2;
      b' = b'temp2;
    }
    means(a' = 'b && b' = 'a);

    } // end class
    """

    And the Java operational compile unit is
    """
    import tlang.runtime.*; @TType class Swapper_3 {

    int a;
    int b;

    void validSwap() { int a$T$temp2; int $T$a = /*'*/a; int a$T$temp1; int b$T$temp2; int b$T$temp1;
      if ($T$a == /*'*/b) {
        a/*'temp1*/ = /*'*/b; a$T$temp1 = a/*'temp1*/;
        a/*'temp2*/ = a$T$temp1; a$T$temp2 = a/*'temp2*/;
        b/*'temp1*/ = $T$a; b$T$temp1 = b/*'temp1*/;
        b/*'temp2*/ = b$T$temp1; b$T$temp2 = b/*'temp2*/;
      } else {
        a/*'temp2*/ = /*'*/b; a$T$temp2 = a/*'temp2*/; // note the different order of assignment to the variables a and b here
        a/*'temp1*/ = a$T$temp2; a$T$temp1 = a/*'temp1*/;
        b/*'temp2*/ = $T$a; b$T$temp2 = b/*'temp2*/;
        b/*'temp1*/ = b$T$temp2; b$T$temp1 = b/*'temp1*/;
      }
      a/*'*/ = a$T$temp2;
      b/*'*/ = b$T$temp2;
    }
    /*$T$* means(a' = 'b && b' = 'a); *$T$*/

    } // end class
    """
