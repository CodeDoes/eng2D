import types, spatial, private/utils
export spatial
type
  Transform* = ref object of Component
    m_parent: Transform
    m_children: seq[Transform]
    m_local_matrix: Matrix
context Transform:
  proc add*(item:Transform)=
    assert item != self
    assert item.m_parent == nil
    item.m_parent = self
    self.m_children.add(item)
  proc remove*(item:Transform)=
    assert item.m_parent == self
    item.m_parent = nil
    self.m_children.remove(item)
Transform.m_parent.owner_property(parent)
context Transform:
  proc local*(): var Matrix =
    self.m_local_matrix
  proc global*(): Matrix =
    # return 
    if self.parent != nil:
      self.parent.global
    else:
      self.local