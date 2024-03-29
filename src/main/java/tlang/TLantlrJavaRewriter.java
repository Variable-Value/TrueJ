package tlang;

import java.util.Map;
import org.antlr.v4.runtime.ParserRuleContext;
import org.antlr.v4.runtime.RuleContext;
import org.antlr.v4.runtime.Token;
import org.antlr.v4.runtime.TokenStream;
import org.antlr.v4.runtime.tree.ParseTree;
import org.eclipse.jdt.annotation.NonNull;
import org.eclipse.jdt.annotation.Nullable;
import tlang.Scope.VarInfo;
import tlang.TLantlrParser.*;

import static tlang.TUtil.*;
import static tlang.TLantlrParser.*;

/**
 * Translate TrueJ to Java
 */
public class TLantlrJavaRewriter extends RewriteVisitor {

/**
 * Are we creating a new value name? For instance, in the assignment <code>x'[0] = 'x[0] + 1</code>
 * the <code>x'[0]</code> is an assignable expression and the <code>'x[0] + 1</code> is not.
 * Assignable expressions may need extra generated code to save the original value if that value
 * name is used again later.
 */
boolean inAssignableExpression = false;

/** A string of characters that may not be used in TrueJ programs. They are reserved for use by the
 * compiler and TrueJ system to use for implemention. */
public static final String $T$ = "$T$";

public TLantlrJavaRewriter( TokenStream             tokenStream
                            , Map<RuleContext, Scope> ctxToScope
                            ) {
  super(tokenStream, ctxToScope);
}

static public String treeToJava( ParseTree parseTree
                               , TokenStream tokenStream
                               , Map<RuleContext, Scope> ctxToScope
                               ) {
  TLantlrJavaRewriter visitor = new TLantlrJavaRewriter(tokenStream, ctxToScope);
  visitor.visit(parseTree);
  return visitor.getJava();
}

public String getJava() {
  return rewriter.getText();
}


// ***** Visit the Nodes that need to be rewritten *******

/* TODO: Include an overriden visitUninitializedField() to enforce the rule that both pre- and
 * post-decorated fields can be delared without initialization, but then they must be defined in all
 * constructors.
 */

/**
 * If there is an import statement, insert the new import before it,
 * else if there is a package declaration, insert the new import after it,
 * else if there is only a type declaration, insert the new import before it,
 * else insert the new import before whatever is there (javadoc?)
 * @return a null to indicate that there are no children to visit.
*/
@Override public Void
visitT_compilationUnit(T_compilationUnitContext ctx) {
  visitChildren(ctx);

  final String runtimeText = "import tlang.runtime.*;";

  final T_importDeclarationContext firstImportCtx =  ctx.t_importDeclaration(0);
  if (firstImportCtx != null) {
    rewriter.insertBefore(firstImportCtx.getStart(), runtimeText +" ");
  } else {

    final T_packageDeclarationContext packageCtx = ctx.t_packageDeclaration();
    if (packageCtx != null) {
      rewriter.insertAfter(packageCtx.getStop(), " "+  runtimeText);
    } else {
      final T_typeDeclarationContext firstTypeDef = ctx.t_typeDeclaration(0);
      if (firstTypeDef != null) {
        rewriter.insertBefore(0, runtimeText +" ");
          // 0 is first token in token stream so inserted before javadoc or
          // other comments
      }
    }
  }
  return VOIDNULL;
}

@Override
protected Void typeVisit(ParserRuleContext ctx) {
  Void result =  super.typeVisit(ctx);
  rewriter.insertBefore(ctx.getStart(), "@TType ");
  return result;
}

/** Reusing valueNames after they have been overwritten requires slightly different treatment for
 * local variables vs. parameters and fields. In both cases we create a temporary variable to hold
 * the overwritten value for its later use and then assign the temporary variable its value as
 * soon as the value is known, that is, when that value is assigned to the valueName that will be
 * overwritten. But we must be careful to ensure that we give the temporary variable the same scope
 * that its value name has, namely the scope of the value name's variable.
 * <p>
 * For valueNames of local variables this means that, in code located elsewhere, we declare a
 * temporary variable at the point where the valueName's variable is declared.
 * <p>
 * However, because a parameter or field is declared and defined with an intial value before the
 * executable begins, We declare its temporary variables at
 * the beginning of the executable, and if the incoming initial valueName is one of the value names
 * being reused after
 * being overwritten, we also assign that value to the initial valueName's temporary variable.
 * <p>
 * A field <code>salary</code> field with type <code>Dollar</code> might have a temporary variable
 * initialized as
 * <pre><code>
 * Dollar $T$salary = /*'*&#47;salary;
 * </code></pre>

 */
@Override
protected void executableVisit(ParserRuleContext ctx, ParserRuleContext bodyCtx) {
  withChildScopeForCtx(ctx, () -> {
    if (bodyCtx != null) {
      Token openBraceForBlock = bodyCtx.getStart();
      StringBuilder tempInitializations = new StringBuilder();
      Scope background = currentScope.parent;
      for (Map.Entry<String, VarInfo> varEntry : background.varToInfoMap.entrySet()) {
        String varName = varEntry.getKey();
        VarInfo varInfo = varEntry.getValue();
        String initValue = decoratorString+ varName;
        for (String reusedName : varInfo.reusedValueNames) {
          if (reusedName.equals(initValue)) {
            tempInitializations.append(" ")       .append(varInfo.getType())
                               .append(" "+ $T$)  .append(varName)
                               .append(" = /*'*/").append(varName)
                               .append(";");
          } else {
            tempInitializations.append(" ")       .append(varInfo.getType())
                               .append(" ")       .append(reusedName.replace(decoratorString, $T$))
                               .append(";");
          }
        }
      }
      rewriter.insertAfter(openBraceForBlock, tempInitializations);
    }

    visitChildren(ctx);
  });
}

/**
 * Translate an assignment statement to Java. We reverse the sequential order of visiting the
 * children in order to reflect the idea that the
 * change to the LHS variable happens after the RHS expression is evaluated.
 * This allows assignments like a' = 'a + 1, where the LHS varable occurs on both sides. Note
 * that visiting the RHS expression translates the expression in place without affecting the as-yet
 * untranslated LHS value-name.
 * <p>
 * {@inheritDoc}
 * @return a null to indicate that there are no children to visit.
 */
@Override public Void //@formatter:off
visitAssignStmt(AssignStmtContext ctx) {
  // Collect pre-visit (unmodified) info
  // running example - let text for assignments statement be         a' = 'a + 1;
  Token assignedValueToken = ctx.t_assignment().t_assignable().getStart();          // token for a'
  String assignedValueName = assignedValueToken.getText();           // a'
  String varName = variableName(assignedValueName);                  // a

  VarInfo varInfo = currentScope.getExistingVarInfo(varName);        // a
  if (  sameVariable(varName, ctx.t_assignment().t_expression())
     && ! (  isReusedAfterOverwrite(ctx.t_assignment().t_expression().getText(), varInfo)
//          || isReusedAfterOverwrite(assignedValueName, varInfo)
          )
     ) {
    commentTheCode(ctx);                  // whole command becomes   /*$T$* a' = 'a + 1; *$T$*/
  } else {
    visit(ctx.t_assignment().t_expression());                                       // becomes /*'*/a + 1
    visit(ctx.t_assignment().t_assignable());                                       // becomes a/*'*/
      // (equal sign and ; are unchanged) so whole command becomes   a/*'*/ = /*'*/a + 1;
  }
  if (isReusedAfterOverwrite(assignedValueName, varInfo)) {          // a' is reused later in code
    rewriter.insertAfter(ctx.getStop(), saveOriginalValue(assignedValueName, varInfo));
    // saves the value for later reuse by inserting "a$T$ = a/*'*/;" after the assignment
    // TODO: An "int a$T$;" should be declared at the declaration of a local variable "a" so it will
    //       have the scope of "a". We have already taken care of fields, so it will only be needed
    //       after local variable declarations.
  }
  return VOIDNULL;
} // @formatter:on

private boolean sameVariable(String varName, T_expressionContext t_expression) {
  if (t_expression.getStart() == t_expression.getStop())
    return variableName(t_expression.getText()).equals(varName);
  else
    return false;
}


private boolean isReusedAfterOverwrite(String assignedValueName, VarInfo varInfo) {
  return varInfo != null && varInfo.reusedValueNames.contains(assignedValueName);
}

private String saveOriginalValue(String assignedValueName, VarInfo varInfo) {
  return " "+ newID(assignedValueName) +" = "+ dedecorate(assignedValueName) +";";
}

@Override
public Void visitConjRelationExpr(ConjRelationExprContext ctx) {
  visitChildren(ctx);

  if (ctx.op.getText().equals("="))
    rewriter.replace(ctx.op, "==");

  return VOIDNULL;
}

/**
 * {@inheritDoc}
 * @return a null to indicate that there are no children to visit.
 */
// TODO: will also need to set inAssignableExpression = true
//       in visitT_initializedVariableDeclaratorId() once we start testing local variable
//       declarations
@Override public Void
visitT_assignable(T_assignableContext ctx) {
  final boolean holdInAssignableState = inAssignableExpression;

  inAssignableExpression = true;
  visitChildren(ctx);

  inAssignableExpression = holdInAssignableState;
  return VOIDNULL;
}

/**
 * An undecorated identifier is the same as its Java form, so do nothing.
 * We only override the visit to this node here in order to put all the calls to visit
 * varieties of value-name decoration into the same class and near one another.
 * <p>{@inheritDoc}
 * @param undecoratedCtx  the parse tree, that is the single node for the undecorated value name
 *                        which contains the value-name token but has no children.
 * @return a null to indicate that there are no children to visit.
 */
@Override public Void
visitT_UndecoratedIdentifier(T_UndecoratedIdentifierContext undecoratedCtx) {
  return VOIDNULL;
}

/**
 * Translate a pre-decorated value name to its Java form in place. If the value needs to be saved
 * because the name is referenced after being overwritten, then the characters <code>$T$</code> are
 * substituted for the decorator, but otherwise the decorator is made into a comment. For example,
 * <code>'xyx</code> is transformed to <code>$T$xyz</code> or <code>/*'*&sol;xyz</code>.
 * <p>{@inheritDoc}
 * @param preDecoratedCtx the parse tree, that is the single node for the pre-decorated value name
 *                        which contains the value-name token but has no children.
 * @return a null to indicate that there are no children to visit.
 */
@Override public Void visitT_PreValueName(T_PreValueNameContext preDecoratedCtx) {
  final String id = rewriter.source(preDecoratedCtx);
  final String variableName = id.substring(1);
  final String javaVarName = ( ! inAssignableExpression && isReusedValue(id))
                             ? $T$ + variableName
                             : "/*'*/"+ variableName
                             ;
  rewriter.replace(preDecoratedCtx.getStart(), preDecoratedCtx.getStop(), javaVarName);
  return VOIDNULL;
}

/**
 * Translate a mid-decorated value name to its Java form in place. If the value needs to be saved
 * because the name is referenced after being overwritten, then the characters <code>$T$</code> are
 * substituted for the decorator, but otherwise the decorator and following value-identifier text
 * made into a comment. For example, <code>abc'xyx</code> is transformed to <code>abc$T$xyz</code>
 * or <code>abc/*'xyz*&sol;</code>.
 * <p>{@inheritDoc}
 * @param midNameContext the parse tree, the single node for the mid-decorated value name
 *                       which contains the value-name token but has no children.
 * @return a null to indicate that there are no children to visit.
 */
@Override public Void visitT_MidValueName(T_MidValueNameContext midNameContext) {
  final String valueName = rewriter.source(midNameContext);            // example: id'xxx
  final int decoratorPosition = decoratorPosition(valueName);               // 2
  final String variableName = valueName.substring(0, decoratorPosition);    // id
  final String decorationText = valueName.substring(decoratorPosition+1);   //    xxx

  final String javaVarName;
  if ( ! inAssignableExpression && isReusedValue(valueName))
    javaVarName = variableName + $T$ + decorationText;                      // id$T$xxx
  else                                                                      //  or
    javaVarName = variableName +"/*"+ decoratorString+decorationText +"*/"; // id/*'xxx*/
  rewriter.replace(midNameContext.getStart(), midNameContext.getStop(), javaVarName);
  return VOIDNULL;
}

/**
 * Translate a post-decorated value name to its Java form, in place, with the decorator made into a
 * comment. For example, <code>xyz'</code> is transformed to <code>xyz/*'*&sol;</code>.
 * <p>{@inheritDoc}
 * @param valueNameCtx the parse tree, the single node for the post-decorated value name
 *                     which contains the value-name token but has no children.
 * @return a null to indicate that there are no children to visit.
 */
@Override public Void visitT_PostValueName(T_PostValueNameContext valueNameCtx) {
  final String id = rewriter.source(valueNameCtx);
  final String variableName = id.substring(0, id.length()-1);
  rewriter.replace(valueNameCtx.getStart(), valueNameCtx.getStop(), variableName +"/*'*/");
  return VOIDNULL;
}

/**
 * The id is transformed from T form to Java form. If the value-name is referenced after its value
 * has been overwritten by an assignment to its variable, then a special name is used for the new
 * variable that keeps the copy of the overwritten value.
 *
 * <ul><li> <code>'name  -> /*'*&sol;name,</code> or <code>$T$name</code> if name is reused</li>
 *     <li> <code>nam'e  -> nam/*'*&sol;e,</code> or <code>nam$T$e</code> if name is reused</li>
 *     <li> <code>name'  -> name/*'*&sol;</code>
 *     <li> <code>name
 *             &NoBreak; -> name</code> (unchanged if no decorator)
 * </ul>
 *
 * @param id a possibly decorated T language identifier
 * @return a valid Java form to use for the <code>id</code>
 */
private String newID(String id) {
  if ( ! inAssignableExpression && isReusedValue(id))
    return id.replace(decoratorString, $T$); // e.g., 'id --> $T$id
  else
    return dedecorate(id, decoratorPosition(id));
}

@Override public Void
visitT_means(T_meansContext ctx) {
  commentTheCode(ctx);
  // do not visitChildren(ctx);
  return VOIDNULL;
}

@Override public Void
visitT_lemma(T_lemmaContext ctx) {
  commentTheCode(ctx);
  // do not visitChildren(ctx);
  return VOIDNULL;
}

@Override public Void visitT_given(TLantlrParser.T_givenContext ctx) {
  commentTheCode(ctx);
  // do not visitChildren(ctx);
  return VOIDNULL;
}

@Override public Void visitT_loopInvariant(TLantlrParser.T_loopInvariantContext ctx) {
  LoopInvariantMgr.transformToJava(ctx, this);
  return VOIDNULL;
}


//@Override public Void visitT_invariant(TLantlrParser.T_invariantContext ctx) {
//  commentTheCode(ctx);
//  // do not visitChildren(ctx);
//  return VOIDNULL;
//}

@Override public Void visitT_variant(TLantlrParser.T_variantContext ctx) {
  commentTheCode(ctx);
  // do not visitChildren(ctx);
  return VOIDNULL;
}


// ******** Utility Functions **********

@SuppressWarnings("null")
private boolean isReusedValue(String id) {
  if (currentScope == null) // Not inside class yet
    return false;

  final VarInfo varinfo = notNull(currentScope).getExistingVarInfo(variableName(id));
  return isReusedAfterOverwrite(id, varinfo);
}

private String dedecorate(String valueName) {
  // assumes decorator position >= 0
  final int primeAt = decoratorPosition(valueName);
  return dedecorate(valueName, primeAt);
}

private String dedecorate(String valueName, final int primeAt) {
  if (primeAt < 0) // undecorated
    return valueName;

  if (primeAt == 0) { // is pre-decorated
    return "/*'*/"+ valueName.substring(1); // e.g., 'id --> /*'*/id
  } else { // mid- or post-decorated
    return valueName.substring(0, primeAt) +"/*"+ valueName.substring(primeAt) +"*/";
  }
}

void commentTheCode(ParserRuleContext ctx) {
  String code = rewriter.originalSource(ctx);
  rewriter.replace(ctx.getStart(), ctx.getStop(), commentTheCode(code));
}

/**
 * Comments out code using reversible T comment markers, even if the code
 * already contains comments. Even comment delimiters in quotes are marked,
 * but that's ok because they become part of a comment and are not operational.
 */
private static String commentTheCode(String code) {
  if (code.contains("/*")) {
    return "/*"+ $T$ +"* "+ code.replace("/*", "(*"+ $T$ +"*").replace("*/", "*"+ $T$ +"*)")
          +" *"+ $T$ +"*/";
  } else {
    return "/*"+ $T$ +"* "+ code +" *"+ $T$ +"*/";
  }
}

/**
 * replaces all sections commented out by T with the uncommented version
 */
@SuppressWarnings("unused")
private static String uncommentTheCode(String code) {
  if (code.contains("/*"+ $T$ +" ")) {
    code = notNull(code.replace("/*"+ $T$ +"* ", ""  ).replace(" *"+ $T$ +"*/", ""  ));
    if (code.contains("(*"+ $T$ +"*")) {
      code = notNull(code.replace("(*"+ $T$ +"*" , "/*").replace("*"+ $T$ +"*)" , "*/"));
    }
  }
  return code;
}

/**
 * Juggle the type of an object from @Nullable to @NonNull for an object that is known to be
 * non-null. The programmer must ensure that the object is guaranteed by other code to be non-null.
 * Instead of using this method, it is much safer to check for <code>null</code> and throw an
 * exception if you made a mistake. But if you are confident, using this is more elegant than a
 * <code>@SuppressWarnings("null")</code> on a whole method. Since this method is private and
 * does not affect runtime state, it compiles away to almost nothing.
 */
@SuppressWarnings("null")
private static <T> @NonNull T notNull(@Nullable T item) {
  return (@NonNull T)item;
}

} // class TLantlrRewriteVisitor
