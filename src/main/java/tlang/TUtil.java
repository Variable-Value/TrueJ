package tlang;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.nio.file.FileVisitResult;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.SimpleFileVisitor;
import java.nio.file.attribute.BasicFileAttributes;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Optional;
import org.antlr.v4.runtime.*;
import org.antlr.v4.runtime.atn.PredictionMode;
import org.antlr.v4.runtime.misc.ParseCancellationException;
import org.antlr.v4.runtime.tree.ParseTree;
import org.eclipse.jdt.annotation.NonNull;
import org.eclipse.jdt.annotation.Nullable;
import tlang.TLantlrParser.*;
import static tlang.TCompiler.*;
import static tlang.TLantlrParser.*;

/**
 * Utility methods used in both the compiler and testing, but somehow they are
 * not in the compiler itself.
 * @author cowan
 */
public class TUtil {

static final HashMap<String,String> EMPTY_HASH_MAP = new HashMap<>(0);
static final HashSet<String> EMPTY_HASH_SET = new HashSet<>(0);
static final char decorator = '\'';
static final String decoratorString = "'";

/**
 * A gimmick for avoiding Eclipse <code>null</code> warnings when using ANTLR visitors. The ANTLR
 * generated superclass <code>TLantlrBaseVisitor&lt;T></code> has the formal type parameter
 * <code>T</code> which Eclipse type checking interprets as <code>@NonNull T</code>. ANTLR uses this
 * <code>T</code> as the return type of on all the visit methods to allow returning, for instance,
 * the type of the expression it has parsed. The convention for not returning anything is to use
 * an actual type parameter of <code>Void</code>. So this subclass extends the base class as
 * <code>TLantlrBaseVisitor&lt;Void></code>, and the actual type parameter becomes
 * <code>@NonNull Void</code> for Eclipse type checking.  Therefore all the overridden visit methods
 * in this subclass must have <code>@NonNull Void</code> as the return type. But on the other hand
 * the value returned for a <code>Void</code> type must be <code>null</code>. So we cast the
 * <code>null</code> to <code>(@NonNull Void)null</code>, and "encapsulate" this nonsense in the
 * constant <code>VOIDNULL</code>.
 */
@SuppressWarnings("null")
static final Void VOIDNULL = (@NonNull Void)null;

@SuppressWarnings("null") // Arrays.asList performs unchecked conversion
final static List<Integer> decoratedTokenTypes
    = Arrays.asList(TLantlrParser.PreValueName,
                    TLantlrParser.PostValueName,
                    TLantlrParser.MidValueName);

/**
 * Read file as a token stream.
 * @return CommonTokenStream built from file input
 */
public static CommonTokenStream
fileToTokens(String fileToParse, CollectingMsgListener msgCollector)
      throws IOException {
  try {
    ANTLRFileStream inputStream = new ANTLRFileStream(fileToParse);
    return charsToTokens(inputStream, msgCollector);
  } catch (FileNotFoundException e) {
    msgCollector.collectError("ERROR: File "+ fileToParse +" was not found. " + e.getMessage());
    throw e;
  } catch (IOException e) {
    msgCollector.collectError("ERROR: "+ fileToParse +" could not be read. " + e.getMessage());
    throw e;
  }
}

public static CommonTokenStream
truejStringToTokens(String name, String tStringToParse, CollectingMsgListener msgCollector) {
  final ANTLRInputStream inputStream = new ANTLRInputStream(tStringToParse);
  inputStream.name = name;
  if (tStringToParse == "") {
    msgCollector.collectError("ERROR: TrueJ Language code is empty for " + name);
  }
  return charsToTokens(inputStream, msgCollector);
}

public static CommonTokenStream
charsToTokens(final ANTLRInputStream inputStream, final CollectingMsgListener msgCollector) {
  final JavaUnicodeInputStream input = new JavaUnicodeInputStream(inputStream);
  // translates Unicode escapes to Unicode characters
  final TLantlrLexer lexer = new TLantlrLexer(input);
  lexer.removeErrorListeners();
  lexer.addErrorListener(msgCollector);
  return new CommonTokenStream(lexer);
}

public static boolean
validFileName(String fileName) {
  return (fileName.endsWith(".t") || fileName.endsWith(".java"));
}

    public static boolean
fileNameErrorReporting( TCompilerCounts counts
                      , CollectingMsgListener msgCollector
                      , String fileName
                      ) {
  if ( ! validFileName(fileName)) {
    msgCollector.collectError(fileName +" must be either a .t or a .java file");
    //TODO: just use the simple file name (after the last "/" or "\")
    counts.incErrorCount();
    return true;
  } else {
    return false;
  }
}


    /**
     * Parse the stream of tokens that is loaded into the T language parser.
     * Attempt SLL parsing. If there are errors or complications,
     * revert to the slower, but more thorough, LL parsing.
     * @param parser Generated parser from Antlr
     * @param msgCollector
     * @param counts A fresh collector for statistics from the parse
     * @return Resulting parse tree
     */
    public static ParseTree
fastParse( TLantlrParser parser  // added parameter
         //, CommonTokenStream tokenStream  // removed parameter
         , CollectingMsgListener msgCollector
         , TCompilerCounts counts
         ) {
  ParseTree tree = null;
  // final TLantlrParser parser = new TLantlrParser(tokenStream);
  final CommonTokenStream tokenStream = (CommonTokenStream)parser.getTokenStream();
  parser.getInterpreter().setPredictionMode(PredictionMode.SLL);
  parser.removeErrorListeners();
  parser.setErrorHandler(new BailErrorStrategy());
  final String sourceName = parser.getSourceName();
  try {
    if (sourceName.endsWith(".java")) {
      counts.incJavaParseCount();
      tree = parser.compilationUnit();
    } else {
      counts.incTCodeCount();
      tree = parser.t_compilationUnit();
    }
  } catch (ParseCancellationException ex) {
    counts.incCatchSLLCount();
    // throw RuntimeException if this is a serious error
    // A RecognitionException just starts Phase II of the parser
    //   to locate and report the synax mistake in the T language program
    if (  ! (ex.getCause() instanceof RecognitionException) ) {
      throw ex;
    }
    else { // revert to the slower LL parsing
      msgCollector.collectMsg( tokenStream.getSourceName()
                             + ": SLL parsing failed; LL parsing was used"
                             );
      tokenStream.seek(0);  // .reset();   to beginning of steam
      parser.getInterpreter().setPredictionMode(PredictionMode.LL);
      parser.addErrorListener(msgCollector); // error listeners removed above
      // parser.addErrorListener(new DiagnosticErrorListener()); // TODO remove from production, leave in special test program
      parser.setErrorHandler(new DefaultErrorStrategy());
      if (sourceName.endsWith(".java")) {
        // counts.incJavaParseCount(); // already counted above
        tree = parser.compilationUnit();
      } else {
        // counts.incTCodeCount(); // already counted above
        tree = parser.t_compilationUnit();
      }
    }
  } // end catch ParseCancellationException
  return tree;
}

    public static boolean
compileSource(String packageName, String typeName, String javaCodeFromT
             , JavaFileHandler javaMgr
             , CollectingMsgListener msgCollector
             ) throws IOException, InterruptedException
{ javaMgr.saveGeneratedJava(javaCodeFromT, packageName, typeName);
  javaMgr.compileJavaFiles(msgCollector);
  /* I would like to use the internal compiler but it doesn't implement all the
   * commandline options. See my issue at Java site.
   * Meanwhile, I have deprecated the CompileToTemp class
   */
  // TODO translate Java errors to correspond to T code
  boolean wasSuccessful = true;
  return wasSuccessful;
}

 final static String variableName(final Token valueNameToken) {
   return variableName(valueNameToken.getText());
 }

final public static String
variableName(String valueName) {
  final int pos = decoratorPosition(valueName);
  if      (pos == -1) { return valueName; }                  // return abc for abc
  else if (pos ==  0) { return valueName.substring(1); }     // return abc for 'abc
  else                { return valueName.substring(0,pos); } // return abc for abc' or abc'de
}


final public static int decoratorPosition(String valueName) {
  return valueName.indexOf(decorator);
}

final public static boolean isDecorated(Token valueToken) {
  return decoratedTokenTypes.contains(valueToken.getType());
}

final public static boolean isDecorated(String valueName) {
  return valueName.contains(decoratorString);
}

final public static boolean isUndecorated(Token valueToken) {
  return valueToken.getType() == UndecoratedIdentifier;
}

final public static boolean isUndecorated(String valueName) {
  return (! isDecorated(valueName)); //TODO: remove this line
}

final public static boolean isMidDecorated(Token valueToken) { // e.g., abc'de
  return valueToken.getType() == MidValueName;
}

final public static boolean isMidDecorated(String valueName) { // e.g., abc'de
  final int pos = decoratorPosition(valueName);
  return ( pos > 0                    // e.g., not abc or 'abc
        && pos < valueName.length()-1 // e.g., not abc'
         );
}

final public static boolean isInitialDecorated(Token valueToken) {
  return valueToken.getType() == PreValueName; // e.g., 'abc
}

final public static boolean isInitialDecorated(String valueName) {
  return valueName.startsWith(decoratorString); // e.g., 'abc
}

final public static boolean isFinalDecorated(Token valueToken) {
  return valueToken.getType() == PostValueName; // e.g., abc'
}

final public static boolean isFinalDecorated(String valueName) {
  return valueName.endsWith(decoratorString) ; // e.g., abc'
}

public static boolean isAFinalValueName(Token valueName) {
  return isUndecorated(valueName) || isFinalDecorated(valueName);
}

public static boolean isAFinalValueName(String valueName) {
  return isUndecorated(valueName) || isFinalDecorated(valueName);
}


private static final List<String> quantifierTypes
      = notNull(List.of("forall", "forsome", "sum", "prod", "setof", "bagof"));

static boolean hasBooleanTerms(T_expressionDetailContext ctx, Scope exprScope) {
  if (ctx instanceof ConditionalAndExprContext || ctx instanceof AndExprContext)
    return true;
  if (ctx instanceof ConditionalOrExprContext || ctx instanceof OrExprContext)
    return true;
  if (ctx instanceof NotExprContext)
    return true;
  if (ctx instanceof ConjRelationExprContext || ctx instanceof ConjunctiveBoolExprContext)
    return true;
  if (ctx instanceof PrimaryExprContext peCtx)
    return isBooleanPrimary(peCtx.t_primary(), exprScope);
  if (ctx instanceof DotExprContext dotCtx)
    return isBooleanDotExpr(notNull(dotCtx), exprScope);
  if (ctx instanceof ConditionalExprContext ceCtx) {  // expr(0) ? expr(1) : expr(2)
    return  hasBooleanTerms(ceCtx.t_expressionDetail(1), exprScope);
      // || hasBooleanTerms(ceCtx.t_expressionDetail(2), currentScope);
  }
  if (ctx instanceof InstanceOfExprContext)
    return true;
  if (ctx instanceof ArrayExprContext aeCtx) {
    if (hasBooleanTerms(aeCtx.t_expressionDetail(0), exprScope))
      return true;
  }
  if (ctx instanceof ExclusiveOrExprContext)
    return true;
  if (quantifierTypes.contains(ctx.start.getText()) ) {
    return true;
  }

  //    if (ctx instanceof DotExplicitGenericExprContext dotExplGenrCtx) { /* TODO: returns boolean? */ }

  //if (ctx instanceof FuncCallExprContext) {
  //// TODO: does this function return a boolean?
  //}

  //    if (ctx instanceof NewExprContext) {
  //      TODO: add this; however, new Boolean(true) is deprecated
  //    }
  //    if (ctx instanceof TypeCastExprContext)  { /* TODO: check for casting boolean to Boolean (deprecated) */

  // OTHERWISE
  return false;
}

private static boolean isBooleanDotExpr(DotExprContext ctx, Scope exprScope) {
  if ("this".equals(ctx.t_expressionDetail().getText())
      && isBooleanIdentifier(ctx.t_identifier(), exprScope))
    return true;
  // TODO: return true if other (non-this) object component identifier is boolean
  // otherwise
  return false;
}

/**
 * Check all possible booleans in the parse rule t_primary in the TLantlr.g4 grammar
 * as of 2019 Jan 16
 */
private static boolean isBooleanPrimary(T_primaryContext ctx, Scope primaryScope) {
  if (! isNull(ctx.t_parExpression()))
    return hasBooleanTerms(ctx.t_parExpression().t_expression().t_expressionDetail(), primaryScope);

  if (! isNull(ctx.t_identifier()))
    return isBooleanIdentifier(ctx.t_identifier(), primaryScope);

  if (! isNull(ctx.t_literal()))
    return true;

  return false;
}

static boolean isBooleanIdentifier(T_identifierContext targetCtx, Scope curScope) {
  String targetVarName = variableName(notNull(targetCtx.getText()));
  String varType = notNull(curScope.getExistingVarInfo(targetVarName)).getType();
  return varType.equals("boolean") || varType.equals("Boolean");
}


public static void printMap(java.util.Map<String, String> map) {
  for (java.util.Map.Entry<String, String> entry : map.entrySet()) {
    System.out.println(entry.getKey() +" --> "+ entry.getValue());
  }
}

boolean isMissing(Optional<?> optional) {
  return !optional.isPresent();
}

/** the string argument is all white space or empty
 * @param stringToCheck
 * @return true if only spaces, newlines, returns, and tabs (or if empty string)
 */
public static boolean isWhiteSpace(String stringToCheck) {
  for (int i = 0; i < stringToCheck.length(); i++) {
    final char ch = stringToCheck.charAt(i);
    if ( ! (ch==' ' || ch=='\n' || ch=='\r'|| ch=='\t'))
      return false;
  }
  return true;
}

/**
 * <strong>Is the object null?</strong>
 * This is a utility method to work around a bug in Eclipse null checking.
 */
static <T> boolean isNull(@Nullable T object) {
  return object == null;
}

/**
 * Juggle the type of an object from @Nullable to @NonNull for an object that is known to be
 * non-null. The programmer must ensure that the object is guaranteed by other code to be non-null.
 * Instead of using this method, it is much safer to check for <code>null</code> and throw an
 * exception if you made a mistake. But if you are confident, using this is more elegant than a
 * <code>@SuppressWarnings("null")</code> on a whole method. Since this method is private and
 * does not affect runtime state, it compiles away to almost nothing.
 * <p>
 * If this method is copied into a class, then, since it is private and doesn't do anything,
 * it compiles away to almost nothing in that class.
 */
@SuppressWarnings({"null", "unused"})
private static <T> @NonNull T notNull(@Nullable T item) {
  return (@NonNull T)item;
}


/**
 * Create a directory if it does not already exist
 * @param dir The desired directory.
 *            Use the empty string "" for the current execution directory
 * @throws IOException
 */
public static void
ensureDirExists(String dir) throws IOException {
  if (dir == "")
    return;

  final File dirAsFile = new File(dir);
  if (dirAsFile.isDirectory())
    return;

  final boolean success = dirAsFile.mkdirs();
  if ( ! success)
    throw new IOException
      ("Could not create directory at location: <"+ dirAsFile.getPath() +">");
}

/** Recursively deletes a directory and everything it contains
 * @param dirPathName Directory to delete as a string
 * @throws IOException
 */
public static void
deleteDirectory(String dirPathName) throws IOException {
  File dirAsFile = new File(dirPathName);
  if ( ! dirAsFile.exists() )
    return;

  Path path = dirAsFile.toPath();
  if (path == null) {
    final String errMsg = "There was a problem with the path name: "+ dirPathName;
    throw new FileNotFoundException(errMsg);
  }
  deleteDirectory(path);
}

/** Recursively deletes a directory and everything it contains
 * @param dirPathName Directory to delete
 * @throws IOException
 */
public static void deleteDirectory(@Nullable Path dirPathName)
      throws IOException {
  Files.walkFileTree(dirPathName, new DeletionVisitor());
}

/**
 * Provides the methods to recursively delete everything in a directory.
 */
    /* nested */ private static class
DeletionVisitor extends SimpleFileVisitor<Path> {

  public DeletionVisitor() {}

      @Override public FileVisitResult
  visitFile(Path file, @Nullable BasicFileAttributes attrs) throws IOException {
    Files.delete(file);
    return FileVisitResult.CONTINUE;
  }

      @Override public FileVisitResult
  postVisitDirectory(Path dir, @Nullable IOException ex) throws IOException {
    if (ex != null)
      throw ex;

    Files.delete(dir);
    return FileVisitResult.CONTINUE;
  }

} // end nested class DeletionVisitor


    /* nested */ public static class
TCompilerCounts {
  private int tCodeCount        = 0;
  private int javaParseCount    = 0;
  private int catchSLLCount     = 0;
  private int errorCount        = 0;
  private int tCompileCount     = 0;
  private int javaPassThruCount = 0;

  public void incTCodeCount()        { tCodeCount       ++; }
  public void incJavaParseCount()    { javaParseCount   ++; }
  public void incJavaPassThruCount() { javaPassThruCount++; }
  public void incTCompileCount()     { tCompileCount    ++; }
  public void incCatchSLLCount()     { catchSLLCount++;  }
  public void incErrorCount()        { errorCount++;     }


  public boolean hasError()          { return errorCount > 0; }
  public boolean noErrors()          { return ! hasError();   }

  @Override
  public String toString() {
    StringBuilder msg = new StringBuilder(200);
    if (tCodeCount > 0) {
      msg.append("Encountered "+ tCodeCount
                +" T language files\n");
    }
    if (javaPassThruCount > 0) {
      msg.append("Passed "+ javaPassThruCount
          +" Java files directly to Java compiler\n");
    }
    if (javaParseCount > 0) {
      msg.append("Parsed "+ javaParseCount +" Java compile units\n");
    }
    if (tCompileCount > 0) {
      msg.append("Compiled "+ tCompileCount +" T language compile units\n");
    }
    if (catchSLLCount > 0) {
      msg.append("Programs that required LL parsing: " + catchSLLCount +"\n");
    }
    if (errorCount > 0) {
      msg.append("Programs with errors: " + errorCount +"\n");
    }
    return notNull(msg.toString());
  }
} // end nested class TCompilerCounts

} // end class TUtil
