package tlang;

import org.eclipse.jdt.annotation.Nullable;

import java.util.Optional;
import static tlang.TUtil.*;

/**
 * Conceptually, this scope holds a copy of fields that may be shadowed by local
 * variables, that is, fields from all ancestor scopes. Thus, it protects
 * enclosing class and interface scopes from changes to their decoration state,
 * in order to reuse the field initial or final states when processing other
 * methods.
 *
 * FUTURE: this scope will also need to hold parameter names as part of the background of the
 *         execution.
 * </p>
 */
public class BackgroundScope extends Scope {

public BackgroundScope(String backgroundLabel, Scope parent) {
  super(backgroundLabel, parent);
}

/* Notes on getVarDeclarationInfo and getVarReferenceInfo
 *
 *   In the Scope class, these two methods have essentially the same definition,
 *   while here, we establish the difference in their overall effect.
 */

 /**
 * Return a null to indicate that no conflicting information exists.
 * If the variable name was declared in scope higher than this background scope,
 * then the name may be redeclared at the lower scope, shadowing the higher
 * definition. Therefore, When declaring a local variable, we only search up to
 * this scope. We don't search in this scope because it contains copies of the
 * variable information that may be shadowed. As a net result, the null return
 * means that the new variable name either is not in a higher scope, or is
 * declared only in a scope that allows the name to be shadowed.
 *
 * @return null to indicate that no conflicting information exists
 */
@Override
public @Nullable VarInfo getConflictingVarDeclarationInfo(String varName) {
  return null;
}

/**
 * We must preserve the information as to whether a field's value may be
 * modified or not for repeated use in all methods, constructors, and
 * initializers. Therefore a method must make a copy of the field information
 * before modifying it, and this background scope contains those copies when the
 * method needs them. When referencing a value name within a method, we do not
 * know if the name is based on a local variable or a class component field. If
 * the name is found in a scope above a background scope, then the value name is
 * based on a field, and we copy the field information to the background scope
 * before changing the field's current value and other info. As a design
 * decision, the copying is done on a lazy basis, when the background scope is
 * searched for a variable, instead of cached when the background scope is
 * created.
 */
@Override
public @Nullable VarInfo getExistingVarInfo(String varName) {
  @Nullable VarInfo varInfo = (varToInfoMap.get(varName));
  final boolean varDefinedInThisScope = ! isNull(varInfo);
  if (varDefinedInThisScope) {
    return notNull(varInfo);
  } else { // background always has a parent
    @Nullable VarInfo originalInfo = notNull(parent).getExistingVarInfo(varName);
    final boolean varUndefined = isNull(originalInfo);
    if (varUndefined) {
      return null;
    } else { // variable definition is in originalInfo
      VarInfo shadowingInfo = new VarInfo(notNull(originalInfo));
      if (shadowingInfo.getCurrentValueName() == "") {
        final String valueName = TUtil.decorator+ varName;
        shadowingInfo.setCurrentValueName(valueName);
        shadowingInfo.defineNewValue(valueName, shadowingInfo.getLineWhereDeclared());
      }
      varToInfoMap.put(varName, shadowingInfo);
      return shadowingInfo;
    }
  }
}

/**
 * We must preserve the information as to whether a field's value may be
 * modified or not for repeated use in all methods, constructors, and
 * initializers. Therefore a method must make a copy of the field information
 * before modifying it, and this background scope contains those copies when the
 * method needs them. When referencing a value name within a method, we do not
 * know if the name is based on a local variable or a class component field. If
 * the name is found in a scope above a background scope, then the value name is
 * based on a field, and we copy the field information to the background scope
 * before changing the field's current value and other info. As a design
 * decision, the copying is done on a lazy basis, when the background scope is
 * searched for a variable, instead of cached when the background scope is
 * created.
 */
@Override
public Optional<VarInfo> getOptionalExistingVarInfo(String varName) {
  VarInfo varInfo = varToInfoMap.get(varName);
  final boolean varDefinedInThisScope = varInfo != null;
  if (varDefinedInThisScope) {
    return Optional.of(varInfo);
  } else { // background always has a parent
    Optional<VarInfo> originalInfo = parent.getOptionalExistingVarInfo(varName);
    if ((originalInfo.isPresent())) {
      VarInfo shadowingInfo = new VarInfo(originalInfo.get());
      String shadowCurrentValueName = shadowingInfo.getCurrentValueName();
      if (shadowCurrentValueName == null || shadowCurrentValueName == "") {
        final String valueName = TUtil.decorator+ varName;
        shadowingInfo.setCurrentValueName(valueName);
        shadowingInfo.defineNewValue(valueName, shadowingInfo.getLineWhereDeclared());
      }
      varToInfoMap.put(varName, shadowingInfo);
      return Optional.of(shadowingInfo);
    } else {
    return Optional.empty();
    }
  }
}


 /**
 * When declaring a local variable, we search up to but not in the background
 * scope. Even if the new local variable name is declared in the background
 * scope, the local variable is allowed to shadow it.
 */
@Override
Scope getDeclarationScope(String varName) {
  return null; // not found, except in background, which can be shadowed
}

/** When redefining the value name for a variable to see if we may redefine its
 * value, if the name is found above a background scope, i.e., the value name is
 * for a field, we copy the field information to the background scope before
 * changing it. This is not an efficiency design decision, but is a requirement: the background
 * scope protects ancestor scopes from changes to the value name as the variable is updated.
 * As a design decision, the copying is done on a lazy basis, when
 * the background scope is searched for a variable, instead of cached when the
 * background scope is created.
 */
@Override
Scope getVariableDeclarationScope(String varName) {
  if (varToInfoMap.containsKey(varName)) {
    return this;
  } else { // background always has a parent
    Scope originalScope = parent.getVariableDeclarationScope(varName);
    if (originalScope == null) {
      return null;
    } else {
      VarInfo originalInfo = originalScope.varToInfoMap.get(varName);
      VarInfo shadowingInfo = new VarInfo(originalInfo);
      varToInfoMap.put(varName, shadowingInfo);
      return this;
    }
  }
}



}
