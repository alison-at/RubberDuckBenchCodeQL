import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.dataflow.new.TaintTracking
import semmle.python.ApiGraphs
import semmle.python.pointsto.CallGraph
import semmle.python.types.FunctionObject
/*

*/

/**
 * @kind path-problem
 */
private module ComparisonDataFlow implements DataFlow::ConfigSig {
    predicate isSource(DataFlow::Node source) {
        exists(UnaryExpr ue, File f |
            source.asExpr() = ue.getOperand()
            and
            ue.getOp().toString() = "Not"
            and ue.getOperand().toString().matches("%build_dir%")
            and f.toString().matches("%corpus_pruning_task.py")
            and ue.getLocation().getFile() = f
        )
        
        
    } 
    predicate isSink(DataFlow::Node sink) {
        
        
       exists (UnaryExpr ue, File f |
            ue.getOperand() = sink.asExpr()
            and
            ue.getOp().toString() = "Not"
            and ue.getOperand().toString().matches("%build_dir%")
            and f.toString().matches("%engine_common.py")
            and ue.getLocation().getFile() = f
        )
        
        
    }

    predicate isAdditionalFlowStep(DataFlow::Node source, DataFlow::Node sink) {
        exists(Call c, Attribute a, Expr e, Function f, Parameter p, Attribute a2  |
            //find engine_common.find_fuzzer_path and find_fuzzer_path in engine_common.py
            c.getFunc() = a
            and c.getFunc().getASubExpression().toString().matches("engine_common")
            and f.getName().toString().matches(a.getAttr().toString())
            and f.getEnclosingModule().toString().matches("%"+c.getFunc().getASubExpression().toString())
            //find self.build_directory as an argument and associate it with build_directory the parameter
            //e = self.build_directory
            and c.getAnArg() = e
            //a2 = self.build_directory
            and e = a2
            and a2.getAttr().toString().matches("build_directory")
            and p = f.getAnArg()
            and p.getName().matches("build_directory")

            and sink.asExpr() = p
            and source.asExpr() = e
            ) 
    }
   

    
}

module Flow = TaintTracking::Global<ComparisonDataFlow>;
import Flow::PathGraph

/**
 * Recursive predicate to assign a step index along a path
 */
predicate pathIndex(Flow::PathNode start, Flow::PathNode n, int idx) {
    // Base case: the start node is index 0
    n = start and idx = 0
    or
    exists(Flow::PathNode prev, int prevIdx |
        pathIndex(start, prev, prevIdx) and
        prev.getASuccessor() = n and
        prev != n and
        idx = prevIdx + 1
    )
}

/**
 * Select edges with index so we can order them
 */
from Flow::PathNode start, Flow::PathNode n, Flow::PathNode ns, int idx, Attribute a1, Call c
where  ComparisonDataFlow::isSource(start.getNode()) and pathIndex(start, n, idx) and n.getASuccessor() = ns
    and 
    c.getFunc() = a1
    //and n.getNode() = c.getAFlowNode()
select start, n.getNode(), //n.getLocation(),
       ns.getNode(), //ns.getLocation(),
       idx
order by idx

