

import macros

proc remove*[T](self:var seq[T],val:T)=
  self.del(self.find(val))
macro hoist*(body:typed):untyped=
  var pre = newStmtList()
  for x in body:
    if x.kind in RoutineNodes:
      var h = x.copy()
      pre.add(h)
      h.body = newEmptyNode()
  body.insert(0,pre)
  # result = newStmtList(pre,body)
  hint repr body
  hint astgenrepr body
  body
macro context*(T:typed,body:untyped):typed=
  for n in body:
    if n.kind in RoutineNodes:
      if n.params.len>1:
        let p = n.params[1]
        if p[0] == "self".ident:
          if p[1].kind != nnkEmpty:
            error("wrong context parameter type for `self` " & repr(n), n)
        else:
          n.params.insert(1, newIdentDefs("self".ident, newEmptyNode()))
      else:
        n.params.insert(1, newIdentDefs("self".ident, newEmptyNode()))
      n.params[1][1]=T
  body.insert(0,
    newStmtList(
      nnkPragma.newTree("push".ident),
      nnkPragma.newTree(newColonExpr("this".ident, "self".ident)),
    )
  )
  body.add(
    nnkPragma.newTree("pop".ident)
  )
  # hint repr body
  return body
macro getter*(source: typed, target: untyped): typed =
  var 
    sourceOwner = source[0]
    sourceField = source[1]
    T = source.getTypeImpl()[1]
  quote do:
    proc `target`*(self:`sourceOwner`):`T`=
      self.`sourceField`
macro property*(source: typed, target: untyped): typed =
  var 
    sourceOwner = source[0]
    sourceField = source[1]
    T = source.getTypeImpl()[1]
    settarget = nnkAccQuoted.newTree(($target & "=").ident)
  quote do:
    proc `target`*(self:`sourceOwner`):`T`=
      self.`sourceField`
    proc `settarget`*(self:`sourceOwner`, value:`T`)=
      self.`sourceField` = value
macro owner_property*(source: typed, target: untyped): typed =
  var 
    sourceOwner = source[0]
    sourceField = source[1]
    T = source.getTypeImpl()[1]
    settarget = nnkAccQuoted.newTree(($target & "=").ident)
  result = quote do:
    # static:
    proc `target`*(self:`sourceOwner`):`T`{.inject.}=
      self.`sourceField`
    proc `settarget` *(self:`sourceOwner`, value: `T`){.inject.}=
      if self.`sourceField`!=nil:
        self.`sourceField`.remove(self)
      if value!=nil:
        value.add(self)
  # hint repr result

    
    
  
    