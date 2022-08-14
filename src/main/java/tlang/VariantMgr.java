package tlang;

import java.util.Map;
import java.util.HashMap;
import org.eclipse.jdt.annotation.*;

import tlang.TLantlrParser.*;

import static tlang.TUtil.*;

/**
 * The engine with the knowledge for processing a while statement.
 *
 * @implNote All of the visit methods for variants, visitT_variant(T_variantContext ctx), in the
 *           expression tree visitors should refer to these methods to keep all the knowledge about
 *           variant processing in one place.
 */
/* TODO: Do we need to coordinate the checking of value names with the LoopMgr or should the variant
 *       simply allow whatever currently available value names?
 */

final class VariantMgr {

  private static Map< T_variantContext, @NonNull VariantMgr> VariantMap = new HashMap<>();

    /** Find (or create) and return the while statement manager for the context. */
    private static VariantMgr findVariantMgr(T_variantContext ctx) {
      @Nullable VariantMgr nullableMgr = VariantMap.get(ctx);
      return isNull(nullableMgr) ? new VariantMgr(ctx) : nullableMgr;
    }


  public VariantMgr(T_variantContext ctx) {
    VariantMap.put(ctx, this);
  }


  public static void checkContext(T_variantContext v, ContextCheckVisitor contextChecker) {
    VariantMgr mgr = findVariantMgr(v);
    // ensure <,>,<=, or >=

// save this for use in invariant processing
//    contextChecker.visitT_booleanExpression(v.t_booleanExpression());

    // visit both sides of the relational expression
    // for (ex: v.t_expressionDetail()) {
    //   visit(ex);
    // }
  }

  public static void validateVariant(T_variantContext ctx, TLantlrProofVisitor validator) {
    var mgr = findVariantMgr(ctx);
//    VariantStatement.validate(verifier);
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
