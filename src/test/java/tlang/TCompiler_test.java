/**
 *
 */
package tlang;

import static org.junit.Assert.*;
import java.io.IOException;

import org.junit.Assert;
import org.junit.Ignore;
import org.junit.Test;

public class TCompiler_test {

// TODO: additional tests needed
  // If final decoration is required from either field or local variable decoration,
  //   then disallow undecorated local variable & vice versa
  // Check that expected number of messages are issued
  // CHeck TODOs

@Test
public void decorationDisagreesWithUndecoratedUninitialized_errorTest() throws Exception {
  compileForError(
      """
      class TestClass {
        int a;
        int n' = 5;           // ERROR LINE
        int m';               // ERROR LINE
        int b;
        int c = 2;
      } // end class
      """ ,

      """
      Valuename n' must be undecorated to agree with the previous use of undecorated final values
      Valuename m' must be undecorated to agree with the previous use of undecorated final values
      """);
}

@Test
public void decorationDisagreesWithDecoratedInitialized_errorTest() throws Exception {
  compileForError(
      """
      class TestClass {
        int n' = 5;
        int a, b = 3;           // ERROR LINE
        int m' = 2;
        int c';
      } // end class
      """ ,

      """
      Valuename a must be decorated to agree with the previous use of decorated final values
      Valuename b must be decorated to agree with the previous use of decorated final values
      """ );

}

@Test
public void UseDisagreesWithUndecoratedDeclaration_errorTest() throws Exception {
  compileForError(
    """
    class TestClass {
      int n = 5;                // L2

      void testMethod() {
        int startingA = n';   // ERROR n'
        int x' = n;           // ERROR x'
        int a  = n;
        int b  = startingA;
      }

    } // end class
    """ ,

    """
    A different final decoration, n, was defined at line 2
    Valuename x' must be undecorated to agree with the previous use of undecorated final values
    """);
}

@Test
public void useDisagreesWithDecoratedLocalDeclaration_errorTest() throws Exception {
  compileForError(
    """
    class TestClass {         // L1
      int 'a, 'b;             // L2
                              // L3
      void testMethod() {     // L4
        int startingA' = 'a;  // L5
        b' = startingA';      // L6 OK
        a  = startingA';      // L7 ERROR
        int c' = startingA;   // L8 ERROR
      }

    } // end class
    """ ,

    """
    Valuename a must be decorated to agree with the previous use of decorated final values
    A different final decoration, startingA', was defined at line 5
    """);
}

@Test
public void decoratedFinalLocalVariableWhenDecorationIsForbidden_errorTest() throws Exception {
  compileForError(
    """
    class TestClass {         // L1
      int 'a, 'b;             // L2
                              // L3
      void testMethod() {     // L4
        int startingA = 'a;   // L5
        b  = startingA;       // L6 OK
        a' = startingA;       // L7 ERROR
        int c = startingA';   // L8 ERROR
      }

    } // end class
    """ ,

    """
    Valuename a' must be undecorated to agree with the previous use of undecorated final values
    A different final decoration, startingA, was defined at line 5
    """);
}

@Test
public void undecoratedFinalVariableUsedWithDecoration_errorTest() throws Exception {
  String methodBody = "      int startingA = 'a;"       // L5
                    + "\n      b' = startingA;"         // L6
                    + "\n      a  = startingA';"        // L7
                    ;
  var truejCompiler = compileBody(methodBody);
  msgMustContain(truejCompiler,
      "A different final decoration, startingA, was defined at line 5");
}

@Test
public void InitializeFinalVariableWithoutDecoration_test() throws Exception {
  String methodBody = "      int startingA = 'a;";
  var truejCompiler = compileBody(methodBody);
  compileMustSucceed(truejCompiler);
}

@Test
public void InitializeFinalFieldWithoutDecoration_test() throws Exception {
  String unitMarker = "-unit";
  String compileUnit =   "  class TestClass {"
              + "\n"+    "  int 'a = 1, 'b = 2;"
              + "\n"+    "  int n = 'a + 'b;"
              + "\n"+""
              + "\n"+""
              + "\n"+    "    void testMethod() {"
              + "\n"+    "      int testN = n+1;"
              + "\n"+    "    }"
              + "\n"+""
              + "\n"+    "  } // end class"
              ;
  String[] args = new String[]{unitMarker, compileUnit};
  TCompiler truejCompiler = TCompiler.runTrueJCompiler(args);
  compileMustSucceed(truejCompiler);
}

private TCompiler compileBody(String methodBody) throws IOException, InterruptedException {
  String unitMarker = "-unit";
  String compileUnit =
    """
    class TestClass {             // L1
    int 'a, 'b;                     // L2
                                  // L3
      void testMethod() {         // L4
    """
    + methodBody +                // L5
    """
      }

    } // end class
    """ ;
  String[] args = {unitMarker, compileUnit};
  TCompiler truejCompiler = compileFresh(args);
  return truejCompiler;
}

private void compileForError(String compileUnit, String msg) throws Exception {
  String unitArg = "-unit";
  String[] args = {unitArg, compileUnit};
  TCompiler truejCompiler = compileFresh(args);
  theErrorMsgsContain(truejCompiler, msg);
}

private void compileForSuccess(String compileUnit) throws Exception {
  String unitMarker = "-unit";
  String[] args = {unitMarker, compileUnit};
  TCompiler truejCompiler = compileFresh(args);
  compileMustSucceed(truejCompiler);
}

private TCompiler compileFresh(String[] args) throws IOException, InterruptedException {
  TCompiler truejCompiler = TCompiler.runTrueJCompiler(args);
  return truejCompiler;
}

public void theErrorMsgsContain(TCompiler truejCompiler, String uniquePartOfErrMsgs) {
  var expectedList = uniquePartOfErrMsgs.split("\\n"); // split on line ending
  var msgs = truejCompiler.msgCollector();
  var errLines = msgs.errLines();
  int numberExpected = expectedList.length;
  int numberActual = errLines.size();
  if (numberExpected != numberActual)
    assertTrue("Different number of messages in expected (" + numberExpected +") "
                + "and actual ("+ numberActual +")."
                + "\nExpected \n"+ uniquePartOfErrMsgs
                + "\nActual \n "+ msgs.toString()
                , false);
  for (int i = 0; i < numberExpected; i++) {
    if ( ! errLines.get(i).contains(expectedList[i]) )
      assertTrue("An expected message was not contained in the corresponding actual message."
                   + "\nExpected: "+ expectedList[i]
                   + "\nActual  : "+ errLines.get(i)
                   + "\n\nThe " + numberExpected +" Expected messages \n"+ uniquePartOfErrMsgs
                   + "\n\nThe " + numberActual +" actual messages from "+ msgs.toString()
                  , false);
  }
}

private void msgMustContain(TCompiler truejCompiler, String msgSegment) {
  System.out.println("From msgMustContain\n"+ errorMsgs(truejCompiler));
  if (truejCompiler.msgCollector().hasMsgContaining(msgSegment))
    return; // assertTrue(true);
  else
    assertEquals(msgSegment, errorMsgs(truejCompiler));
}

private void compileMustSucceed(TCompiler truejCompiler) {
//  System.out.println("From compileMustSucceed\n"+ errorMsgs(truejCompiler));
  assertTrue(errorMsgs(truejCompiler)
              , truejCompiler.counts().noErrors());
}

/**
 * We print error messsages from both the regular and the Java compiler messages collector.
 * However both collectors will issue a "no messages" if they are empty, so we fiddle around to
 * prevent two "No messages" and to only issue a single one when both collectors are empty.
 */

private String errorMsgs(TCompiler truejCompiler) {
  String msgs = "\nERRORMSGS";
  if (truejCompiler.msgCollector().isEmpty())
    msgs += "\n"+ truejCompiler.javaMessages().toString();
  else if (truejCompiler.javaMessages().isEmpty())
    msgs += "\n"+ truejCompiler.msgCollector().toString();
  else
    msgs += "\n"+ truejCompiler.msgCollector().toString()
           +"\n"+ truejCompiler.javaMessages().toString();
  return "TrueJ Compiler Messages Issued: "+ msgs;
}

}
