##  CodeQL Notes

This is a collection of my notes on the syntax and functionality of CodeQL for Python and Java. 
## Python

__DataFlow__
- To get Python dataflow nodes, edges, and paths as well as the selected elements, specifiy `@kind pathproblem` in the metadata and `import PathGraph` after instantiating the data flow module.
```
module Flow = TaintTracking::Global<MyDataFlow>;
import Flow::PathGraph
```
- There are two dataflow APIs. The new dataflow API can be accessed with import semmle.python.dataflow.new.DataFlow.
- The type called RemoteFlowSource for Python contains all predefined sources. This can be extended for new sources. 

__Call__
- Anything that looks like `<element>.<attribute>` will be seen as a Call and an Attribute by the Python CodeQL AST. 
- `self.getSize()` is the Call `self.getSize()` with the Attribute `getSize()`. To isolate out `self`, use Attribute `.getObject()`.
- APICall will not include calls to methods defined within the same file of as the call. Call will show those calls. 

__Attribute__
- To get a descriptive string of the attribute, use `<attribute>.getattr()` (if it is a method call) or similar. 
- `<attribute>.toString()` always prints out the text "Attribute()". 

__BinaryExpr__
- BinaryExprs for Python CodeQL mean simple math expressions like `a + b`. They do not mean logical expressions like `and`, `or`, `not`. 

__UnaryExpr__
- UnaryExpr encompases expressions with logical operators in Python CodeQL.
- The operation `not` is capitalized, must be matched to the string `Not`.

__Return__
- Return keywords do not get their own ControlFlowNodes.
- The subexpression of a Return type is the return value. Those do have a ControlFlowNode.

__Parameter__
- A selected Parameter will output as the text "Parameter", to get the actual name of the parameter use `<parameter>.getName()`.

Functions
---
There are many objects which relate to functions and function calls

__Function__
- A function def in the codebase

__Function Object__
- Relates a Function to Call objects. 
If there is a function as an attribute, this will not be percieved as a call on that function. `environment.get_value()` is not seen by Function Object
- Relates the call, caller, and callee together

__Function Invocation__
- Relates to the CallGraph
- `<FunctionInvocation>.getFunction()` returns the FunctionObject

__CallNode__
- There is an API:CallNode that is connected to the API graph of external calls
- There is also the "normal" AST CallNode

ControlFlow & Dataflow
---
In Changelog 0.11.6, there is this update on the implementation of dataflow for python:
"The dataflow graph no longer contains SSA variables. Instead, flow is directed via the corresponding controlflow nodes. This should make the graph and the flow simpler to understand. Minor improvements in flow computation has been observed, but in general negligible changes to alerts are expected."
- That ControlFlow is used all over in SSA.qll library source file maybe contradicts this changelog:
https://github.com/github/codeql/blob/5523b5e25f01c4bb3183d8286a2fd7194807566c/python/ql/lib/semmle/python/SSA.qll#L20

AST Graph
---
- The AST graph contains the above types like
Calls, Parameters, and Attributes. The Controlflow graph and Dataflow graph is seperate.
- For some AST nodes, there is a ControlFlowNode. For some, there is not: https://github.com/github/codeql/blob/5523b5e25f01c4bb3183d8286a2fd7194807566c/python/ql/lib/semmle/python/AstExtended.qll#L22

## Java
BinaryExpr
---
-  Java CodeQL BinaryExprs are expressions with logical operators.
- BinaryExpr.getOp() = BinaryExpr.getOp() does not compare the operators for the same symbol, BinaryExpr.getOp().toString() = BinaryExpr.getOp().toString()

AST Graph
---
- In the AST parser, an object method call like `<object>.<method>` is understood as a VarAccess with a nested MethodCall.
