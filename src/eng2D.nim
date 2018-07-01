# eng2D
# Copyright CodeDoes
# 2D Game Engine
import class_macro
import math
proc remove[T](self:var seq[T],val:T)=
  self.del(self.find(val))

class:
  System* of RootObj:
    var
      m_world: World
    proc world*():auto=self.m_world
    method add(component: Component){.base.}=
      discard
    method remove(component: Component){.base.}=
      discard
  World* of RootObj:
    var 
      m_entities: seq[Entity]
      m_systems: seq[System]
    proc add*(item:System)=
      item.m_world=self
      self.m_systems.add item
    proc add*(item:Entity)=
      item.m_world=self
      self.m_entities.add item
    proc remove*(item:System)=
      item.m_world=self
      self.m_systems.remove item
    proc remove*(item:Entity)=
      item.m_world=self
      self.m_entities.remove item
  Component* of RootObj:
    var 
      m_owner: Entity
    proc owner*():auto=
      return self.m_owner
  Entity* of RootObj:
    var 
      m_components: seq[Component]
      m_world: World
    proc components*():auto=
      self.m_components
  type Interval = float
  Timer* of RootObj:
    var
      interval:Interval
    method step*(dt:Interval){.base.}=
      discard
  ExitOnEscape of Timer:
    method step*(dt:Interval)=
      echo dt
  Runtime* of RootObj:
    var
      timers*: seq[Timer] = @[]
      exit_on_esc = true 

type
  Bounds* = tuple[a:Vec2,b:Vec2]
  AABB* = tuple[min:Vec2,max:Vec2]
  Vec2* = tuple[x:float,y:float]
  Scale* = float
  Angle* = float
  Matrix* = object
    pos*: Vec2
    angle*: Angle
    scale*: Scale
  # Asset* = object of RootObj
  #   path: string
  #   data: cstring
  # Image* = ref object of Asset
  # Map* = ref object of Asset
  # Text* = ref object of Asset
# proc load(self:Asset)=
  
proc `*`*(self:Vec2,scale:float):Vec2=
  return (x: self.x * scale, y: self.y * scale)
proc rotated*(self:Vec2, angle: float):Vec2=
  if angle == 0:
    return self
  let
    rot = degToRad(angle)
    c = cos(rot)
    s = sin(rot)
  return (
    x: self.x * c - self.y * s, 
    y: self.x * s + self.y * c
    )
template elementwise(f)=
  proc f*(a,b:Vec2):Vec2=
    return (
      x: f(a.x,b.x),
      y: f(a.y,b.y)
    )
elementwise `+`
elementwise `-`
elementwise `/`
elementwise `*`

proc `*`*(self:Matrix, point:Vec2):Vec2=
  self.pos + point.rotated(self.angle) * self.scale
proc `*`*(self:Matrix, other:Matrix):Matrix=
  return Matrix(
    pos: self * other.pos,
    angle: self.angle + other.angle,
    scale: self.scale * other.scale
    )
# type 
#   Origin* = enum
#        TopLeft,    TopRight,    TopMiddle,
#     BottomLeft, BottomRight, BottomMiddle, 
#     CenterLeft, CenterRight, CenterMiddle,

class Transform* of Component:
  var 
    m_parent*: Transform
    m_children*: seq[Transform]
    m_local_matrix: Matrix
    # origin= Origin.CenterMiddle
  proc parent*(): auto = self.m_parent
  proc local_matrix*(): Matrix =
    self.m_local_matrix
  proc world_matrix*(): Matrix =
    return 
      if self.parent != nil:
        self.parent.world_matrix
      else:
        self.local_matrix
type 
  Drag= float
  VelocityComponent[K] = object
    velocity: K
    drag: Drag
  LinearVelocity = VelocityComponent[Vec2]
  AngularVelocity = VelocityComponent[Angle]

class Velocity* of Component:
  var 
    transform: Transform
    linear: LinearVelocity
    angular: AngularVelocity

class VelocitySystem of System:
  var
    m_vel_comps = newSeq[Velocity]()
  method add(component:Component)=
    