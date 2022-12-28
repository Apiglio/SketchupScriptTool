#建筑建模脚本辅助
#arh.rb
#by Apiglio


module Arh
	
	
	def self.add_instace_with_line(line,definition)
		raise ArgumentError.new("给定的向量不能垂直于水平面") if line[1].parallel?([0,0,1])
		x_axis = line[1]
		z_axis = [0,0,1]
		y_axis = z_axis.cross(x_axis)
		xscale = x_axis.length / definition.bounds.width
		trans = Geom::Transformation.axes(line[0],x_axis,y_axis,z_axis) * Geom::Transformation.scaling(xscale,1,1)
		Sketchup.active_model.entities.add_instance(definition,trans)
	end
	def self.add_instace_between_points(p1,p2,definition)
		ptr1=Geom::Point3d.new(p1)
		ptr2=Geom::Point3d.new(p2)
		add_instace_with_line([ptr1,ptr2-ptr1],definition)
	end
	
	module BuildTool
		
		class Wall
		
			# genWall = UI::Command.new("绘制墙"){Sketchup.active_model.select_tool(Arh::BuildTool::Wall.new)}
			# genWall.menu_text = "Wall Gen"
			# genWall.set_validation_proc {Sketchup.active_model.tools.active_tool.is_a?(Arh::BuildTool::Wall) ? MF_GRAYED : MF_ENABLED}
			# arh_tb = UI::Toolbar.new("Apiglio Arh 工具")
			# genWall.tooltip = "Test Toolbars"
			# genWall.status_bar_text = "Testing the toolbars class"
			# genWall.menu_text = "Test"
			# arh_tb = arh_tb.add_item(genWall)
			# arh_tb.show
			
			def activate
				@point1 = [0,0,0]
				@point2 = [0,0,0] #始终表示鼠标指针的位置
				@thickness  = 100.mm
				@point3 = nil
				@point4 = nil
				@state  = 0 # 0-未选择  1-已选择一个点
			end
			def do_wall
				d = Sketchup.active_model.definitions["墙"]
				if d.nil? then
					puts "没有找到名称为“墙”的组件，不能绘制墙。"
				else
					Sketchup.active_model.start_operation("放置墙体",false)
					Arh.add_instace_between_points(@point1,@point2,d)
					Sketchup.active_model.commit_operation()
				end
			end
			def onLButtonUp(flags,x,y,view)
			# 左键选择第一个点或创建墙体
				case @state
				when 0
					ip = view.inputpoint(x,y)
					@point1 = ip.position
					@point3 = nil
					@state = 1
				when 1
					do_wall
					@state = 0
				end
			end
			def onCancel(reason, view)
			# 左键选择第一个点或创建墙体
				@state = 0
			end
			def onMouseMove(flags,x,y,view)
				ip = view.inputpoint(x,y)
				@point2 = ip.position
				if @state == 1 then
					x_vec = @point2 - @point1
					if x_vec.length==0 or x_vec.parallel?([0,0,1]) then
						@point3 = nil
					else
						y_vec = [0,0,1].cross(x_vec)
						y_vec.length = @thickness
						@point3 = @point2+y_vec
						@point4 = @point1+y_vec
					end
				end
				draw(view)
			end
			def getExtents
				bb = Geom::BoundingBox.new
				bb.add(@point1,@point2,@point3,@point4) unless @point3.nil?
				return bb
			end
			def draw(view)
				if @state == 1 then
					view.drawing_color="red"
					view.line_width=2
					if @point3.nil?
						view.draw_text(view.screen_coords(@point2+[24,24,0]),"不能创建垂直与平面的墙体")
					else
						view.draw_polyline(@point1,@point2,@point3,@point4,@point1)
						view.draw_text(view.screen_coords(@point2+[24,24,0]),"L:#{(@point1-@point2).length.to_mm.round(3)}mm\nW:#{@thickness.to_mm.round(3)}mm")
					end
				end
				view.draw_points(@point2,6,2,"black")
				view.invalidate
			end
		end
		
		def self.line_to_wall(ll,depth,height)
			ArgumentError.new("Sketchup::Edge is expected but #{ll.class} found.") unless ll.is_a?(Sketchup::Edge)
			p1=ll.start.position
			p2=ll.end.position
			vert_vec=ll.line[1].cross([0,0,-1])
			vert_vec.length=depth
			p3=p1+vert_vec
			p4=p2+vert_vec
			ents=ll.parent.entities
			ents.add_line(p2,p4)
			ents.add_line(p4,p3)
			ents.add_line(p3,p1)
			f=ents.add_face(p1,p2,p4,p3)
			f.pushpull(-height)
			ents.add_group(f.all_connected)
			#群组坐标轴需要修改
		end
	end
	
end
