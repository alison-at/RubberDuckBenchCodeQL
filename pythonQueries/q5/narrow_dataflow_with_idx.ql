import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.dataflow.new.TaintTracking
import semmle.python.ApiGraphs
import semmle.python.pointsto.CallGraph

/**
 * @kind path-problem
 */

private module SmallDataFlow implements DataFlow::ConfigSig {
    predicate isSource(DataFlow::Node source) { 
        exists(Expr e, AssignStmt a | 
            e = API::moduleImport("os").getMember("getenv").getACall().asExpr()
            and source.asExpr() = e
            and a.getASubExpression() = e
        )
    }

    predicate isSink(DataFlow::Node sink) {
        exists(AssignStmt a, Expr e |
            a.getATarget() = e
            and e.toString().matches("build_directory%")
            and e = sink.asExpr()
        )
    }

    predicate isAdditionalFlowStep(DataFlow::Node source, DataFlow::Node sink) {
        exists(Return r, Function f, Call c, Attribute a, File file |
            r.getASubExpression() = source.asExpr() 
            and a.getAttr() = f.getName()
            and f.contains(r)
            and sink.asExpr() = c
            and c.getFunc() = a
            and f.getEnclosingModule().toString().matches("%"+a.getObject().toString()+"%")

            and a.getObject().toString().matches("%environment%")
            and c.getLocation().toString().matches("%corpus_pruning_task%")
            and r.getASubExpression().toString().matches("%eval%")
            and f.toString().matches("%get_value%")
        )
    }
}

module Flow = TaintTracking::Global<SmallDataFlow>;
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
where  SmallDataFlow::isSource(start.getNode()) and pathIndex(start, n, idx) and n.getASuccessor() = ns
    and 
    c.getFunc() = a1
    //and n.getNode() = c.getAFlowNode()
select start, n.getNode(), //n.getLocation(),
       ns.getNode(), //ns.getLocation(),
       idx
order by idx