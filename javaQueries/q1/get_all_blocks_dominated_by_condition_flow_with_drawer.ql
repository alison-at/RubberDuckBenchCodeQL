import java
import semmle.code.java.dataflow.DataFlow
import semmle.code.java.dataflow.TaintTracking
import semmle.code.java.ControlFlowGraph
/*
Kind of sloppy to use string matching to find the variable 

Find the conditional which contains drawer and list every code block which is dominated by this conditional.
*/

from ConditionNode cn, BasicBlock bb, VarAccess va
where 
  cn.getLocation().toString().matches("%MessageList.%")
  and
  cn.asExpr().getAChildExpr() = va 
  and
  va.toString().matches("%drawer%")
  and 
  cn.getBasicBlock().dominates(bb) 
  and
  not bb.postDominates(cn.getBasicBlock())
select
  cn,
  bb,
  "This basic block is control-dependent on 'drawer'."