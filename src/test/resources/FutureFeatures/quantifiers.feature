Feature: Quantifiers

Example: The sum quantifier

    given n < start;
    'tot = 0;
    'm = start;

    loop ('tot --> tot, 'm --> m)
      invariant m >= n & tot = sumOf(int i: m < i <= start: i);
      variant m - n > 0;
    while ('m > n) {
      tot = 'tot + 'm;
      m = 'm - 1;
    }
    means ~(m > n) & (m>= n & tot = sum(int i : m< i<= start : i))

    means tot = sum(int i: n< i<= start : i);