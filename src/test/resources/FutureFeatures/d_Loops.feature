@InProgress
@Ready
Feature: Iteration with the while statement

  Iterations loop through a block of code, executing it repeatedly, until a stopping condition is
  reached. Here we only consider iteration with arithmetic problems. Looping through arrays and
  other more complex loops will be considered later.

  <h3>The theory of loops</h3>

  We will analyze the following example snippet of code in the most general way possible, but most
  actual code allows for simplifications that we will explain later. The example multiplies two
  numbers by repeatedly adding. For readability, we take the option of using the undecorated names
  for final values rather than the post-decorated names, e.g., `i` instead of `i'`:

  <h4>Our working example</h4>

    int m = 4;
    int n = 7;

    'product = 0;
    'i = 0;

    loop ('product --> product, 'i --> i)
      invar: i <= n  &  product = m * i;
      var: n - i > 0;
    while ('i < n) {
      product = 'product + m;
      i = 'i + 1;
    }
    means: ~(i < n) & i <= n & product = m * i;

    means: product = m * n;

  <h4>Our explanation of loops using the example</h4>

  The _body_ is the code that is repeatedly executed: XXX

  > body
          product = 'product + m;
          i = 'i + 1;

  The _condition_ is the test that is executed to decide whether to stop or continue:

    while ('i < n)

  which would stop when `'i >= n`.

  The _value name shift_ is the change that is made by the body from the starting value name of
  modified variables to their ending value names:

    ('product --> product, 'i --> i)

  which uses only initial and final value names in our example, but in general could use
  intermediate value names, such as `product'soFar`. We call the value names that are used at the
  start of an iteration the unshifted form and the value names that are used at the end of an
  iteration the shifted form.

  The _invariant_ is a status statement that is always true immediately before the condition is
  tested in its unshifted form, but is stated in the shifted form of the value names, e.g.,
  `product` instead of `'product`:

      invar: i <= n  &  product = m * i;

  The _variant_ is also stated in the shifted form of the value names, but with a very restricted
  syntax, consisting of an integer expression, a direction that it always changes, and a constant
  stopping point:

      var: n - i > 0;

  meaning that `n - i` goes from greater to smaller until it reaches `0`.

  There are relationships that must be maintained between these parts of the while loop:

  - The body must change the value of the variant expression, `n - i`, in the direction of the
    stopping point, `n - i > 0`, so the stopping point will eventually be reached. This is true in
    our example because

                  i = 'i + 1  // from the body
        ==>      'i < i
        ==>  n - 'i > n - i   // the variant expression changes in the right direction

    We could add the change in the variant expression at the end of the body as a `lemma`:

        lemma: n - 'i > n - i

    and because `'i`, `i`, and `n` are integers, `n - i` will eventually become zero. So we know
    that the stopping point will always be reached.

  - The variant expression, when it has reached its stopping point, must imply the stopping
    condition, so the condition test will eventually force the exit of the loop. For our example,
    using unshifted value names

            ~(n - 'i > 0)
        ==>     ~( n >'i)
        ==>     ~('i < n)

  - The code before the first condition test must establish the invariant (in its unshifted form).

            m = 4;
          & n = 7;
          & 'product = 0;
          & 'i = 0;
        ==> 'i <= n  &  'product = m * i  // unshifted invariant

  - The invariant must be reestablished by the body before the next test of the condition. Our proof
    can use the facts that we know we have before the body is executed: (1) the previous and
    unshifted version of the invariant and (2) the condition that was tested.

            'i <= n  &  'product = m * 'i  // unshifted previous invariant
          & 'i < n                         // condition
          & product = 'product + m         // body
          & i = 'i + 1
        ==> i <= n  &  product = m * i     // new invariant (in shifted form)

    We can see that the first term of the new invariant is true because integer additon by one
    doesn't let you skip over any integers.

             'i < n       // condition
          &   i = 'i + 1  // body
        ==>               // because 'i < n < 'i + 1 = i is impossible then n >= i
              i <= n      // first term of invariant

    And we can see that the second term is true because

            'product = m * 'i            // (1) from previous invariant
          & product = 'product + m       // body
          & i = 'i + 1;                  // body
        ==> 'product + m = m * ('i + 1)  // adding m to both sides of (1)
        ==> product = m * i              // substituting product and i for 'product + m and ('i + 1)

    We could add the invariant in its shifted form as a lemma before the end of the body:

        lemma: i <= n  &  product = m * i;

    Note that the invariant that must be reestablished by the end of the body must be true in terms
    of the new/shifted value names that are defined in the body. At the beginning of the next
    iteration of the loop, those same values will still be there in their variables, but will have
    different names, the old/unshifted value names. So the form of the invariant that will be true
    at the beginning of the next iteration is the invariant with the unshifted variable names. Since
    the condition test is not allowed to modify variables, we could add the unshifted form of the
    invariant as a lemma at the beginning of the body:

        lemma: 'i <= n  &  'product = m * 'i;

    Because both the unshifted and shifted forms of the invariant are useful in understanding the
    code, but we don't want the programmer to be forced to code both, the design decision in TrueJ
    was to require the unshifted form of the invariant.

  - If the loop exits, we can be sure (1) that the condition is false, and (2) that the invariant is
    true, so we take their conjunction to be the meaning of the loop.

        ~(i < n) & i <= n  &  product = m * i

    At the completion of the loop we use the shifted form of the value names, which means the
    condition will have to be used in its shifted form, but the invariant statement can be left as coded, which does help us
    read off the meaning of the loop. The meaning does not have to be stated as we did in the
    example, but it is used by the prover to validate any future status statements that we make. Typically, we code our desired result from the execution
    of the loop as a `lemma` or `means`:

        means: product = m * n

  - Finally, in order to make sure that all changes to secured variables are reflected in the
    meaning of code, any change in the loop's body to a secured variable must be reflected in the
    invariant so that it will be part of the meaning of the loop. We insure this by insisting that
    if the changes to the invariant in the body are known, then the body's change to the secured
    variable is known. Therefore, supposing that product was a secured variable, the following
    condition would be necessary:

            'i <= n  &  'product = m * 'i  // unshifted previous invariant
          & 'i < n                         // condition
          & i = 'i + 1;                    // other command from the body
          & i <= n  &  product = m * i     // new invariant
        ==>
            product = 'product + m         // assignment to a secured variable in the body

Rule: The invariant is true at the start of a every test for entering the loop

  Let's deal with stopping first. A "loop condition" tests whether the desired ending state has been
  reached, but it is just a test and does not guarantee that the end will ever arrive. So we use an
  expression, the "loop variant", that documents how the loop body changes the state so that
  a stopping point will be reached. The programmer must arrange things so that by the time the
  loop variant has reached its stopping point, the loop condition will have reached its exit
  condition. The syntax for a loop variant is such that for some loops it is identical to the loop  condition; in these cases the redundant loop variant does not need to be coded.

  The code following the loop can count on the invariant being true, so it must be true before every
  test to see if the loop continues, or even if it begins.

Example: The invariant is true on the first test, whether the loop is entered or not

  Even when the loop is never executed, we must ensure that the invariant is true.

  Example:


  * a compile unit that parses is
    """
    class NullLoop {

    void nullCountWithLoopingGoto() {
      int n' = 0;
      int 'count = 0;

      condition loopInv(j, m) ( j = sum(int i : upto(0, m) : 1 ) );

      LoopStart: // ('count --> count')
        means loopInv('count, n');
        variant 'count < n'; // 'count + epsilon' <= count'  (where epsilon' > 0)

        if ('count < n')
          goto LoopEnd;

        count' = 'count + 1;
        m' = 'm + 1;
        means 'count + 1 <= count'
            & loopInv(count', n');

        goto LoopStart (count' --> 'count);
        LoopEnd: ;
      }
      means count' = 0;
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
        means count' = 0;
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
        // means product' = m' * 'i + m';

        i' = 'i + 1;
        // means product' = m' * i';
      }
      // means i' = n' & product' = m' * i'; // (3)
      return product';
    }
    means return' = n' * m';

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
#          means (productSoFar'inLoop = multiplicand' * ('i+1));
#
#          i' = 'i+1;
#          means (productSoFar'inLoop = multiplicand' * i');
#        }
#        means (productSoFar' = multiplicand' * multiplier');
#
#        return productSoFar';
#      }
#      means(return' = multiplicand' * multiplier');
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
#        means (productSoFar'inLoop = multiplicand' * ('i+1));
#        i' = 'i+1;
#        means (productSoFar'inLoop = multiplicand' * i');
#      }
#      means (productSoFar' = multiplicand' * multiplier');
#      return productSoFar';
#    }
#    Means(return = multiplicand' * multiplier');
#    """