package tlang;

import java.util.Map;
import java.util.Optional;
import org.antlr.v4.runtime.ParserRuleContext;
import org.antlr.v4.runtime.Token;
import org.eclipse.jdt.annotation.NonNull;
import org.eclipse.jdt.annotation.Nullable;
import static tlang.TUtil.VOIDNULL;
import static tlang.TUtil.isNull;
import java.util.HashMap;
import tlang.TLantlrParser.T_blockContext;
// import tlang.TLantlrParser.QuantifierExprContext;
import tlang.TLantlrParser.T_expressionDetailContext;
import tlang.TLantlrParser.T_loopInvariantContext;
import tlang.TLantlrParser.T_quantificationContext;
import tlang.TLantlrParser.WhileStmtContext;

import static tlang.TLantlrParser.*;

/**
 * The engine with the knowledge for processing a while statement.
 *
 */
class QuantifierMgr {

  enum QuantifierType {Forall, Forsome, Sum, Prod, SetOf, BagOf}

  /** The quantifier type of this object. The starting value will be overwritten when this object is
   * created.
   */
  QuantifierType quantifierType = QuantifierType.Forall;

  private static Map<T_expressionDetailContext, @NonNull QuantifierMgr> quantifierMap = new HashMap<>();

      /** Find and return the while statement manager for the context, or create a new one. */
      private static QuantifierMgr findQuantifier(T_expressionDetailContext ctx) {
        @Nullable
        QuantifierMgr nullableMgr = quantifierMap.get(ctx);
        return isNull(nullableMgr) ? new QuantifierMgr(ctx) : nullableMgr;
      }


  /** The context that the parser created for this quantifier */
  private final T_expressionDetailContext ctx;

  public QuantifierMgr(T_expressionDetailContext ctx) {
    this.ctx = ctx;
    quantifierMap.put(ctx, this);
  }


  static void checkContext(T_expressionDetailContext ctx, ContextCheckVisitor checker) {
    QuantifierMgr mgr = findQuantifier(ctx);
    mgr.quantifierType = mgr.quantificationTypeOf(checker);

    Scope quantScope = mgr.newQuantifierScope(checker);

    checker.visitChildrenInScope(ctx, quantScope);
  }


  private Scope newQuantifierScope(ContextCheckVisitor checker) {
    final Token quant = getStart(ctx);
    String blockLabel = quantifierType + quantifierLineAndChar(quant);
    Scope quantifierScope = new Scope(blockLabel, checker.currentScope);
    checker.scopeMap.put(ctx, quantifierScope);
    return quantifierScope;
  }


  private static String quantifierLineAndChar(final Token quant) {
    return "_L"+ quant.getLine() +"C"+ quant.getCharPositionInLine();
  }

  private QuantifierType quantificationTypeOf(ContextCheckVisitor checker) {
    String quantifier = ctx.getStart().getText();
    return switch (quantifier) {
      case "forall"  -> QuantifierType.Forall;
      case "forsome" -> QuantifierType.Forsome;
      case "sum"     -> QuantifierType.Sum;
      case "prod"    -> QuantifierType.Prod;
      case "setof"   -> QuantifierType.SetOf;
      case "bagof"   -> QuantifierType.BagOf;
      default ->    { String msg = "Expected a quantifier type but found "+ quantifier;
                      checker.errs.collectError(ContextCheckVisitor.contextCheck, getStart(ctx), msg);
                      yield QuantifierType.BagOf; // To reduce following message noise
                    }

    };
  }


  static void validate(T_expressionDetailContext ctx, TLantlrProofVisitor validator) {
    // TODO: lookup instance, and create if not found
    var quantifierStatement = findQuantifier(ctx);
    // quantifierStatement.validate(visitor);
  }


  static void transformToJava(T_expressionDetailContext ctx, TLantlrJavaRewriter transformer) {
    transformer.commentTheCode(ctx);
    //do not visitChildren(ctx);
  }

//  private void ensureQuantifierIsInLogic(T_expressionDetailContext ctx) {
//    if ( ! isInLogic)
//      errs.collectError( contextCheck, getStart(ctx),
//          "A quantified expression may only be used inside logic, not executable code");
//  }
//
//  @Override
//  public Void visitT_quantification(T_quantificationContext ctx) {
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

  @SuppressWarnings("null")
  private static Token getStart(ParserRuleContext ctx) {
    return ctx.getStart();
  }



}

