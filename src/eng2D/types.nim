{.push.}
{.this: self.}
import private/utils
import math
from tables import TableRef 


# class:
type
  System* = ref object of RootObj
    m_world: World
  World* = ref object of RootObj
    m_systems: seq[System]
    m_entities: seq[Entity]
  Component* = ref object of RootObj
    m_owner: Entity
  Entity* = ref object of RootObj
    m_components: seq[Component]
    m_world: World
  Runtime* = ref object of RootObj
    m_world: World# = newWorld()

# proc add*(self: World, item: Entity)
# proc remove*(self: World, item: Entity)
# proc add*(self: Entity, comp: Component)
# proc remove*(self: Entity, comp: Component)

# method add*(self: System, component: Component) {.base.}
# method remove*(self: System, component: Component) {.base.}




proc add*(self: World; item: System)
proc remove*(self: World; item: System)
## System
System.m_world.owner_property(world)
context System:
  method add*(component: Component) {.base.} = discard
  method remove*(component: Component) {.base.} = discard
  method step*(dt: float) {.base.} = discard
## World
proc new*(_:type World):World=
  system.new result
  result.m_systems = @[]
  result.m_entities = @[]
World.m_systems.getter(systems)
World.m_entities.getter(entities)
context World:
  proc add*(item:System)=
    assert item.m_world==nil
    item.m_world=self
    m_systems.add item
    for ent in m_entities:
      for comp in ent.m_components:
        item.add(comp)
  proc remove*(item:System)=
    assert item.m_world==self
    item.m_world=nil
    m_systems.remove item
    for ent in m_entities:
      for comp in ent.m_components:
        item.remove(comp)
  proc add*(item:Entity)=
    assert item.m_world==nil
    item.m_world=self
    m_entities.add item
    for sys in m_systems:
      for comp in item.m_components:
        sys.add(comp)
  proc remove*(item:Entity)=
    assert item.m_world==self
    item.m_world=nil
    m_entities.remove item
    for sys in m_systems:
      for comp in item.m_components:
        sys.remove(comp)
  proc add*(item:Component)=
    assert item.m_owner!=nil
    for sys in m_systems:
      sys.add(item)
  proc remove*(item:Component)=
    assert item.m_owner!=nil
    for sys in m_systems:
      sys.remove(item)

## Entity
# constructor Entity.init():
#   m_components = @[]
proc new*(_: type Entity): Entity =
  system.new result
  result.m_components = @[]
Entity.m_world.owner_property(world)
Entity.m_components.getter(components)
context Entity:
  proc add*(comp:Component)=
    assert comp.m_owner == nil
    assert m_components.contains(comp).not
    comp.m_owner=self
    m_components.add(comp)
    if m_world!=nil:
      m_world.add(comp)
  proc remove*(comp:Component)=
    assert comp.m_owner==self
    assert m_components.contains(comp)
    comp.m_owner=nil
    m_components.remove(comp)
    if m_world!=nil:
      m_world.remove(comp)
## Component
Component.m_owner.owner_property(owner)
## Runtime
Runtime.m_world.getter(world)
context Runtime:
  proc init*(world:World)=
    m_world=world
  proc step*(dt:float=1.0)=
    for sys in m_world.m_systems:
      sys.step(dt)
proc new*(_: type Runtime, world: World): Runtime =
  system.new result
  result.m_world = world
{.pop.}