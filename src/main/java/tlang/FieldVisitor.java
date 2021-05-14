package tlang;

import java.util.Map;
import org.antlr.v4.runtime.ParserRuleContext;
import org.antlr.v4.runtime.RuleContext;
import org.antlr.v4.runtime.Token;
import org.eclipse.jdt.annotation.NonNull;
import org.eclipse.jdt.annotation.Nullable;
import tlang.Scope.VarInfo;

import static tlang.TLantlrParser.*;
import static tlang.TUtil.*;

/**
 * Stores field information for use by later vistors.
 */

public class FieldVisitor extends TLantlrBaseVisitor<Void> {

private static final Scope scopeParentLeftNullHere = null;

/**
 * The scope surrounding the current visit. Used by almost all the visitXXX methods. A null value
 * means that we have not yet entered a scope.
 */
@Nullable protected Scope currentScope;

private final String program;

CollectingMsgListener errs;

/** Map from the parse context (ctx) for the code of a scope to the corresponding Scope object. */
protected Map<RuleContext, Scope> scopeMap;

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
private static final Void VOIDNULL = (@NonNull Void)null;


public FieldVisitor(String program, CollectingMsgListener msgListener, Map<RuleContext, Scope> scopeMap) {
  this.program = program;
  this.errs = msgListener;
  this.scopeMap = scopeMap;
}

/**
 * {@inheritDoc}
 */
@Override public Void
visitT_classDeclaration(T_classDeclarationContext classCtx) {
  Scope localParent = currentScope;

  String classStaticScopeName = classCtx.UndecoratedIdentifier().getText();
  Scope classScope= new Scope(classStaticScopeName, scopeParentLeftNullHere);
    /* For classes that are at the top level in their compile unit, a null parent indicates that
     * they are a top level class. For inner classes, the correct enclosing scope will be determined
     * during the ContextCheckVisitor.
     *
     * TODO: Create a test and implement the inner-class parent
     * assignment. */
  currentScope = new Scope("this", classScope); // instance scope
  scopeMap.put(classCtx, currentScope);                                         // push
    // note that static fields will need to be defined with
    // currentScope.parent.declareFieldName(fieldId, idDeclarationCtx.idType)

  visitChildren(classCtx);

  currentScope = localParent;                                                   // pop
  return VOIDNULL;
}

public void otherTypeDeclarationVisit(ParserRuleContext ctx, String scopeName) {
  final Scope localParent = currentScope; // push

  currentScope= new Scope(scopeName, scopeParentLeftNullHere);
    // a scope within a method would not point to the correct parent if we were
    // to fill in parent scope here, so we wait until ContextCheckVisitor
  scopeMap.put(ctx, currentScope);
  visitChildren(ctx);

  currentScope = localParent; // pop
}

/**
 * {@inheritDoc}
 */
@Override
public Void visitT_enumDeclaration(T_enumDeclarationContext ctx) {
  String scopeName = ctx.UndecoratedIdentifier().getText();
  otherTypeDeclarationVisit(ctx, scopeName);
  return VOIDNULL;
}

/**
 * {@inheritDoc}
 */
@Override
public Void visitT_interfaceDeclaration(T_interfaceDeclarationContext ctx) {
  String scopeName = ctx.UndecoratedIdentifier().getText();
  otherTypeDeclarationVisit(ctx, scopeName);
  return VOIDNULL;
}

@Override
public Void visitInitializedField(InitializedFieldContext initializedCtx) {
  Token fieldId = notNull(initializedCtx.getStart());
  var newFieldInfo = currentScope.declareInitializedFieldName(fieldId, initializedCtx.idType);
  if ( newFieldInfo.isEmpty() ) {
    issueErrorForPreviouslyDeclared(fieldId);
  } else {
//  if (declarationHasFinalModifier) {
//    <check for either undecorated or final decorated>
//    currentScope.makeValueAvailable(varOrValueName);
//  }
//  else {

    currentScope.makeValueAvailable(fieldId.getText());
  }
  return VOIDNULL;
}

@Override
public Void visitUninitializedField(UninitializedFieldContext uninitializedCtx) {
  Token fieldId = notNull(uninitializedCtx.getStart());
  var newFieldInfo = currentScope.declareUninitializedVariableFieldName(
                                                                fieldId, uninitializedCtx.idType);
  if ( newFieldInfo.isEmpty() )
    issueErrorForPreviouslyDeclared(fieldId);
  else {
    String varOrValueName = fieldId.getText();
    //TODO: Add check for modifiers (perhaps a bitSet)
//    if (declarationHasFinalModifier) {
//      <check for either undecorated or final decorated>
//      currentScope.makeValueAvailable(varOrValueName);
//    }
//    else
    if (TUtil.isFinalDecorated(varOrValueName))
      currentScope.makeValueAvailable(varOrValueName + decoratorString);
    else if (TUtil.isDecorated(fieldId))
      currentScope.makeValueAvailable(varOrValueName);
    else // undecorated, meaning final value will be provided in initializer block or constructor
      currentScope.makeValueAvailable(decoratorString + varOrValueName);
  }

  return VOIDNULL;
}

private void issueErrorForPreviouslyDeclared(Token fieldId) {
  VarInfo otherField = currentScope.getConflictingVarDeclarationInfo(variableName(fieldId));
  errs.collectError(program, fieldId
                   , "The field " + otherField.varName()
                   + " has already been declared at line " + otherField.getLineWhereDeclared());
}

/**
 * Juggle the status of an object from @Nullable to @NonNull for an object that is known to be
 * non-null. The programmer must ensure that the object is guaranteed by other code to be non-null.
 * It is much safer to check for <code>null</code> and throw an exception if you made a mistake.
 * But if you are confident, using this is more elegant than a
 * <code>@SuppressWarnings("null")</code> on a whole method. And since this method is private and
 * doesn't do anything, it compiles away to almost nothing.
 */
@SuppressWarnings("null")
private static <T> @NonNull T notNull(@Nullable T item) {
  return item;
}


// Skip processing for all other class components
//   (except inner types, which are already handled by the above code)

@Override
public Void visitT_methodDeclaration(T_methodDeclarationContext ctx) {
  // visitChildren(ctx);
  return VOIDNULL;
}

@Override
public Void visitT_genericMethodDeclaration(T_genericMethodDeclarationContext ctx) {
  // visitChildren(ctx);
  return VOIDNULL;
}

@Override
public Void visitT_constructorDeclaration(T_constructorDeclarationContext ctx) {
  // visitChildren(ctx);
  return VOIDNULL;
}

@Override
public Void visitT_genericConstructorDeclaration(T_genericConstructorDeclarationContext ctx) {
  // visitChildren(ctx);
  return VOIDNULL;
}

@Override
public Void visitT_annotationTypeDeclaration(T_annotationTypeDeclarationContext ctx) {
  // visitChildren(ctx);
  return VOIDNULL;
}

} // end class FieldVisitor
