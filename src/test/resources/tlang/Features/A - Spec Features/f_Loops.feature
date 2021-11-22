@Ready
Feature: Iteration with the while statement

  Iterations loop through a block of code, executing it repeatedly, until a stopping condition is
  reached. Here we only consider iteration with arithmetic problems. Looping through arrays and
  other more complex loops will be considered later.

  <h3>The theory of loops</h3>

  The idea of doing something over and over seems quite simple. However, it turns out that it is
  very easy to make small mistakes with large consequences when we try to automate a repetition that
  is just a little complex. Have we gathered everything we need before we start? Are we clear on the
  details of what we are trying to accomplish? How do we make sure that we don't stop too soon or
  too late, or never! Once we make sure that we haven't made one of these simple mistakes, the loop
  turns out to be quite complex.

  We will attempt to simplify our work by adding some thinking aids to the syntax of the loop:

  - The usual parts of a loop in procedural programming languages
    * the _body_ - the code that we execute over and over
    * the _loop condition_ - an executable test for when to keep going and when to stop
  - New non-executable statements to help us think clearly about loops
    * the _meaning of the loop_ as a whole
    * the _invariant_ - the piece of the meaning of the loop that applies to one iteration
    * the _variant_ - a way of looking at the loop condition that helps us make sure we eventually
      reach the stopping condition

Rule: The components of a loop work together

  Here, we will present a simple example. Then, below, we will use the example to explain how the
  different statements help us understand loops and write them correctly.

# @InProgress
Example: A simple loop to multiply by adding

  The example multiplies two numbers by repeatedly adding.

  For readability, we take the option of using undecorated names for final values rather than the
  more explicit, but more cluttered, post-decorated names; for example,  we use `i` instead of `i'`
  to refer to the final value that the variable `i` will have at the end of the method. The
  advantages and disadvantages of this notation are explained in the feature
  `aa_valueNamesDetails_finalDecoration.feature`. The important thing to remember is that in TrueJ,
  the variable name is never used except as a part of a value name, so if it looks like a variable
  name it is really the name of a value that never changes, the final value that the variable holds
  at the end of a method.

  * a valid compile unit is
  """
  class Counter {

  int m = 4;
  int n = 7;

  int 'product;

  void multiplyByAdding() {
    product'current = 0;

    loop (int 'i = 0) (product <-- product'current, i <-- 'i) {
      invar: i <= n  &  product = m * i;
      var: n - i > 0;
      while (i < n) {
        product = product'current + m;
        i = 'i + 1;
      }
    means: ~(i < n) & i <= n & product = m * i;
    }
    means: product = m * n;
  }

  }
  """

# @InProgress
Example: An explanation of the above code

  Some loops are simpler, but the example that we gave requires a complete explanation of the
  workings of a loop. First we review the parts of a loop that are familiar from other procedural
  languages:

  - The _body_ is the code that is repeatedly executed. in our example that is
    >
          product = product'current + m;
          i = 'i + 1;

    The meaning of the body can be read off directly:
    >
            product = product'current + m
          & i = 'i + 1

  - The _loop condition_ is the test that is executed to decide whether to stop or continue. In our
    example, we are using the `while` clause, which starts another iteration through the code in the
    body as long as the condition is true:
    >
          while (i < n)

    which would stop when `'i >= n`.

  Next we look at the components that we add to the loop to allow us to understand why it
  accomplishes its goal and to allow the compiler to check our understanding. We will start with the
  meaning of the loop and then see how it is constructed from the other parts:

  - The _meaning of the loop_ is the set of facts that we are left with after the loop has
    completed. The loop has this meaning whether we explicitly state it or not, but we have chosen
    to show it in our example, immediately after the close of the loop's body:
    >
          means: ~(i < n) & i <= n & product = m * i;

    but rather than coding this exact meaning of the loop, it is a good practice to code a `means`
    statement that states the goal that we are attempting to achieve with the loop:
    >
          means: product = m * n;

    a much more useful summary statement. Note that this second `means` statement can be derived
    from the exact meaning of the loop without any reference to the code in the loop's body:
    >
              ~(i < n) & i <= n & product = m * i
          ==>                     product = m * n

    Now let's look at the other components to see how they build up to our understanding of the
    meaning of the loop.

  - The _value name shift_ is the change that is made by the body from the starting value name of
    modified variables to their ending value names:
    >
          (product <-- product'current, i <-- 'i)

    We call the value names that are available before the looping begins the "unshifted" form and
    the value names that are available in the code after the looping ends the "shifted" form.
    Clearly, the meaning of the loop is a fact that uses the shifted form of the value names,
    since it is a fact about the values that the variables hold after the loop is completed.

    We also use these same forms within the loop's body, the unshifted form to name the values that
    the variables hold at the iteration's start, and the shifted form to name the values that the
    variables hold at its end. This is a very simple convention for the programmer that is just trying to understand the code in the body; where a programmer could possibly become confused is that the context changes from outside the loop's body to inside it: the names in the body are only to be used to understand the body, and the names outside the body are used to understand the effect of the loop statement after all iterations are complete.

    We write the condition test in terms of the unshifted value names because it is tested before each iteration and also because if it's meaning is used inside the body, it is needed in the unshifted form.

  - The _invariant_ is a status statement that is always true immediately before the condition is
    tested in its unshifted form, but is stated in the shifted form of the value names, e.g.,
    `product` instead of `'product`:
    >
          invar: i <= n  &  product = m * i;

    This particular invariant consists of something that we might call one iteration's slice of the
    goal, `product = m * i`, and another bit of code, `i <= n`, to keep us from making a mistake
    where the loop condition accidently skips over our ending point.

    If we were to attempt to prove that our loop reached our goal by using mathematical induction,
    we might invent our invariant to use in the induction step.

  - It isn't clear that any facts about program values can be assigned to a loop statement that
    never stops, so we insist that we must be able to understand why it eventually stops. To do this
    we use a _variant_ statement that relies on the fact that there are only a finite number of
    integers between any two integers. The variant is a statement using the shifted form of the
    value names, but with a very restricted syntax, consisting of an integer expression, a direction in which it always changes, and a constant stopping value:
    >
          var: n - i > 0;

    meaning that `n - i` goes from greater to smaller until it reaches `0`.

  In order for the loop condition, the body, the invariant, and the variant to result in the meaning of the loop, there are relationships that must be maintained between them:

Rule: The body must change the variant in the direction of the stopping value

    The body must change the value of the variant expression, `n - i`, in the direction of the
    stopping value, `n - i > 0`, so the stopping value will eventually be reached. This is true in
    our example because
    >
                    i = 'i + 1  // from the body
          ==>      'i < i
          ==>  n - 'i > n - i   // the variant expression changes in the right direction

    and because `'i`, `i`, and `n` are integers, `n - i` will eventually reach zero. Because we a adding `1` to `'i`, our example will always stop at exactly zero, but in general the variant allows us to skip over the stopping value.

    If the change in the variant is somehow difficult to see at a glance, we can add the change in the variant expression at the end of the body as a `lemma`:
    >
          lemma: n - 'i > n - i

    but usually we can see the direction of change easily, and the compiler will generate an error
    if it cannot prove that the code causes the variant to change in the right direction.

Example: A variant that changes in the wrong direction

  When an invalid compile unit is
  """
  class Counter {

  int m = 4;
  int n = 7;

  int 'product;

  void multiplyByAdding() {
    product'current = 0; // "product-naught" will be the value name at the beginning of each iteration
    int 'i = 0;

    loop (product'current --> product, 'i --> i)
      invar: i <= n  &  product = m * i;
      var: n - i > 0;
    while ('i < n) {
      product = product'current + m; // "product" will be the value name at the end of each iteration
      i = 'i - 1;
    }
    means: ~(i < n) & i <= n & product = m * i;

    means: product = m * n;
  }

  }
  """

  Then an error message contains
  """
  The code does not support the required change in the invariant, n - 'i > n - i
  """

Rule: The variant statement forces the loop condition to stop

  The variant expression, when it has reached its stopping value, must imply the stopping
  condition, so the condition test will eventually force the exit of the loop. For our example,
  using unshifted value names
  >
            ~(n - 'i > 0)
        ==>     ~( n >'i)
        ==>     ~('i < n)

Rule: The invariant is true when the loop is entered

  The code before the first condition test must establish the invariant (in its unshifted form).
  >
            m = 4;
          & n = 7;
          & 'product = 0;
          & 'i = 0;
        ==> 'i <= n  &  'product = m * i  // unshifted invariant

Rule: The invariant is true at the end of the body

  The invariant must be reestablished by the body before the next test of the condition. Our proof
  can use the facts that we know we have before the body is executed: (1) the previous and
  unshifted version of the invariant and (2) the condition that was tested.
  >
            'i <= n  &  'product = m * 'i  // unshifted previous invariant
          & 'i < n                         // condition
          & product = 'product + m         // body
          & i = 'i + 1
        ==> i <= n  &  product = m * i     // new invariant (in shifted form)

  We can see that the first term of the new invariant is true because integer additon by one
  doesn't let you skip over any integers.
  >
             'i < n       // condition
          &   i = 'i + 1  // body
        ==>               // because 'i < n < 'i + 1 = i is impossible then n >= i
              i <= n      // first term of invariant

Example: A variant change that skips over the stopping value

  We attempt to be more efficient by adding twice in each iteration, but forget to check that we
  have reached the stopping point after the first of the additions. This is why we coded the first part of the invariant, `i <= n`; it prevents us from skipping over the point at which `i = n`.

  When an invalid compile unit is
  """
  class Counter {

  int m = 4;
  int n = 7;

  int 'product;

  void multiplyByAdding() {
    product'current = 0;
    int 'i = 0;

    loop (product'current --> product, 'i --> i)
      invar: i <= n  &  product = m * i;
      var: n - i > 0;
    while ('i < n) {
      product'intermediate = product'current + m;
      product = product'intermediate + m;
      i = 'i + 2;
    }
    means: ~(i < n) & i <= n & product = m * i;

    means: product = m * n;
  }

  }
  """

  Then an error message contains
  """
  The code does not support the proof of the invariant statement: i <= n
  """

Rule: ***** WORKING *****

  We can also see that the second term is true because
  >
            'product = m * 'i            // (1) from previous invariant
          & product = 'product + m       // body
          & i = 'i + 1;                  // body
        ==> 'product + m = m * ('i + 1)  // adding m to both sides of (1)
        ==> product = m * i              // substitute product for 'product + m and i for ('i + 1)

  This means that the shifted form of the invariant is true at the end of the body, so we could
  validly add it there as a lemma:
  >
        lemma: i <= n  &  product = m * i;

  Note that the invariant that must be reestablished by the end of the body must be true in terms
  of the new/shifted value names that are defined in the body. At the beginning of the next
  iteration of the loop, those same values will still be there in their variables, but will have
  the names that are correct for entering the loop, the old/unshifted value names. So the form of
  the invariant that will be true at the beginning of the loop for the next iteration is the
  invariant with the unshifted variable names. Since the condition test is not allowed to modify
  variables, we could add the unshifted form of the invariant as a lemma at the beginning of the
  body:
  >
        lemma: 'i <= n  &  'product = m * 'i;

  Because both the unshifted and shifted forms of the invariant are useful in understanding the
  code, but we don't want the programmer to be forced to code both, the design decision in TrueJ
  was to require the unshifted form of the invariant.

  - If the loop exits, we can be sure (1) that the condition is false, and (2) that the invariant is
    true, so we take their conjunction to be the meaning of the loop.
    >
          ~(i < n) & i <= n  &  product = m * i

    At the completion of the loop we use the shifted form of the value names, which means the
    condition will have to be shifted, but the invariant statement can be left as coded, which does
    help us read off the meaning of the loop. The meaning does not have to be stated as we did in
    the example, but it is used by the prover to validate any future status statements that we make.
    Typically, we code our desired result from the execution of the loop as a `lemma` or `means`:
    >
          means: product = m * n

  - Finally, in order to make sure that all changes in the body to _secured_ variables are shown in
    the meaning of the loop, TrueJ insists that if the invariant is known, then the body's change to
    the secured variable is known. Therefore, supposing that product was a secured variable in our
    example, the following condition would be necessary:
    >
              'i <= n  &  'product = m * 'i  // unshifted previous invariant
            & 'i < n                         // condition
            & i = 'i + 1;                    // other command from the body
            & i <= n  &  product = m * i     // new invariant
          ==>
              product = 'product + m         // assignment to a secured variable in the body

  * end explanation

Rule: The loop variant documents how a stopping value will be reached.

  In each iteration of a loop, the code in the body moves the loop closer to reaching its goal. To
  document what variables the body changes and how the change moves the loop toward the stopping value, we use
  the variant statement. The variant, for example `i'+1 > 0`, is a boolean expression, but with a
  very restricted format. It must start with an integer expression , which will always be changed by
  the body to move either up or down towards a stopping value. The direction is shown next with a
  relation sign, `<` or `<=` for moving up, and `>` or `>=` for moving down. And the variant expression ends
  with an integer constant for a stopping value. When the whole boolean expression of the
  variant becomes false, it has reached its stopping value. So our example variant of `i'+1 > 0`
  would reach its stopping value when `i' = -1` (or `i' < -1`). (Sometimes, it is more convenient to
  use the `>=` instead of `>`, so in our example we could write `i' >= 0' instead of `i'+1 > 0`. But for our example let's pretend that we didn't notice this simplification.)

  The variant is not executable code, so we do not test it to actually stop the execution of the next iteration. And sometimes the variant is indirect and less readable, like `var: i'+1 > 0`, while there is a simple and executable stop/continue test that is available, like
  `while (i' >= 0)`. The compiler checks to make sure that this loop condition stops when our variant reaches its stopping value, or, technically, that when the boolean variant expression is false it implies that the boolean loop condition is also false.

Example: A simple counter

  No one would ever need a counter this simple, but here are the bones of counting up to some number in TrueJ.

  * a valid compile unit is
  """
  class Counter {
    int 'i;

    void countUpTo1000() {

      loop ('i --> i)
        invar: i <= 1000;
        var: 1000 - i > 0;
      while ('i < 1000) {
        i = 'i + 1;
      }
      means: ~(i < 1000) & i <= 1000;
    }
    means: i = 1000;

  }
  """


Rule:

  Let's deal with stopping first. A "loop condition" tests whether the desired ending state has been
  reached, but it is just a test and does not guarantee that the end will ever arrive. So we use an
  expression, the "loop variant", that documents how the loop body changes the state so that
  a stopping value will be reached. The programmer must arrange things so that by the time the
  loop variant has reached its stopping value, the loop condition will have reached its exit
  condition.

  The code following the loop can count on the invariant being true, so it must be true before every
  test to see if the loop continues, or even if it begins.

Example: A missing variant defaults to the loop condition

  The syntax for a loop variant is such that for some loops it is identical to the loop condition;
  in these cases, the redundant loop variant does not need to be coded.

Rule: The invariant is true at the start of a every test for entering the loop

Example: The invariant is true on the first test, whether the loop is entered or not

  Even when the loop is never executed, we must ensure that the invariant is true.

  * a compile unit that parses is
    """
    class NullLoop {

    void nullCountWithLoopingGoto() {
      int n' = 0;
      int 'count = 0;

      condition loopInv(j, m) ( j = sum(int i : upto(0, m) : 1 ) );

      LoopStart: // ('count --> count')
        means: loopInv('count, n');
        variant 'count < n'; // 'count + epsilon' <= count'  (where epsilon' > 0)

        if ('count < n')
          goto LoopEnd;

        count' = 'count + 1;
        m' = 'm + 1;
        means: 'count + 1 <= count'
            & loopInv(count', n');

        goto LoopStart (count' --> 'count);
        LoopEnd: ;
      }
      means: count' = 0;
    }

    }
    """

  * a valid compile unit is
    """
    class NullLoopExample {
      private int n' = 0;

      void nullLoop() {
        int 'count = 0;
        while ('count < n') { // ('count --> count')
          invar 'count = sum(int i : upto(0, n') : 1 );
          variant 'count < n';

          count' = 'count + 1;
        }
        means: count' = 0;
      }
    }
    """


  * a valid compile unit is
    """
    class MultiplyByAdding {

    int product(int m', int n') {

      given n' >= 0;

      int 'product = 1;
      int 'i = 0;
      while ('i != n') {                  // (1)
        variant 'i < n';
        invariant 'product = m' * 'i;     // (2)

        product' = 'product + m';
        // means: product' = m' * 'i + m';

        i' = 'i + 1;
        // means: product' = m' * i';
      }
      // means: i' = n' & product' = m' * i'; // (3)
      return product';
    }
    means: return' = n' * m';

    }
    """



#  # TODO:
#  Given the assumption
#    """
#      forall(number n', m' : m' >= 0 : n' * (m'+1) = n'*m' + n')
#    &
#    """
#
#  * A valid compile unit is
#    """
#    class ProductExample {
#
#      int productByAddition(int multiplicand', int multiplier') {
#        given (multiplier' >= 0);
#
#        int 'productSoFar = 0;
#        int 'i = 0;
#
#        ('productSoFar --> productSoFar')
#        while ('i < multiplier') {
#          invar i' >= multiplier' & 'productSoFar = multiplicand' * 'i;
#          variant multiplier' - i’ > 0;
#
#          productSoFar'inLoop = 'productSoFar + multiplicand';
#          means: productSoFar'inLoop = multiplicand' * ('i+1);
#
#          i' = 'i+1;
#          means: productSoFar'inLoop = multiplicand' * i';
#        }
#        means: productSoFar' = multiplicand' * multiplier';
#
#        return productSoFar';
#      }
#      means: return' = multiplicand' * multiplier';
#
#    }
#    """
#
#  * A valid compile unit is
#    """
#    int product(int multiplicand', int multiplier') {
#      given (multiplier' >= 0);
#      int 'productSoFar = 0;
#      int 'i = 0;
#      while ('i != multiplier')
#        'productSoFar --> productSoFar';
#        invar 'productSoFar = multiplicand' * 'i;
#        variant multiplier' - i’ > 0;
#      {
#        productSoFar'inLoop = 'productSoFar + multiplicand';
#        means: productSoFar'inLoop = multiplicand' * ('i+1);
#        i' = 'i+1;
#        means: productSoFar'inLoop = multiplicand' * i';
#      }
#      means: productSoFar' = multiplicand' * multiplier';
#      return productSoFar';
#    }
#    means: return = multiplicand' * multiplier';
#    """