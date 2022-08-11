package tlang;

import java.util.Map;
import java.util.Optional;
import org.eclipse.jdt.annotation.NonNull;
import org.eclipse.jdt.annotation.Nullable;
import static tlang.TUtil.isNull;
import java.util.HashMap;
import tlang.TLantlrParser.QuantifierExprContext;
import tlang.TLantlrParser.WhileStmtContext;

/**
 * The engine with the knowledge for processing a while statement.
 *
 */
class QuantifierMgr {

  enum QuantifierType {Sum, Prod, Forall, Forsome, Set, List, Bag}

  private static Map<QuantifierExprContext, @NonNull QuantifierMgr> quantifierMap = new HashMap<>();

      /** Find and return the while statement manager for the context, or create a new one. */
      private static QuantifierMgr findQuantifier(QuantifierExprContext ctx) {
        @Nullable
        QuantifierMgr nullableMgr = quantifierMap.get(ctx);
        return isNull(nullableMgr) ? new QuantifierMgr(ctx) : nullableMgr;
      }


  /** The context that the parser created for this while statement */
  private final QuantifierExprContext ctx;


  public QuantifierMgr(QuantifierExprContext ctx) {
    this.ctx = ctx;
    quantifierMap.put(ctx, this);
  }


  static void checkContextForQuantifier(QuantifierExprContext ctx, ContextCheckVisitor visitor) {
    // TODO: lookup instance, and create if not found
  }

  static void validateQuantifier(QuantifierExprContext ctx, TLantlrProofVisitor visitor) {
    // TODO: lookup instance, and create if not found
    var quantifierStatement = findQuantifier(ctx);
    // quantifierStatement.validate(visitor);
  }


  static void generateJavaForQuantifier(QuantifierExprContext ctx, TLantlrJavaRewriter visitor) {
    // TODO: lookup instance, and create if not found
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

