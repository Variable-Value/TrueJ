package tlang;

import java.util.Map;
import java.util.HashMap;
import org.eclipse.jdt.annotation.*;

import tlang.TLantlrParser.*;

import static tlang.TUtil.*;

/**
 * The engine with the knowledge for processing a loop invariant statement.
 *
 * @implNote All of the visit methods for loop invariants,
 *           <code>visitT_loopInvariant(T_loopInvariantContext ctx)</code>, in the expression tree
 *           visitors should refer to these methods to keep all the knowledge about the invariant
 *           processing in one place.
 */
/* TODO: Do we need to coordinate the checking of value names with the LoopMgr or does the LoopInvariant
 *       simply allow whatever currently available value names?
 */
final class LoopInvariantMgr {

  private static Map< T_loopInvariantContext, LoopInvariantMgr> invariantMap = new HashMap<>();

    /** Find (or create) and return the while statement manager for the context. */
    private static LoopInvariantMgr findLoopInvariantMgr(T_loopInvariantContext ctx) {
      LoopInvariantMgr nullableMgr = invariantMap.get(ctx);
      return isNull(nullableMgr) ? new LoopInvariantMgr(ctx) : nullableMgr;
    }


  LoopInvariantMgr(T_loopInvariantContext ctx) {
    invariantMap.put(ctx, this);
  }


  static void checkContext(T_loopInvariantContext inv, ContextCheckVisitor checker) {
    LoopInvariantMgr mgr = findLoopInvariantMgr(inv);
//    checker.visitT_booleanExpression(v.t_booleanExpression());

    // visit both sides of the relational expression
    // for (ex: v.t_expressionDetail()) {
    //   checker.visit(ex);
    // }
  }

  static void validateLoopInvariant(T_loopInvariantContext ctx, TLantlrProofVisitor validator) {
    var mgr = findLoopInvariantMgr(ctx);
//    LoopInvariantStatement.validate(verifier);
  }

  static void transformToJava(T_loopInvariantContext ctx, TLantlrJavaRewriter transformer) {
    transformer.commentTheCode(ctx);
    //do not visitChildren(ctx);
  }


  /**
   * Juggle the type of an object from @Nullable to @NonNull for an object that is known to be
   * non-null. The programmer must ensure that the object is guaranteed by other code to be non-null.
   * Instead of using this method, it is much safer to check for <code>null</code> and throw an
   * exception if you made a mistake. But if you are confident, using this is more elegant than a
   * <code>@SuppressWarnings("null")</code> on a whole method. Since this method is private and
   * does not affect runtime state, it compiles away to almost nothing.
   */
  @SuppressWarnings({"null", "unused"})
  private static <T> @NonNull T notNull(@Nullable T item) {
    return (@NonNull T)item;
  }


}

