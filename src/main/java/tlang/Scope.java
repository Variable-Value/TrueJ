package tlang;

import java.util.Map;
import java.util.Optional;
import java.util.HashMap;
import java.util.Set;
import java.util.HashSet;
import org.antlr.v4.runtime.Token;
import org.eclipse.jdt.annotation.NonNull;
import org.eclipse.jdt.annotation.Nullable;

import static tlang.TUtil.*;

/** A range of code where a name can be declared and used. When a name is declared within a scope,
 * then it is only visible within that scope. The possible types of scopes are Class, Instance,
 * Initializer, Constructor, Method, Block, Interface, EnumType, and EnumValue. */
class Scope {

//@formatter:off

/** may be another executable scope or the background scope of the method */
@Nullable Scope    parent;
  public            void       setParent(@Nullable Scope parent) { this.parent = parent; }
  public  @Nullable Scope      getParent()             {return parent;}
  public            boolean    hasParent()             {return (parent != null);}
  public            boolean    isTopLevelScope()       {return ! hasParent();}

final private String label;
  String getLabel() { return label; }
  String getAncestryLabel() {
    return hasParent() ? notNull(parent).getAncestryLabel() +"."+ getLabel()
                       : getLabel();
  }

//@formatter:on

  /**
 * A list of the value names that are available at the current point in the code. At the beginning
 * of an executable, this is a copy of the valuesAvailable where the executable was called, e.g.,
 * all field values and all values in enclosing scopes at that point. In the code following a means
 * statement, the only value names that are available are those that were referenced in the means
 * statement.
 */
private Set<String> valuesAvailable = new HashSet<>();

  void setValuesAvailable(Set<String> newValuesNames) { this.valuesAvailable = newValuesNames; }

  boolean hasAvailable(String valueName) { return valuesAvailable.contains(valueName); }

  void makeValueAvailable(String valueName) { valuesAvailable.add(valueName); }

  /**
   * Make any new value names that were defined in this scope available to an executable parent
   * scope. The parent scope's valuesAvailable then becomes the union of its old contents and the
   * contents of this scopes valuesAvailable. This method is executed at the end of an executable
   * scope.
   * <p>
   */
  public void makeNewValueNamesAvailableToParent() {
    // Note that the BackGroundScope stops the propagation, so this Scope always has a parent.
    notNull(parent).valuesAvailable.addAll(this.valuesAvailable);
  }

// *** end valuesAvailable methods ***


private boolean isInstanceScope = false;

void setAsInstanceScope() {
  isInstanceScope = true;
}
boolean isInstanceScope() {
  return isInstanceScope;
}


private boolean isStaticScope = false;

void setAsStaticScope() {
  isStaticScope = true;
}
boolean isStaticScope() {
  return isStaticScope;
}

/** Map from a variable name to its information, if the variable is declared in this scope */
protected Map<String, @Nullable VarInfo> varToInfoMap = new HashMap<>();

boolean isVariableDefinedInThisScope(String varName) {
  return varToInfoMap.containsKey(varName);
}


/**
 * The line number of the latest means-statement encountered, which eclipses all valueNames that
 * are not referenced in the means-statement. When set to zero, it means that no means-statement has
 * occurred in the code, and all value-names are still available both from the enclosing scope and
 * from preceding local variables.
 */
private int latestMeansStatementLine = 0;
  boolean thereIsAPrecedingMeans() { return (latestMeansStatementLine > 0); }

  int latestMeansStatementLine() { return latestMeansStatementLine; }
  void setLatestMeansStatementLine(int lineNumber) { this.latestMeansStatementLine = lineNumber; }



public Scope(String scopeLabel, Scope parent) {
  this.label = scopeLabel;
  this.parent = parent;
  latestMeansStatementLine = 0;
  if (hasParent()) {
    this.valuesAvailable.addAll(parent.valuesAvailable);
  }
}


/**
 * Track the information for an initialized field.
 * Assumption: the field name does not already exist. If it does, a programmer error is thrown.
 */
public void declareInitializedFieldName
    ( Token   valueNameToken
    , String  valueName       // may have been modified before calling this method
    , String  type
    ) {
  String varName = variableName(valueName);
  if (varToInfoMap.containsKey(varName)) {
    programError("Attempting to declare a field name that already exists");
  } else
    varToInfoMap.put(varName, new VarInfo(this, valueNameToken.getLine(), type, valueName));
}

private static void programError(String message) {
  try {
    throw new Exception("PROGRAMMING ERROR: "+ message);
  } catch (Exception e) {
    e.printStackTrace();
  }
}

//  VarInfo existingVarInfo = varToInfoMap.get(varName);
//  final boolean varIsNew = (existingVarInfo == null);
//  if (varIsNew) {
//    final int declarationLine = valueNameToken.getLine();
//    VarInfo newVarInfo = new VarInfo(this, declarationLine, type, valueName);
//    varToInfoMap.put(varName, newVarInfo);
//  } else {
//    throw new Exception("PROGRAMMING ERROR: Attempting to delare a field name that already exists");
//  }

/** Track the information for an uninitialized field.
 * @return an Optional with the new field information. An empty Optional means that the field
 *         variable name already exists. */
public Optional<VarInfo> declareUninitializedFieldName(Token variableToken, String type) {
  String valueName = variableToken.getText();
  String varName = variableName(valueName);
  VarInfo existingVarInfo = varToInfoMap.get(varName);
  boolean varIsNew = (existingVarInfo == null);
  if (varIsNew) {
    final int declarationLine = variableToken.getLine();
    VarInfo newVarInfo = new VarInfo(this, declarationLine, type, valueName);
    varToInfoMap.put(varName, newVarInfo);
    return notNull(Optional.of(newVarInfo));
  } else {
    return notNull(Optional.empty());
  }
}

public Optional<VarInfo> declareVarName(Token varNameToken, String type) {
  final String varName = notNull(varNameToken.getText());
  return declareNewVariable(varNameToken, type, varName, null);
}

// TODO: Calling routine must look up VarInfo again. Save the VarInfo or issue an exception here
/** Note that either a new VarInfo or a null value is returned. If a null is returned, a previously
 * existing varInfo exists and an error msg needs to be issued.
 *
 * @param  valueNameToken A variable name or value name Token
 * @param  type           The declared type of the new variable
 * @return                optional new VarInfo for the variable. If not present, a declaration for
 *                        that variable already exists. */
public Optional<VarInfo> declareNewVarNameWithValueName(Token valueNameToken, String type) {
  final String valueName = notNull(valueNameToken.getText());
  final String varName = variableName(valueName);
  return declareNewVariable(valueNameToken, type, varName, valueName);
}

Optional<VarInfo> declareNewVariable(Token varOrValueName, String type
                                         , String varName, @Nullable String valueName) {
  @Nullable VarInfo existingVarInfo = getConflictingVarDeclarationInfo(varName);
  final boolean varIsNew = (existingVarInfo == null);
  if (varIsNew) {
    final int declarationLine = varOrValueName.getLine();
    final VarInfo newVarInfo = new VarInfo(this, declarationLine, type, valueName);
    varToInfoMap.put(varName, newVarInfo);
    return notNull(Optional.of(newVarInfo));
  } else { // error: variable already declared
    return notNull(Optional.empty());
  }
}

boolean scopeIsStillInExecutable() {
  return ! (this instanceof BackgroundScope);
}

/* Notes on getConflictingVarDeclarationInfo and getVarReferenceInfo
 *
 * Although these two methods (immediately below) have essentially the same definition here, their
 * effect is different because of the overridden definitions in the BackgroundScope subclass. */

/**
 * If a variable cannot be declared at the current scope, return the information about the
 * conflicting declaration. Return a null if no variable was declared with the name or if it was
 * declared as a field, which allows a shadowing declaration. This requires a search for a
 * declaration of the variable name in all the scopes up to, but not including, the field-level
 * scope or the BackgroundScope which mirrors and protects it.
 * @return conflicting information for the variable, else null
 */
public @Nullable VarInfo getConflictingVarDeclarationInfo(String varName) {
  if (isTopLevelScope()) // field level scope, no conflict exists
    return null;

  @Nullable VarInfo varInfo = varToInfoMap.get(varName);
  final boolean varDefinedInThisScope = (varInfo != null);
  if (varDefinedInThisScope) {
    return varInfo;
  } else { // This is not a BackgroundScope, so we look in an ancestor scope
    return parent.getConflictingVarDeclarationInfo(varName);
  }
}

/** Returns the information for the variable or a null if the variable was not declared in any
 * ancestor scope.
 * @see BackgroundScope#getExistingVarInfo(String varName)
 * @return variable's information or a null
 */
public @Nullable VarInfo getExistingVarInfo(String variableName) {
  if (isVariableDefinedInThisScope(variableName))
    return varToInfoMap.get(variableName);

  if (isTopLevelScope()) { // the varName was not found in any ancestor scope
    return null;
  } else { // we have at least one ancestor and may be able to find the variable there
    return notNull(parent).getExistingVarInfo(variableName);
  }
}

/** Returns an Optional for the information for the variable. The Optional is empty if the variable
 * was not declared in any ancestor scope. Otherwise see BackgroundScope.getExistingVarInfo(String)
 * @see BackgroundScope#getExistingVarInfo(String varName)
 * @return variable's information or an empty optional
 */
/*TODO: finish converting all users from getExistingVarInfo(String)
 *      to getOptionalExistingVarInfo(String), THEN change name back to getExistingVarInfo(String)
 */
public Optional<@Nullable VarInfo> getOptionalExistingVarInfo(String variableName) {
  var optionalVarInfo = Optional.ofNullable(varToInfoMap.get(variableName));
  if ((optionalVarInfo.isPresent())) { // the varName was found in this scope
    return optionalVarInfo;
  } else if (isTopLevelScope()) { // the varName was not found in any ancestor scope
    return optionalVarInfo; // which is empty
  } else { // try to find the variable in an ancestor scope
    return notNull(parent).getOptionalExistingVarInfo(variableName);
  }
}


/** When declaring a local variable, we search up to but not in the background scope. Even if the
 * new local variable name is declared in the background scope, the local variable is allowed to
 * shadow it.
 * @param  varName
 * @return */
Scope getDeclarationScope(String varName) { // overriden in BackgroundScope
  if (varToInfoMap.containsKey(varName)) {
    return this;
  } else {
    return parent.getDeclarationScope(varName);
  }
}

/**
 * Return the Scope that a variable name was declared in. Searches all the way up the Scope tree,
 * including the top level object scope.
 */
Scope getVariableDeclarationScope(String varName) { // overriden in BackgroundScope
  if (varToInfoMap.containsKey(varName)) {
    return this;
  } else {
    return parent.getVariableDeclarationScope(varName);
  }
}

@Override
public String toString() {
  return label;
}

/**
 * Clean up fields to make them available to garbage collection, but keep scope info for
 * code generation.
 */
// Suppress null warnings because we are only using this method at the end of context checking to
// clean up fields that never contain a null.
@SuppressWarnings("null")
void clearForCodeGeneration() {
  for (VarInfo v : varToInfoMap.values()) {
    v.clearForCodeGen();
  }

  valuesAvailable.clear();
  valuesAvailable = null;
}

/** Clean up fields to make them available to garbage collection */
// Suppress null warnings because we are only using this method when a scope is no longer needed to
// clean up fields that never contain a null.
@SuppressWarnings("null")
void clear() {
  for (VarInfo v : varToInfoMap.values()) {
    v.clear();
  }
  varToInfoMap.clear();
  varToInfoMap = null;

  valuesAvailable.clear();
  valuesAvailable = null;
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

  // inner
  static class VarInfo {

    private Scope scopeWhereDeclared;

    public Scope getScopeWhereDeclared() {
      return scopeWhereDeclared;
    }

    /** The computational type of the variable, e.g., int, Employee. */
    private String type;

    /** @return the variable type, such as int, Employee */
    public String getType() {
      return type;
    }

    private int lineWhereDeclared;

    public int getLineWhereDeclared() {
      return lineWhereDeclared;
    }

    private String currentValueName = "";
    boolean isFirstReferenceToUninitializedField() {return currentValueName == "";}

    /** @return the name of the most recent value that has been assigned to this variable */
    public String getCurrentValueName() {
      return currentValueName;
    }

    public void setCurrentValueName(String newCurrentValueName) {
      currentValueName = newCurrentValueName;
    }

    /** Maps a valueName of this variable to the line where it was given a value. */
    private Map<String, Integer> valueToLineMap = new HashMap<>();

    /** The code generator needs to know which values are needed after they have been overwritten with
     * new values. Temporary variables can then be created to store these values. */
    public Set<String> reusedValueNames = new HashSet<>();

    public boolean hasDefinedValue(String valueName) {
      return valueToLineMap.containsKey(valueName);
    }

    public Set<String> definedValues() {
      return valueToLineMap.keySet();
    }

    /** Accept a new value name and make it the current value name that is being considered. This
     * should happen during assignment, but it can also happen when the default value is used for
     * a field.
     */
    public void defineNewValue(String valueName, int definitionLine) {
      if (getCurrentValueName() == "" || ! isAFinalValueName(getCurrentValueName())) {
        setCurrentValueName(valueName);
        valueToLineMap.put(valueName, definitionLine);
      }
    }

    public void defineNewValue(Token valueNameToken) {
      defineNewValue(notNull(valueNameToken.getText()), valueNameToken.getLine());
    }

    /**
     * Returns the line number where the valueName was given a value.
     */
    public @Nullable Integer lineOf(String valueName) {
      return valueToLineMap.get(valueName);
    }



    public VarInfo(Scope scopeWhereDeclared, int lineWhereDeclared, String type) {
      this(scopeWhereDeclared, lineWhereDeclared, type, null);
    }

    public VarInfo( Scope scopeWhereDeclared, int lineWhereDeclared
                  , String type             , @Nullable String valueName
                  )
    {
      this.scopeWhereDeclared = scopeWhereDeclared;
      this.lineWhereDeclared = lineWhereDeclared;
      this.type = type;
      if (valueName != null) {
        defineNewValue(valueName, lineWhereDeclared);
      }
    }

    public VarInfo(VarInfo shadowedInfo) {
      this.scopeWhereDeclared = shadowedInfo.scopeWhereDeclared;
      this.lineWhereDeclared = shadowedInfo.lineWhereDeclared;
      this.type = shadowedInfo.type;
      currentValueName = shadowedInfo.getCurrentValueName();
      // Can't just use pointers to the map and set instead of copying because each method will define
      // its own values and will reuse different values. The original VarInfo that is being shadowed
      // must be kept clean.
      valueToLineMap.putAll(shadowedInfo.valueToLineMap);
      reusedValueNames.addAll(shadowedInfo.reusedValueNames);
    }

    /** Free all data that is not needed for generating code. This enables faster garbage
     * collection. Because this data will never be used again the nulls do not violate any null
     * checking.
     */
    public void clearForCodeGen() {
    // We need valueToLineMap for setting the type for all values in prover
    //    valueToLineMap.clear();
    //    valueToLineMap   = null;
      currentValueName = "";
    }

    public String varName() {
      return variableName(currentValueName);
    }

    void removeLineInfo(String valueName) {
      valueToLineMap.remove(valueName);
    }

    boolean hasClassScope() {
      return scopeWhereDeclared instanceof BackgroundScope
          || scopeWhereDeclared.isInstanceScope()
          || scopeWhereDeclared.isStaticScope();
    }

    static boolean hasClassScope(Scope.VarInfo varInfo) {
      Scope scopeWhereDeclared = varInfo.getScopeWhereDeclared();
      return scopeWhereDeclared instanceof BackgroundScope
          || scopeWhereDeclared.isInstanceScope()
          || scopeWhereDeclared.isStaticScope();
    }

    /** Free all data for garbage collection. */
    @SuppressWarnings({ "null" })
    // null suppressed so we can cleanup with null
    public void clear() {
      clearForCodeGen();
      scopeWhereDeclared = null;
      reusedValueNames.clear();
      reusedValueNames = null;
    }

    @Override
    public String toString() {
      return this.currentValueName +":"+ this.type +" in scope "+ this.scopeWhereDeclared;
    }

  } // end inner class VarInfo


} // end class
