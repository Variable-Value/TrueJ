package tlang;

import java.util.Map;
import java.util.Objects;
import java.security.InvalidParameterException;
import java.util.HashMap;
import java.util.List;
import java.util.Optional;
import org.eclipse.jdt.annotation.*;

import org.antlr.v4.runtime.*;
import tlang.TLantlrParser.*;

import static tlang.TUtil.*;

/**
 * The engine with the knowledge for processing a while statement.
 *
 */
public class LoopMgr {

  private static Map< T_statementContext, @NonNull LoopMgr> loopMap = new HashMap<>();

    /** Find (or create) and return the while statement manager for the context. */
    private static LoopMgr findLoopMgr(T_statementContext ctx) {
      @Nullable LoopMgr nullableMgr = loopMap.get(ctx);
      return isNull(nullableMgr) ? new LoopMgr(ctx) : nullableMgr;
    }


  public LoopMgr(T_statementContext ctx) {
    loopMap.put(ctx, this);
  }


//  public LoopMgr(DoStmtContext ctx) {
//    this.condition       = ctx.t_parExpression().t_expression();
//    this.variant         = ctx.t_variant();
//    this.invariant       = ctx.t_invariant();
//    this.endingInvariant = ctx.t_endingInvariant();
//
//    loopMap.put(ctx, this);
//  }

//  public LoopMgr(ForStmtContext ctx) {
//    this.condition       = ctx.t_parExpression().t_expression();
//    this.variant         = ctx.t_variant();
//    this.invariant       = ctx.t_invariant();
//    this.endingInvariant = ctx.t_endingInvariant();
//
//  loopMap.put(ctx, this);
//}

  public static void checkContext(WhileStmtContext wh, ContextCheckVisitor contextChecker) {
    LoopMgr mgr = findLoopMgr(wh);
    contextChecker.visitT_booleanExpression(wh.t_condition().t_booleanExpression());

//    if (mgr.variant != null)
//      contextChecker.visitT_variant(mgr.variant);
//    if (mgr.invariant != null)
//      contextChecker.visitT_invariant(mgr.invariant);
//    if (mgr.endingInvariant != null)
//      contextChecker.visitT_endingInvariant(mgr.endingInvariant);
  }

  public static void validateWhile(WhileStmtContext ctx, TLantlrProofVisitor visitor) {
    var mgr = findLoopMgr(ctx);
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

  /**
   * A record of the change from a beginning value name at the start of the while statement's body
   * to the latest value name that has been found so far while working down through the statements
   * in the body. The latest value name should be created or updated with a call to
   * <code>changeValue</code> when the an update to the variable is found, for instance, in an
   * assignment that defines the latest value name.
   */
  class ValueChange {

    /** A map from variable names to the current status of the ValueChange for that variable */
    static Map<String, ValueChange> valueChangeMap = new HashMap<>();

    /** the value name at the beginning of the while statement */
    Token beginningValue;

    /** The latest value name that has been found in the body of the while statement */
    Token endingValue;


    ValueChange(Token currentValue, Token newValue) {
      beginningValue = currentValue;
      endingValue = newValue;
      valueChangeMap.put(variableName(newValue), null /*FIX scope.map.get(var name)*/);
    }

    /**
     * Record the new value for a variable, and if the ValueChange object does not
     * exist for the variable, create one with the current valueName and the new one.
     */
    static void changeValue(Token newValue) {
      String varName = variableName(newValue);
      if (valueChangeMap.containsKey(varName)) {
        var changeInValue = valueChangeMap.get(varName);
        changeInValue.endingValue = newValue;
      } else { // create the ValueChange
//        Token currentValue = currentScope.
      }
    }

  } // end inner class ValueChange


}
