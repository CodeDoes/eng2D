import math
type
  Bounds* = tuple[a: Vec2, b: Vec2]
  AABB* = tuple[min: Vec2, max: Vec2]
  
  Scale* = float
  Angle* = float
  Vec2* = tuple[x:float, y:float]

  Matrix* = tuple
    pos: Vec2
    angle: Angle
    scale: Scale
proc newMatrix*(
      pos: Vec2= (0.0, 0.0),
      angle: Angle= 0.0,
      scale: Scale= 1.0
      ): Matrix =
  return (
    pos: pos,
    angle: angle,
    scale: scale,
  )
proc rotated*(self:Vec2, angle: float): Vec2 {.inline.} =
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

template elementwise(f) =
  proc f*(a, b: Vec2): Vec2 {.inline, inject.} =
    return (
      x: f(a.x, b.x),
      y: f(a.y, b.y)
    )

elementwise `+`
elementwise `-`
elementwise `/`
elementwise `*`

proc `*`*(self:Vec2,scale:float):Vec2{.inline.}=
  return (x: self.x * scale, y: self.y * scale)
proc `*`*(self:Matrix, point:Vec2):Vec2 {.inline.}=
  return self.pos + point.rotated(self.angle) * self.scale

proc `*`*(self:Matrix, other:Matrix):Matrix{.inline.}=
  return (
    pos: self * other.pos,
    angle: self.angle + other.angle,
    scale: self.scale * other.scale
    )
