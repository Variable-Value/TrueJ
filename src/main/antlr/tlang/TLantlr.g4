/*
 [The "BSD licence"]
 Copyright (c) 2013 George S. Cowan
 All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 1. Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution.
 3. The name of the author may not be used to endorse or promote products
  derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/


/** T Language, version 0.00a
  grammar for Antlr 4
   Includes TJava based on Java 7 grammar at
    https://github.com/antlr/grammars-v4/tree/master/java7/Java7.g4

  TODO: Correctly parses sequences of assignment statements to primatives in methods.
        Other parts of the system will generate working Java and verify the logic.
  */
grammar TLantlr;

import TJava;

@header {
package tlang; // or provide in command line as "-package tlang"
}


/*******************************************************************************
      Parser section
*******************************************************************************/

t_compilationUnit
  : t_packageDeclaration? t_importDeclaration* t_typeDeclaration* EOF
  ;

// note that annotations for a package are only allowed in a single place
// and that is recommended to be the package-info.java file.
t_packageDeclaration
  : t_annotation* 'package' t_qualifiedName ';'
  ;

t_importDeclaration
  : 'import' 'static'? t_qualifiedName ('.' '*')? ';'
  ;

t_typeDeclaration
  : t_classOrInterfaceModifier* t_classDeclaration
  | t_classOrInterfaceModifier* t_enumDeclaration
  | t_classOrInterfaceModifier* t_interfaceDeclaration
  | t_classOrInterfaceModifier* t_annotationTypeDeclaration
  | ';'
  ;

// The Context checker must prohibit certain modifiers, e.g., private constants in an interface.
t_modifier
  : t_classOrInterfaceModifier
  | ( 'native'
    | 'synchronized'
    | 'transient'
    | 'volatile'
    )
  ;

t_classOrInterfaceModifier
  : t_annotation   // class or interface
  | (   'public'   // class or interface
    | 'protected'  // class or interface
    | 'private'    // class or interface
    | 'static'     // class or interface
    | 'abstract'   // class or interface
    | 'default'    // interface only
    | 'transient'  // class only -- does not apply to interfaces
    | 'final'      // class only -- does not apply to interfaces
    | 'strictfp'   // class or interface
    )
  ;

t_variableModifier
  : 'final'
  | t_annotation
  ;

t_classDeclaration
  : 'class' UndecoratedIdentifier t_typeParameters?
    ('extends' t_type)?
    ('implements' t_typeList)?
    t_classBody
  ;

t_typeParameters
  : '<' t_typeParameter (',' t_typeParameter)* '>'
  ;

t_typeParameter
  : UndecoratedIdentifier ('extends' t_typeBound)?
  ;

t_typeBound
  : t_type ('&' t_type)*
  ;

t_enumDeclaration
  : ENUM UndecoratedIdentifier ('implements' t_typeList)?
      '{' t_enumConstants? ','? t_enumBodyDeclarations? '}'
  ;

t_enumConstants
  : t_enumConstant (',' t_enumConstant)*
  ;

t_enumConstant
  : t_annotation* UndecoratedIdentifier t_arguments? t_classBody?
  ;

t_enumBodyDeclarations
  : ';' t_classBodyDeclaration*
  ;

t_interfaceDeclaration
  : 'interface' UndecoratedIdentifier t_typeParameters? ('extends' t_typeList)? t_interfaceBody
  ;

t_typeList
  : t_type (',' t_type)*
  ;

t_classBody
  : '{' t_classBodyDeclaration* '}'
  ;

t_interfaceBody
  : '{' t_interfaceBodyDeclaration* '}'
  ;

t_classBodyDeclaration
  : ';'
  | 'static'? t_initializer
  | t_modifier* t_memberDeclaration
  ;

t_initializer
  : t_block (t_finalMeans)?
  ;

t_memberDeclaration
  : t_methodDeclaration
  | t_genericMethodDeclaration
  | t_fieldDeclaration
  | t_constructorDeclaration
  | t_genericConstructorDeclaration
  | t_interfaceDeclaration
  | t_annotationTypeDeclaration
  | t_classDeclaration
  | t_enumDeclaration
  ;

/* We use this rule even for void methods which cannot have [] after parameters.
   This simplifies grammar and we can consider void to be a type, which
   renders the [] matching as a context-sensitive issue or a semantic check
   for invalid return type after parsing.
 */
t_methodDeclaration
  :   (t_type|'void') UndecoratedIdentifier t_formalParameters ('[' ']')*
      ('throws' t_qualifiedNameList)?
      ( t_methodBody
      | ';'
      )
      (t_finalMeans)?
  ;

t_methodBody
  : t_block
  ;

t_genericMethodDeclaration
  : t_typeParameters t_methodDeclaration
  ;

t_constructorDeclaration
  : UndecoratedIdentifier t_formalParameters ('throws' t_qualifiedNameList)?
      t_constructorBody (t_finalMeans)?
  ;

t_constructorBody
  : t_block
  ;

t_genericConstructorDeclaration
  : t_typeParameters t_constructorDeclaration
  ;

t_fieldDeclaration
  : ty=t_type t_fieldDeclarator[$ty.text] (',' t_fieldDeclarator[$ty.text])* ';'
  ;

/** Implementation note: separate processing is required for initialized and
    uninitialized fields in the SemanticsCheckVisitor, but this causes a little
    awkwardness in the FieldVistor.
 */
t_fieldDeclarator[String idType]
  : t_idDeclaration[$idType] op='=' t_variableInitializer   #InitializedField
  | t_idDeclaration[$idType]                                #UninitializedField
  ;

t_interfaceBodyDeclaration
  : ';'
  | t_modifier* t_memberDeclaration // certain members are prohibited or have restricted modifiers
  ;

// t_interfaceMemberDeclaration
//   : t_constDeclaration
//   | t_interfaceMethodDeclaration
//   | t_genericInterfaceMethodDeclaration
//   | t_interfaceDeclaration
//   | t_annotationTypeDeclaration
//   | t_classDeclaration
//   | t_enumDeclaration
//   ;
//
// t_constDeclaration
//   : ty=t_type t_constantDeclarator[$ty.text] (',' t_constantDeclarator[$ty.text])* ';'
//   ;
//
// t_constantDeclarator [String idType]
//   : t_idDeclaration[$idType] op='=' t_variableInitializer
//   ;
//
// Requires much work for default, static, and private methods in interface
// see matching of [] comment in methodDeclaratorRest
// t_interfaceMethodDeclaration
//   : t_methodDeclaration
//   ;
//
// t_genericInterfaceMethodDeclaration
//   : t_typeParameters t_interfaceMethodDeclaration
//   ;

t_annotationVariableDeclarator
  : t_annotationVariableDeclaratorId '=' t_variableInitializer
  ;

t_variableDeclarator [String idType]
  : t_initializedVariableDeclaratorId[$idType] op='=' t_variableInitializer #InitializedVariable
  | t_uninitializedVariableDeclaratorId[$idType]                            #UninitializedVariable
  ;

t_initializedVariableDeclaratorId [String idType]
  : t_idDeclaration[$idType]
  ;

t_uninitializedVariableDeclaratorId [String idType]
  : t_idDeclaration[$idType]
  ;

t_annotationVariableDeclaratorId
  : t_identifier ('[' ']')*
  ;

t_variableInitializer
  : t_arrayInitializer
  | t_expression
  ;

t_arrayInitializer
  : '{' (t_variableInitializer (',' t_variableInitializer)* (',')? )? '}'
  ;

t_packageOrTypeName
  : t_qualifiedName
  ;

t_enumConstantName
  : UndecoratedIdentifier
  ;

t_typeName
  : t_qualifiedName
  ;

t_type
  : t_classOrInterfaceType ('[' ']')*
  | t_primitiveType ('[' ']')*
  ;

t_classOrInterfaceType
  : UndecoratedIdentifier t_typeArguments? ('.' UndecoratedIdentifier t_typeArguments? )*
  ;

t_primitiveType
  : 'boolean'
  | 'char'
  | 'byte'
  | 'short'
  | 'int'
  | 'long'
  | 'float'
  | 'double'
  ;

t_typeArguments
  : '<' t_typeArgument (',' t_typeArgument)* '>'
  ;

t_typeArgument
  : t_type
  | '?' (('extends' | 'super') t_type)?
  ;

t_qualifiedNameList
  : t_qualifiedName (',' t_qualifiedName)*
  ;

t_formalParameters
  : '(' t_formalParameterList? ')'
  ;

t_formalParameterList
  : t_formalParameter (',' t_formalParameter)* (',' t_lastFormalParameter)?
  | t_lastFormalParameter
  ;

t_formalParameter
  : t_variableModifier* ty=t_type t_initializedVariableDeclaratorId[$ty.text]
  ;

t_lastFormalParameter
  : t_variableModifier* ty=t_type '...' t_initializedVariableDeclaratorId[$ty.text]
  ;

t_qualifiedName
  : t_identifier ('.' t_identifier)*
  ;

t_literal
  : IntegerLiteral
  | FloatingPointLiteral
  | CharacterLiteral
  | StringLiteral
  | BooleanLiteral
  | 'null'
  ;

// ANNOTATIONS

t_annotation
  : '@' t_annotationName ( '(' ( t_elementValuePairs | t_elementValue )? ')' )?
  ;

t_annotationName : t_qualifiedName ;

t_elementValuePairs
  : t_elementValuePair (',' t_elementValuePair)*
  ;

t_elementValuePair
  : UndecoratedIdentifier '=' t_elementValue
  ;

t_elementValue
  : t_expression
  | t_annotation
  | t_elementValueArrayInitializer
  ;

t_elementValueArrayInitializer
  : '{' (t_elementValue (',' t_elementValue)*)? (',')? '}'
  ;

t_annotationTypeDeclaration
  : '@' 'interface' UndecoratedIdentifier t_annotationTypeBody
  ;

t_annotationTypeBody
  : '{' (t_annotationTypeElementDeclaration)* '}'
  ;

t_annotationTypeElementDeclaration
  : ';' // this is not allowed by the grammar, but apparently allowed by the Java compiler
  | t_modifier*
    ( t_type t_annotationMethodRest ';'
    | t_type t_annotationConstantRest ';'
    | t_classDeclaration ';'?
    | t_interfaceDeclaration ';'?
    | t_enumDeclaration ';'?
    | t_annotationTypeDeclaration ';'?
    )
  ;

t_annotationMethodRest
  : UndecoratedIdentifier '(' ')' t_defaultValue?
  ;

t_annotationConstantRest
  : t_annotationVariableDeclarator (',' t_annotationVariableDeclarator)*
  ;

t_defaultValue
  : 'default' t_elementValue
  ;


// STATEMENTS / BLOCKS

t_block
  : openBrace='{'  t_blockStatement*  (t_markedFinalMeans)? closeBrace='}'
  ;

t_blockStatement
  : t_localVariableDeclaration ';'
  | t_typeDeclaration
  | t_statement
  ;

t_localVariableDeclaration
  : t_variableModifier* ty=t_type
        t_variableDeclarator[$ty.text] (',' t_variableDeclarator[$ty.text])*
  ;

t_statement
  : t_block                                                                      # BlockStmt
  | ASSERT t_expression (':' t_expression)? ';'                                  # AssertStmt
  | 'if' t_parExpression t_statement ('else' t_statement)?                       # IfStmt
  | 'for' '(' t_forControl ')' t_statement                                       # ForStmt
  | 'while' t_parExpression t_statement                                          # WhileStmt
  | 'variant' t_expression ';'                                                   # VariantStmt
  | 'invariant' t_expression ';'                                                 # InvariantStmt
  | 'do' t_statement 'while' t_parExpression ';'                                 # DoStmt
  | 'try' t_block (t_catchClause+ t_finallyBlock? | t_finallyBlock)              # TryStmt
  | 'try' t_resourceSpecification t_block t_catchClause* t_finallyBlock?         # TryStmt
  | 'switch' t_parExpression '{' t_switchBlockStatementGroup* t_switchLabel* '}' # SwitchStmt
  | 'synchronized' t_parExpression t_block                                       # SyncStmt
  | 'return' t_expression? ';'                                                   # ReturnStmt
  | 'throw' t_expression ';'                                                     # ThrowStmt
  | 'break' UndecoratedIdentifier? ';'                                           # BreakStmt
  | 'continue' UndecoratedIdentifier? ';'                                        # ContinueStmt
  | ';'                                                                          # EmptyStmt
	| t_assignable op='=' t_expression ';'                                         # AssignStmt
  | t_expression '(' t_expressionList? ')' ';'                                   # CallStmt
  | t_expression '.' 'new' t_nonWildcardTypeArguments? t_innerCreator            # CreationStmt
  | UndecoratedIdentifier ':' t_statement                                        # LabelStmt
  | t_means                                                                      # MeansStmt
  | t_given                                                                      # GivenStmt
  | t_ERROR                                                                      # ERROR_STMT
  ;

/**
 * Catch some errors caused by misspelled keywords
 */
t_ERROR
  : t_identifier t_expression ';'
  ;

t_assignable // left hand side or method argument referring to a modified object
  : t_expression '[' t_expression ']'
  | t_identifier
  ;

t_catchClause
  : 'catch' '(' t_variableModifier* t_catchType t_identifier ')' t_block
  ;

t_catchType
  : t_qualifiedName ('|' t_qualifiedName)*
  ;

t_finallyBlock
  : 'finally' t_block
  ;

t_resourceSpecification
  : '(' t_resources ';'? ')'
  ;

t_resources
  : t_resource (';' t_resource)*
  ;

t_resource
  : t_variableModifier* ty=t_classOrInterfaceType
    t_initializedVariableDeclaratorId[$ty.text] '=' t_expression
  ;

/** Matches cases then statements, both of which are mandatory.
 *  To handle empty cases at the end, we add switchLabel* to statement.
 */
t_switchBlockStatementGroup
  : t_switchLabel+ t_blockStatement+
  ;

t_switchLabel
  : 'case' t_constantExpression ':'
  | 'case' t_enumConstantName ':'
  | 'default' ':'
  ;

t_forControl
  : t_enhancedForControl
  | t_forInit? ';' t_expression? ';' t_forUpdate?
  ;

t_forInit
  : t_localVariableDeclaration
  | t_expressionList
  ;

t_enhancedForControl
  : t_variableModifier* t_type t_identifier ':' t_expression
  ;

t_forUpdate
  : t_expressionList
  ;

// EXPRESSIONS

t_parExpression
  : '(' t_expression ')'
  ;

t_expressionList
  : t_expression (',' t_expression)*
  ;

t_constantExpression
  : t_expression
  ;

t_expression : t_expressionDetail; // to give us a t_expression visitor
t_expressionDetail // in order of most sticky to least sticky
  : t_primary                                                                  # PrimaryExpr
  | t_expressionDetail '.' t_identifier                                        # DotExpr
  | t_expressionDetail '.' 'this'                                              # DotThisExpr
  | t_expressionDetail '.' 'new' t_nonWildcardTypeArguments? t_innerCreator    # DotNewExpr
  | t_expressionDetail '.' 'super' t_superSuffix                               # DotSuperExpr
  | t_expressionDetail '.' t_explicitGenericInvocation                         # DotExplicitGenericExpr
  | t_expressionDetail '[' t_expressionDetail ']'                              # ArrayExpr
  | t_expressionDetail '(' (t_expressionDetail (',' t_expressionDetail)*)? ')' # FuncCallExpr
  | 'new' t_creator                                                            # NewExpr
  | '(' t_type ')' t_expressionDetail                                          # TypeCastExpr
  | ('+'|'-') t_expressionDetail                                               # SignExpr
  | '~' t_expressionDetail                                                     # BitComplementExpr
  | '!' t_expressionDetail                                                     # NotExpr
  | t_expressionDetail ('*'|'/'|'%') t_expressionDetail                        # MultiplicativeExpr
  | t_expressionDetail ('+'|'-') t_expressionDetail                            # AdditiveExpr
  | t_expressionDetail ('<' '<' | '>' '>' '>' | '>' '>') t_expressionDetail    # ShiftExpr
  | t_expressionDetail op=('<'|'<='|'='|'>='|'>'|'!=') t_expressionDetail      # ConjRelationExpr
                                // = is not assignment in expressions
      // Allowed conjunctive chains:
      //   A sequence of =
      //   A sequence of = with a single embedded !=, which implies !=
      //   A sequence of intermixed =, > and >=, which implies >= (or > if one is present)
      //   A sequence of intermixed =, < and <=, which implies <= (or < if one is present)
      //   Other sequences are prohibited, such as a >= b <= c,
      //                          which would mean a and c >= b
  | t_expressionDetail 'instanceof' t_type                                     # InstanceOfExpr
  | t_expressionDetail '&' t_expressionDetail                                  # AndExpr
  | t_expressionDetail '^' t_expressionDetail                                  # ExclusiveOrExpr
  | t_expressionDetail '|' t_expressionDetail                                  # OrExpr
  | t_expressionDetail '&&' t_expressionDetail                                 # ConditionalAndExpr
  | t_expressionDetail '||' t_expressionDetail                                 # ConditionalOrExpr
  | t_expressionDetail '?' t_expressionDetail ':' t_expressionDetail           # ConditionalExpr
  | t_expressionDetail op=('<==' | '===' | '=!='| '==>') t_expressionDetail    # ConjunctiveBoolExpr
      // Allowed conjunctive chains:
      //   A sequence of ===
      //   A sequence of === with a single embedded =!=, which implies =!=
      //   A sequence of intermixed === and ==>, which implies ==>
      //   A sequence of intermixed === and <==, which implies <==
      //   Other sequences are prohibited, such as A ==> B =!= C <== D,
      //                             which implies (A =!= D) | (A === false)

  | ('sum' | 'prod' | 'forall' | 'forsome' | 'set' | 'list' | 'bag')
    t_quantifiedExpression                                                     # QuantifierExpr

//  | t_expressionDetail     // only = assignment allowed
//      (  '='<assoc=right>     // specified in rule (t_statement # AssignStmt)
//      | '+='<assoc=right>
//      | '-='<assoc=right>  // All incremental operators are useless in TrueJ because reference
//      | '*='<assoc=right>  // to a particular value of a variable is required, e.g.,
//      | '/='<assoc=right>  //   x' += 4;
//      | '&='<assoc=right>  // is ambiguous because we need to specify the value name of the
//      | '|='<assoc=right>  // previous value of x, as in,
//      | '^='<assoc=right>  //   x' = x'almostThere + 4;
//      | '>>='<assoc=right>
//      | '>>>='<assoc=right>
//      | '<<='<assoc=right>
//      | '%='<assoc=right>
//      )
//      t_expressionDetail
  ;

/**
 * The body of a quantified expression. The range constraint may be a collection of a super type of
 * the identifiers, or else it is a boolean expression intended to restrict the possible range of
 * the identifiers. The then-expression is an expression of the type needed by the type of the
 * quantifier.
 */
t_quantifiedExpression
  : '(' t_type t_identifier (',' t_identifier)*
    ':' (t_rangeConstraint)?
    ':' (t_expression)
    ')'
  ;

t_rangeConstraint
  : t_expression
  ;

t_primary // any changes must coordinate with TLantlrProofVisitor.isBooleanPrimary()
  : t_parExpression
  | 'this'
  | 'super'
  | t_literal
  | t_identifier
  | t_type '.' 'class'
  | 'void' '.' 'class'
  | t_nonWildcardTypeArguments (t_explicitGenericInvocationSuffix | 'this' t_arguments)
  ;

t_creator
  : t_nonWildcardTypeArguments t_createdName t_classCreatorRest
  | t_createdName (t_arrayCreatorRest | t_classCreatorRest)
  ;

t_createdName
  : t_identifier t_typeArgumentsOrDiamond? ('.' t_identifier t_typeArgumentsOrDiamond?)*
  | t_primitiveType
  ;

t_innerCreator
  : t_identifier t_nonWildcardTypeArgumentsOrDiamond? t_classCreatorRest
  ;

t_arrayCreatorRest
  : '['
      (   ']' ('[' ']')* t_arrayInitializer
      | t_expression ']' ('[' t_expression ']')* ('[' ']')*
      )
  ;

t_classCreatorRest
  : t_arguments t_classBody?
  ;

t_explicitGenericInvocation
  : t_nonWildcardTypeArguments t_explicitGenericInvocationSuffix
  ;

t_nonWildcardTypeArguments
  : '<' t_typeList '>'
  ;

t_typeArgumentsOrDiamond
  : '<' '>'
  | t_typeArguments
  ;

t_nonWildcardTypeArgumentsOrDiamond
  : '<' '>'
  | t_nonWildcardTypeArguments
  ;

t_superSuffix
  : t_arguments
  | '.' t_identifier t_arguments?
  ;

t_explicitGenericInvocationSuffix
  : 'super' t_superSuffix
  | t_identifier t_arguments
  ;

t_arguments
  : '(' t_expressionList? ')'
  ;

t_finalMeans
  : t_markedFinalMeans
  | t_genericFinalMeans
  ;

t_markedFinalMeans
  : FINAL t_genericFinalMeans
  ;

/**
 * The final means which collects both marked and unmarked final means. Therefore this can be used
 * by the parser to mark both as "final".
 */
t_genericFinalMeans
  : t_means
  ;

t_means
  : MEANS t_expression ';'
  ;

t_given
  : GIVEN t_expression ';'
  ;

t_idDeclaration [String idType]
  : t_identifier
  ;

t_identifier : t_identifierDetail ; // to give us a t_identifier visitor
t_identifierDetail
  : UndecoratedIdentifier   # T_UndecoratedIdentifier
	| PreValueName            # T_PreValueName
	| MidValueName            # T_MidValueName
	| PostValueName           # T_PostValueName
	;

t_valueName
  : PreValueName
  | MidValueName
  | PostValueName
  // | t_invalidIdentifierWithReservedString
  ;

// t_invalidIdentifierWithReservedString
//   : InvalidNameWithReservedString
//   ;

// t_invalidCommentWithReservedString
//   : INVALID_LINE_COMMENT_WITH_RESERVEDSTRING
//   | INVALID_COMMENT_WITH_RESERVEDSTRING
//   ;


/*******************************************************************************
      Lexer section
*******************************************************************************/

// §3.9 Keywords ( Java keywords are also listed here to keep from having them
//                 overridden by other lexer rules in the T language)

ABSTRACT      : 'abstract';
ASSERT        : 'assert';
BOOLEAN       : 'boolean';
BREAK         : 'break';
BYTE          : 'byte';
CASE          : 'case';
CATCH         : 'catch';
CHAR          : 'char';
CLASS         : 'class';
CONST         : 'const';
CONTINUE      : 'continue';
DEFAULT       : 'default';
DO            : 'do';
DOUBLE        : 'double';
ELSE          : 'else';
ENUM          : 'enum';
EXTENDS       : 'extends';
FINAL         : 'final';
FINALLY       : 'finally';
FLOAT         : 'float';
FOR           : 'for';
FORALL        : 'forall';
FORSOME       : 'forsome';
IF            : 'if';
GIVEN         : 'given';
GOTO          : 'goto';
IMPLEMENTS    : 'implements';
IMPORT        : 'import';
INSTANCEOF    : 'instanceof';
INT           : 'int';
INTERFACE     : 'interface';
INVARIANT     : 'invariant';
LONG          : 'long';
MEANS         : 'means';
NATIVE        : 'native';
NEW           : 'new';
PACKAGE       : 'package';
PRIVATE       : 'private';
PROD          : 'prod';
PROTECTED     : 'protected';
PUBLIC        : 'public';
RETURN        : 'return';
SHORT         : 'short';
STATIC        : 'static';
STRICTFP      : 'strictfp';
SUM           : 'sum';
SUPER         : 'super';
SWITCH        : 'switch';
SYNCHRONIZED  : 'synchronized';
THIS          : 'this';
THROW         : 'throw';
THROWS        : 'throws';
TRANSIENT     : 'transient';
TRY           : 'try';
VARIANT       : 'variant';
VOID          : 'void';
VOLATILE      : 'volatile';
WHILE         : 'while';

// §3.10.3 Boolean Literals

// Repeated here (from TJava.g4) because definition of UndecoratedIdentifier
//   would subsume true and false
BooleanLiteral
    :   'true'
    |   'false'
    ;

// §3.10.7 The Null Literal

NullLiteral
    :   'null'
    ;

// §3.12 Operators

// Conjunctive Boolean Operators

CONJUNCTIVE_BOOLEAN_EQUAL : '===';
CONJUNCTIVE_IMPLIES       : '==>';
CONJUNCTIVE_CONSEQUENCE   : '<==';
CONJUNCTIVE_NOT_EQUAL     : '=!=';


/* §3.8 Identifiers (this definition must appear after all keywords and alphabetic
                     literals in the grammar because they would be subsumed by
                     the definition of Identifier)
*/

/** We use UndecoratedIdentifier instead of Identifier everywhere within the T
    grammar for clarity and to provide better error messages
 */
UndecoratedIdentifier
    : JavaLetter JavaLetterOrDigit*
    ;

Identifier
  : 'We are just overriding the TJava.g4 definition of Identifier'
    'with a few of impossible tokens'
    'ew;oirtyughbnp;iowsyuernyboianu'
  ;

///** This is an attempt to generate error messages from within a token
//      definition, but I can't get it to generate the message.
//
//      TODO: investigate the code generated in the tokenizer
// */
//UndecoratedIdentifier
//  : JavaLetter JavaLetterOrDigit*
//    { ! getText().contains("$"+"T$") }?
//      <fail={"$T$ is an invalid string of characters in the T language"}>
//  ;

// InvalidNameWithReservedString
//   : SingleQuote ReservedString (JavaLetterOrDigit | SingleQuote)*
//   | SingleQuote (JavaLetterOrDigit | SingleQuote)* ReservedString (JavaLetterOrDigit | SingleQuote)*
//   | ReservedString (JavaLetterOrDigit | SingleQuote)*
//   | (JavaLetterOrDigit | SingleQuote)* ReservedString (JavaLetterOrDigit | SingleQuote)*
//   ;

PreValueName
  : SingleQuote  JavaLetter JavaLetterOrDigit*
	;

MidValueName
  : JavaLetter JavaLetterOrDigit* SingleQuote JavaLetterOrDigit+
	;

PostValueName
  : JavaLetter JavaLetterOrDigit* SingleQuote
  ;

fragment
SingleQuote : '\'' ;


//
// Whitespace and comments (override "skip" to "channel(HIDDEN)")
//

WS
  : [ \r\t\u000C\n]+ -> channel(HIDDEN)
  ;

/** TODO: The string $T$ is reserved for use in generated Java code and may not be used in
 *  the T language.
 */
fragment
ReservedString
  : '$T$' // {false}?<fail={"$T$ is an invalid string of characters in the T language"}>
  ;
//
// INVALID_COMMENT_WITH_RESERVEDSTRING
//   : '/*' .*? ReservedString .*? '*/'
//     {msgContainer.add($line+":"+$col+" The characters $T$ are reserved for use by the T language compiler.")}
//   ;

COMMENT
  : '/*' .*? '*/' -> channel(HIDDEN)
  ;


/**
 * Comments may not contain the reserved string $T$
 */
//COMMENT
//  : '/*' CommentTail -> channel(HIDDEN)
//  ;
//
//fragment
//CommentTail
//  : ~[\$\*]*? '*/'
//  | ~[$]* '$'+ ( '*/'
//               | ~[T] CommentTail
//               | 'T' ( '*/'
//                     | ~[$] CommentTail
//                     )
//               )
//  ;

// fragment
// CommentTail
//   : ~[$]*? '*/'
//   | ~[$]* '$'+  '*/'
//   | ~[$]* '$'+ ~[T] CommentTail)
//   | ~[$]* '$T' ( '*/' | ~[$] CommentTail)
//   ;

// COMMENT
//   : '/*' .*? '*/'
// //    {getText().contains("$"+"T$")}?<fail={"$T$ is an invalid string of characters in the T language"}> // exclude $T$}
//   -> channel(HIDDEN)
//   ;

// INVALID_LINE_COMMENT_WITH_RESERVEDSTRING
//   : '//' ~[\r\n]*? ReservedString ~[\r\n]*
//   ;

LINE_COMMENT
  : '//' ~[\r\n]*    -> channel(HIDDEN)
  ;
