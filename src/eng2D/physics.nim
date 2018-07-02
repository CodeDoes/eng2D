import types, transform, spatial, private/utils, typetraits
import macros
import tables,hashes

type 
  Drag= float
  VelocityModule[K] = object
    delta*: K
    drag*: Drag
  LinearVelocity = VelocityModule[Vec2]
  AngularVelocity = VelocityModule[Angle]

type Velocity* = ref object of Component
  linear*: LinearVelocity
  angular*: AngularVelocity
proc new*(_:type Velocity):Velocity=
  system.new result
  result.linear.delta=(0.0,0.0)

proc hash*(self:Entity):Hash=
  return hash(self[].addr.pointer)
proc hash*(self:NimNode):Hash=
  # good enough for my use case
  return hash(self.repr())
template watchFor*(
      Sys:typed,
      partial:untyped,
      complete:untyped,
      f:untyped,
      T:typed
      ):untyped=
  
  {.push.}
  {.this: self.}
  method add*(
        self:Sys,
        comp:T) {.inject.} =
    var data = partial.getOrDefault(comp.owner)
    
    data.f = comp
    partial[comp.owner]=data
    block complete_scope:
      for v in data.fields:
        if not(v!=nil): break complete_scope
      complete[comp.owner] = data
    
  method remove*(
        self:Sys,
        comp:T) {.inject.} =
    var data = partial.getOrDefault(comp.owner)
    data.f = nil
    if comp.owner in complete:
      complete.del(comp.owner)
    partial[comp.owner] = data
    block empty_scope:
      for v in data.fields:
        if v!=nil: break empty_scope
      partial.del(comp.owner)
  {.pop.}

type 
  Collection*[K; D: Data] = tuple
    keyType: K
    dataType: D
    partial: TableRef[K, seq[D]]
    complete: TableRef[K, seq[D]]
  Data* = object of RootObj
  VelocitySystemData* = ref object of Data
    velocity: Velocity
    transform: Transform
  VelocitySystemCollection* = Collection[Entity, VelocitySystemData]
proc new[C: Collection](_:type C):C=
  new result
  result.partial= newTable[C.K,seq[C.D]]()
  result.complete= newTable[C.K,seq[C.D]]()

type VelocitySystem* = ref object of System
  m_vel_partial:TableRef[Entity,VelocitySystemData]
  m_vel_complete:TableRef[Entity,VelocitySystemData]
proc new*(_:type VelocitySystem):VelocitySystem=
  system.new result
  result.m_vel_partial = newTable[Entity,VelocitySystemData]()
  result.m_vel_complete = newTable[Entity,VelocitySystemData]()
# TODO container delegate 
# VelocitySystem.watchFor( 
#   m_vel_partial, m_vel_complete, 
#   transform, Transform)
# VelocitySystem.watchFor( 
#   m_vel_partial, m_vel_complete, 
#   velocity, Velocity)

macro delegate*#[]#(x: type Collection#[,name:untyped]#):untyped=
  # hint astGenRepr x.symbol.getImpl()
  hint astGenRepr x.getType()
  hint astGenRepr x.getTypeImpl()
  hint astGenRepr x.getTypeInst()
  hint astGenRepr x.getTypeInst()[1].symbol.getImpl()

  let 
    tyImpl = x.getTypeInst()[1].symbol.getImpl()
    ty = tyImpl[0]
    tyBody = tyImpl[2]
  # return newStmtList()
  #[
  ]#
  let 
    add_name = "add".ident #genSym(nskMethod, "add_method")
    rem_name = "rem".ident #genSym(nskMethod, "rem_method")
    input = "input".ident
    data = "data".ident
    I = genSym(nskType, "I")
    K = tyBody[1]
    T = tyBody[2]
    c = genSym(nskVar, "c")
  # hint repr x.getTypeInst()[1][2]
  hint astGenRepr x.getTypeInst()[1]
  hint astGenRepr T.symbol.getImpl()[2]
  
  result = quote do:
    type
      `I` = object
    var `c`:`ty`
  var base_add_method = newProc(
    add_name.postfix("*"),
    [ bool.getType(),
      newIdentDefs("_".ident,I),
      newIdentDefs(input, "Component".ident),
      newIdentDefs(data, nnkVarTy.newTree(T))
    ],
    quote do:
      echo "empty!"
      false
    ,
    nnkMethodDef
  )
  base_add_method.addPragma("base".ident)
  var base_rem_method = base_add_method.copy()
  base_rem_method[0] = rem_name.postfix("*")
  result.add newStmtList(base_add_method, base_rem_method)

  # base_method.addPragma("inject".ident)
  var ts = newTable[NimNode, seq[NimNode]]()
  var IdDefs = T.symbol.getImpl()[2]
  for t in IdDefs:
    var td = ts.mgetOrPut(t[1], newSeq[NimNode]())
    td.add(t)

  # result.body.add quote do:
  for idT,idNs in ts:
    let idTstr = newLit(repr idT)
    hint astGenRepr idT
    var add_method = base_add_method.copy()
    add_method.params[2][1]=idT
    add_method.pragma=newEmptyNode()
    add_method.body = quote do:
      # system.echo("checking - ", `idNtext`)
      # system.echo("added - ", `idTstr`)
      true
    result.add add_method
    # block remove:
    var rem_method = add_method.copy()
    rem_method[0] = base_rem_method[0]
    rem_method.body = quote do:
      # system.echo("checking - ", `idNtext`)
      # `data`.`idN` = nil
      # system.echo("removed - ", `idTstr`)
      true
    for idN in idNs:
      let idNstr = newLit(repr idN)
      add_method.body.insert 0, quote do:
        system.echo("set - ", `idNstr`)
        `data`.`idN` = `input`
    for idN in idNs:
      let idNstr = newLit(repr idN)
      add_method.body.insert 0, quote do:
        system.echo("unset - ", `idNstr`)
        `data`.`idN` = nil
    result.add rem_method
  
  # var
  #   add_method_call = newCall(add_name,input,data)
  #   rem_method_call = newCall(rem_name,input,data)
    # interface_add_name = genSym(nskProc,"add_interface")
    # interface_rem_name = genSym(nskProc,"rem_interface")
    # I = "I".ident
    # add_method_call_type = add_method_call.getType
  # hint astGenRepr quote do:
    
    #[ 
    ]#

  # hint astGenRepr result
  
  result.add quote do:
    let i = `I`()
    i
  hint astGenRepr result
  hint repr result
  #[]#
  # for k,v in T.symbol.getImpl():
# echo astGenRepr VelocitySystem.m_vel_partial.delegate()
proc isComplete(data: VelocitySystemData):bool=
  for k,v in data.fieldPairs:
    if v.isNil(): return false
  return true
proc isEmpty(data: VelocitySystemData):bool=
  for k,v in data.fieldPairs:
    if not v.isNil(): return false
  return true


# const vel_delegate = VelocitySystemCollection.delegate
VelocitySystemCollection.delegate

context VelocitySystem:
  # proc isComplete(data: VelocitySystemData):bool=
  #   for k,v in data.fieldPairs:
  #     if v.isNil(): return false
  #   return true
  # proc isEmpty(data: VelocitySystemData):bool=
  #   for k,v in data.fieldPairs:
  #     if not v.isNil(): return false
  #   return true
  # TODO Api change I.add(_:I,comp:Component,data:var Data):bool
  method add(comp: Component)=
    # echo "added comp ", comp.type.name
    discard
    # var data = self.m_vel_partial.getOrDefault(comp.owner)
    
    # if vel_delegate.add(comp, data):
    #   if not isEmpty(data):
    #     self.m_vel_partial[comp.owner] = data
    #   if isComplete(data):
    #     echo "is complete!!!"
    #     self.m_vel_complete[comp.owner] = data
  method remove(comp:Component) = 
    # echo "removed comp ", comp.type.name
    discard
    # var data = self.m_vel_partial.getOrDefault(comp.owner)
    
    # if vel_delegate.rem(comp, data):
    #   if comp.owner in self.m_vel_partial and isEmpty(data):
    #     self.m_vel_partial.del(comp.owner)
    #   else:
    #     self.m_vel_partial[comp.owner] = data
    #     if comp.owner in self.m_vel_complete:
    #       self.m_vel_complete.del(comp.owner)
  method step(dt: float)=
    for ent,data in m_vel_complete:
      # echo "b ", repr(data.transform.local.pos)
      data.transform.local.pos = 
        data.transform.local.pos +
        data.velocity.linear.delta * dt
# TODO better syntax: watchSystemContainer VelocitySystem.m_vel_comps
# TODO make it modifiable.

