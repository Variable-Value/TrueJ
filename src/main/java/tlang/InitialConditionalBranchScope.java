package tlang;

import static tlang.TUtil.variableName;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Optional;
import java.util.Set;

import org.eclipse.jdt.annotation.NonNull;
import org.eclipse.jdt.annotation.Nullable;
import tlang.Scope.VarInfo;
import tlang.TLantlrParser.T_assignableContext;

/** <code>InitialConditionalBranchScope</code> is used for the then branch of an <code>if</code>
 * statement and for The first case of a <code>switch</code> statement. The code of the branch is
 * enclosed in an <code>InitialConditionalBranchScope</code> whether a single statement or a block.
 * @see FollowingConditionalBranchScope */
class InitialConditionalBranchScope extends Scope {

/** A map from variables that are assigned values in the initial branch to the value names they had
 * before the execution of the initial branch. */
Map<String, String> varToHeldLatestValue = new HashMap<>();

/** The value names assigned in the initial branch to variables of enclosing scopes. These are saved
 * in order to make sure that all branches assign values to the same value names. Note that this
 * means that if multiple valueNames are assigned to the same variable in one conditional branch,
 * then all the same valueNames must be used in all the branches. If a complicated computation is
 * needed in just one branch, then the others might avoid extra computation by trivially assigning
 * the current value to the unneeded valueNames. */
private HashSet<String> delegatedValueNames = new HashSet<>();

/** The value of the variables at the end of the initial branch. If a following branch ends with a
 * different valueName we change its value here to $T$. Then at the end of the conditional
 * statement, we set that variable's varInfo.currentValueName to $T$. This will force the next
 * refernce to the variable, whatever the valueName, to be seen as a reference to an overwritten
 * valueName, and the code necessary to access the valueName's value will be generated, whether it
 * was the ending currentValueName or not. */
Map<String, String> varToEndingValueName = new HashMap<>();

/**
 * @param scopeLabel
 * @param parent
 */
public InitialConditionalBranchScope(String scopeLabel, Scope parent) {
  super(scopeLabel, parent);
}

/** Restore the current values for all enclosing scopes to set the context for processing any
 * following branch. */
void reestablishEnclosingScopeValues() {
  for (Entry<String,String> maplet : varToHeldLatestValue.entrySet()) {
    final String varName = maplet.getKey();
    final String latestValueForVariable = maplet.getValue();
    Optional<VarInfo> optionalInfo = getOptionalExistingVarInfo(varName);
    if (optionalInfo.isPresent())
      resetVarToBeforeConditionalStatement(varName, latestValueForVariable, optionalInfo.get());
  }
}

private void resetVarToBeforeConditionalStatement(String varName
    , String valueForVar, VarInfo varInfo) {
  varInfo.setCurrentValueName(valueForVar);
  for (String valueName : delegatedValueNames)
    if (varName.equals(variableName(valueName)))
      varInfo.removeLineInfo(valueName);
}

@SuppressWarnings({"unchecked", "null"})
public HashSet<String> getCloneOfDelegatedValueNames() {
  return (HashSet<String>)delegatedValueNames.clone();
}

@Override
public @Nullable VarInfo getConflictingVarDeclarationInfo(String varName) {
  return parent.getConflictingVarDeclarationInfo(varName);
}

@Override
Scope getDeclarationScope(String varName) {
  return parent.getDeclarationScope(varName);
}

@Override
Scope getVariableDeclarationScope(String varName) {
  return parent.getVariableDeclarationScope(varName);
}

void delegateInScope(String valueName, String currentValueName) {
  delegatedValueNames.add(valueName);
  String varName = variableName(valueName);
  if ( ! varToHeldLatestValue.containsKey(varName)) {
    varToHeldLatestValue.put(varName, currentValueName);
  }
}

void setEndingValueNames() {
  Set<String> modififedVariables = varToHeldLatestValue.keySet();
  for (String var : modififedVariables) {
    @NonNull
    VarInfo varInfo = notNull(getExistingVarInfo(var));
    varToEndingValueName.put(var, varInfo.getCurrentValueName());
  }
}

public void captureConflictingEndingValueNames() {
  for (Entry<String,String> maplet : varToEndingValueName.entrySet()) {
    String var = notNull(maplet.getKey());
    String endingValueName = notNull(maplet.getValue());
    VarInfo varInfo = notNull(getExistingVarInfo(var));
    String currentValueName = varInfo.getCurrentValueName();
    if ( ! endingValueName.equals(currentValueName) ) {
      if (endingValueName != TLantlrRewriteVisitor.$T$)
        varInfo.reusedValueNames.add(endingValueName);
      varInfo.reusedValueNames.add(currentValueName);
      varToEndingValueName.put(var, TLantlrRewriteVisitor.$T$);
      varInfo.setCurrentValueName(TLantlrRewriteVisitor.$T$);
    }
  }
}

/** Conditional statement handling of valueNames gets complicated. We create a new valueName anytime
 * we assign a value to a variable, and that valueName is used later in the code to represent the
 * value. If the assignment is in a branch of a conditional statement, we must therefore make the
 * valueName available to statements that follow the conditional, but that implies that all paths
 * through the conditional must assign a value to the valueName. So if we assign a value to a new
 * valueName inside any branch of a conditional statement, then all the branches of that conditional
 * are obligated to assign a value to that same valueName; therefore, we will encounter the new
 * valueName first in the initial branch. The "obligation" for all the following branches of the
 * conditional statement is recorded as a "delegation" in the <code>delegatedValueNames</code> set
 * of the corresponding initial branch.
 * <p>
 * This kind of obligation can be created in the initial branch even when the assignment to a new
 * valueName happens in a nested conditional statement. So when we assign to a new valueName in an
 * initial branch, we need to check <em>enclosing</em> scopes and set the delegation in every
 * enclosing <code>InitialConditionalBranchScope</code> until we run out of enclosing scopes in the
 * executable, or until we find an enclosing {@link FollowingConditionalBranchScope}. We can stop at
 * a following scope because its corresponding initial scope will have already created the
 * delegation/obligation in its enclosing scopes, as we just described.
 * <p>
 * So, often, we will be left sitting at an enclosing following scope, and in that case it turns out
 * there will be more to do. This is because nested conditional statements under following branches
 * can fulfill that branch's obligations. To see this, let's start with the
 * <code>delegatedValueNames</code> set from the initial branch. Each corresponding following branch
 * gets a copy of that set, which it calls <code>obligatedValueNames</code>, and it records meeting
 * its obligations by removing valueNames from its copy of the set. When an assignment is made in
 * the following branch to a valueName, it fulfills the obligation for that valueName; however, this
 * obligation may also be fulfilled by a nested conditional statement in our following branch with
 * the assignment in all of its branches. So, when we are searching upwards from an initial branch
 * assignment, the assignment may be to a valueName fulfilling an obligation of a following branch.
 * Therefore, we remove the valueName from the <code>obligatedValueNames</code> of the following
 * branch where the search stops.
 * @param valueName  the valueName that was assigned a value inside an initial branch of a
 *                    conditional statement
 * @param currentValueName */
void setDeligationObligationForEnclosingScopes(String valueName, String currentValueName) {
  Scope s;
  for (s = this; notAnEnclosingFollowingScope(s); s = notNull(s.getParent()))
    if (s instanceof InitialConditionalBranchScope initialScope)
      initialScope.delegateInScope(valueName, currentValueName);

  if (s instanceof FollowingConditionalBranchScope followingScope)
    followingScope.removeAnyObligationOnValueName(valueName);
}

static boolean notAnEnclosingFollowingScope(Scope s) {
  return ! (s instanceof FollowingConditionalBranchScope) && scopeIsStillInExecutable(s);
}

void setCollectionsToEmpty() {
  varToHeldLatestValue = TUtil.EMPTY_HASH_MAP;
  delegatedValueNames = TUtil.EMPTY_HASH_SET;
}

/**
 * Juggle the status of an object from @Nullable to @NonNull for an object that is known to be
 * non-null. The programmer must ensure that the object is guaranteed by other code to be non-null.
 * It is much safer to check for <code>null</code> and throw an exception if you made a mistake.
 * But if you are confident, using this is more elegant than a
 * <code>@SuppressWarnings("null")</code> on a whole method. Since this method is private and
 * doesn't do anything, it compiles away to almost nothing.
 */
@SuppressWarnings("null")
private static <T> @NonNull T notNull(@Nullable T item) {
  return (@NonNull T)item;
}




}
