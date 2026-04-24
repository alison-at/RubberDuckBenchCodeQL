import java 
import semmle.code.java.dataflow.TaintTracking

//does drawer impact actionBarSubTitle?
//This shows no dataflow between drawer and actionBarSubTitle, as we expect


module FlowConfig implements DataFlow::ConfigSig {
    predicate isSource(DataFlow::Node source) {
        //drawer = or drawer.something
        exists(VarAccess va |
        va.getVariable().hasName("drawer") and
        va.getVariable().getType().getName() = "K9Drawer" and
        source.asExpr() = va
        )
        or
        // Any result of a method call on `drawer` (e.g., drawer.getLayout())
        exists(MethodCall call |
        call.getQualifier() instanceof VarAccess and
        call.getQualifier().(VarAccess).getVariable().hasName("drawer") and
        call.getQualifier().(VarAccess).getVariable().getType().getName() = "K9Drawer" and
        source.asExpr() = call
        )
    }

    predicate isSink(DataFlow::Node sink) {
        //this finds dataflow to actionBarSubTitle but also anything that drawer touches
         //exists(Expr e | sink.asExpr() = e)
         
         //this find dataflow only to actionBarSubTitle
         exists(VarAccess va |
            //va.getVariable().toString().matches("%actionBarSubTitle%") and
            sink.asExpr() = va and not (va.toString().matches("drawer")))
        
    }
}

module Flow = TaintTracking::Global<FlowConfig>;
import Flow::PathGraph

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
from Flow::PathNode start, Flow::PathNode n, Flow::PathNode ns, int idx
where  FlowConfig::isSource(start.getNode()) and pathIndex(start, n, idx) and n.getASuccessor() = ns
    //and n.getNode() = c.getAFlowNode()
select start, n.getNode(), //n.getLocation(),
       ns.getNode(), //ns.getLocation(),
       idx
order by idx
/*
from Flow::PathNode source, Flow::PathNode sink
where Flow::flowPath(source, sink)
select sink, source, sink.toString(), "Data flows from drawer here"
*/

/*
actionbarsubtitle is a android textveiw object
setVisibility takes !singleFolderMode as an argument
https://developer.android.com/reference/android/view/View#setVisibility(int)
(!singleFolderMode) ? View.GONE : View.VISIBLE
if !singleFolderMode use view.gone, else use view.visible
so does drawer impact singlefoldermodel to impact actionbarsubtitle.setvisibility
does drawer

make a seperate query which says drawer != null for actionbarsubtitle.setVisibility to happen
*/