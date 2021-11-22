package tlang;

import static org.junit.Assert.*;
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.Iterator;
import org.junit.Ignore;
import org.junit.Test;

public class KnowledgeBaseTest {

private static final String and = KnowledgeBase.and;

@Test
public void test_child_KB_empty() throws Exception {
  KnowledgeBase parent = new KnowledgeBase();
  parent.assume("fact 1");
  KnowledgeBase child = new KnowledgeBase(parent);
  assertTrue(child.hasNoFacts());
  String expected = "true" + and + parent.conjoinedFacts();
  String actual   = child .conjoinedFacts();
  if ( expected.equals(actual))
    assertTrue(true);
  else
    assertEquals(expected, actual);
}


@Test
public void test_elaborated_copies_not_equal() throws Exception {
  KnowledgeBase parent = new KnowledgeBase();
  KnowledgeBase expected = new KnowledgeBase(parent);
  expected.assume("fact 1");
  KnowledgeBase actual = expected.copy();
  actual.assume("fact 2");
  assertNotSame(expected, actual);
  assertFalse(expected.equals(actual));
}


@Test
public void test_elaborated_copies_equal() throws Exception {
  KnowledgeBase parent = new KnowledgeBase();
  KnowledgeBase expected = new KnowledgeBase(parent);
  expected.assume("fact 1");
  KnowledgeBase actual = expected.copy();
  assertNotSame(expected, actual);
  assertTrue(expected.equals(actual));
}

@Test
public void test_empty_copies_equal() throws Exception {
  KnowledgeBase expected = new KnowledgeBase();
  KnowledgeBase actual = expected.copy();
  assertNotSame(expected, actual);
  assertTrue(expected.equals(actual));
}

/** SPIKE: Insure that we get array in most-recent-fact first order */
@Ignore
@Test
public void spike_Deque_array() throws Exception {
  Deque<Integer> d = new ArrayDeque<>();
  d.push(2);
  d.push(1);
  d.push(0);
  Integer[] da = d.toArray(new Integer[3]);
  org.junit.Assert.assertEquals(0, da[0].intValue());
  org.junit.Assert.assertEquals(1, da[1].intValue());
  org.junit.Assert.assertEquals(2, da[2].intValue());
}

/** SPIKE: Insure that regular expression will split Unix lines into array */
//@Ignore
@Test
public void spike_eolSplitForUnix() throws Exception {
  String lines = "aaa\nbbb\nccc";
  String[] lineArray = lines.split("\\r?\\n");
  //System.out.println("0: "+ lineArray[0] + " 1: "+ lineArray[1] + " 2: "+ lineArray[2]);
  assertEquals("aaa",lineArray[0]);
  assertEquals("bbb",lineArray[1]);
  assertEquals("ccc",lineArray[2]);
}

/** SPIKE: Insure that regular expression will split Windows lines into array */
//@Ignore
@Test
public void spike_eolSplitForWindows() throws Exception {
  String lines = "aaa\r\nbbb\r\nccc";
  String[] lineArray = lines.split("\\r?\\n");
  //System.out.println("0: "+ lineArray[0] + " 1: "+ lineArray[1] + " 2: "+ lineArray[2]);
  assertEquals("aaa",lineArray[0]);
  assertEquals("bbb",lineArray[1]);
  assertEquals("ccc",lineArray[2]);
}

/** SPIKE: Insure that split does not create extra line */
//@Ignore
@Test
public void spike_eolSplitNoExtraLine() throws Exception {
  String lines = "aaa\r\nbbb\r\nccc\r\n";
  String[] lineArray = lines.split("\\r?\\n");
  //System.out.println("0: "+ lineArray[0] + " 1: "+ lineArray[1] + " 2: "+ lineArray[2]);
  assertEquals(3, lineArray.length);
}


}
