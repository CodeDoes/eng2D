# eng2D
# Copyright CodeDoes
# 2D Game Engine
import eng2d/[
  types,
  physics,
  transform,
  spatial,
]

block:
  var world = World.new()
  var ent = Entity.new()
  world.add(VelocitySystem.new())
  world.add(ent)
  var velocity = Velocity.new()
  ent.add(velocity)
  var transform = Transform.new()
  ent.add(transform)
  velocity.linear.delta = (1.0, 0.0)
  var runtime = Runtime.new(world)
  echo repr(velocity.linear.delta)
  echo repr(ent.components[0].Velocity.linear.delta)
  echo repr((1.0, 0.0)+(1.0,0.0))
  echo repr(transform.global.pos)
  runtime.step(123123.0)
  echo repr(transform.global.pos)
  
