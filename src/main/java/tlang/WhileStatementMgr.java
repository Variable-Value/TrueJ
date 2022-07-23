package tlang;

import java.util.Map;
import java.util.Optional;
import org.eclipse.jdt.annotation.NonNull;
import org.eclipse.jdt.annotation.Nullable;
import static tlang.TUtil.isNull;
import java.util.HashMap;

import tlang.TLantlrParser.WhileStmtContext;

/**
 * The engine with the knowledge for processing a while statement.
 *
 */
public class WhileStatementMgr {

  private static Map< WhileStmtContext, @NonNull WhileStatementMgr> whileMap = new HashMap<>();

      /** Find and return the while statement manager for the context, or create a new one. */
      private static WhileStatementMgr findWhile(WhileStmtContext ctx) {
        @Nullable
        WhileStatementMgr nullableMgr = whileMap.get(ctx);
        return isNull(nullableMgr) ? nullableMgr : new WhileStatementMgr(ctx);
      }


  /** The context that the parser created for this while statement */
  private final WhileStmtContext ctx;


  public WhileStatementMgr(WhileStmtContext ctx) {
    this.ctx = ctx;
    whileMap.put(ctx, this);
  }


  public static void validateWhile(WhileStmtContext ctx, TLantlrProofVisitor visitor) {
    var whileStatement = findWhile(ctx);
//    whileStatement.validate(visitor);
  }


//  private void validate(TLantlrProofVisitor visitor) {
//    XXXXXXX
//  }



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
