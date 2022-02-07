# SketchupScriptTool
in SketchUp Ruby Script

**Mov** is for moving entities by axis and by fixed scale
+ only contains one module named Mov


**Sca** is for scaling entities by axis and by fixed scale
+ only contains one module named Sca


**Cge** is for editing component and group
+ module Cge::DC is for dynamic component
+ module Cge::MoveTool is for moving instance(ComponentInstance | Group) by its axis, with a GUI
+ module Cge::Move is for other moving operation such as grouding and aligning
+ module Cge::Deform is for checking whether a instance has a "abnormal" transformation
+ module Cge::Defs is to check or clean DefinitionList


**Sel** is for selection operation
+ module Sel::Width/ Height/ Depth/ Size is for selecting instances by their size, Size is the supermodule
+ module Sel::Edit is for those can modify entities
+ module Sel::Surf is for surface operation


**Arh** is for architecture modelling
+ module Arh::BuildTool is for very basical architecture modelling such as wall building


**Proj** is for projection operation
+ only contains one module named Proj


**Trans** is for some advanced moving operation such as randon moving
+ Trans::Rand is random moving

**Cam** is for camera action
+ only contains one module named Cam yet
