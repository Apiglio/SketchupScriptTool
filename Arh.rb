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
	
	module Stories
		#在block中计算层高并创建多层建筑草模
		#目前faces不能在群组内，pushpull会将面放到原点，之后改current_path解决
		#Arh::Stories.pushpull_stories_by_faces(fs, 3.m){|face|face.get_attribute("EsriJSONAttribute", "层数")}
		def self.pushpull_stories_by_faces(faces, height_of_stories, &block)
			raise ArgumentError.new("faces must in Model instead of in Definition") unless faces.map{|f|f.parent.class}.uniq==[Sketchup::Model]
			model = Sketchup.active_model
			ppCopy = true
			soDisableUI = true
			Sketchup.active_model.start_operation("Pushpull Stories by Faces", soDisableUI)
			begin
				total_count = 0
				faces.each{|face|
					number_of_stories = block.call(face)
					next if number_of_stories<1
					grp = model.entities.add_group(face)
					bottom = grp.definition.entities.grep(Sketchup::Face)[0]
					bottom.pushpull(-height_of_stories*number_of_stories, ppCopy)
					floor = grp.definition.entities.add_group(bottom)
					floor.move!(grp.transformation)
					parts = [grp, floor]
					1.upto(number_of_stories-1){|floor_number|
						nf = floor.copy
						nf.move!(grp.transformation*Geom::Transformation.translation([0, 0, floor_number*height_of_stories]))
						parts << nf
					}
					building = model.entities.add_group(parts)
					# 把面要素属性复制给群组
					face.attribute_dictionaries.entries.each{|entry|
						entry.to_h.each{|k,v|
							building.set_attribute(entry.name, k, v)
						}
					}
					total_count += 1
				}
			rescue
				Sketchup.active_model.abort_operation()
				raise RuntimeError.new("Pushpull Stories Error")
			end
			Sketchup.active_model.commit_operation()
			return total_count
		end
	end
	
	module Roofs
		#根据给定的平面和确定的屋顶坡度创建山墙屋顶
		#如果face不是四边形则报错
		def self.build_gable_by_pitch(face, pitch_angle)
			edgeuses = face.loops[0].edgeuses
			raise RuntimeError.new("GableRoof: expected exactly 4 edges") unless edgeuses.count==4
			longest_eu = edgeuses.max_by{|eu|eu.edge.length}
			b1 = longest_eu.previous.edge
			b2 = longest_eu.next.edge
			p1 = longest_eu.edge.start
			p2 = longest_eu.edge.end
			p1,p2 = p2,p1 if longest_eu.reversed?
			p0 = b1.other_vertex(p1)
			p3 = b2.other_vertex(p2)
			m1 = Geom.linear_combination(0.5, p1.position, 0.5, p0.position)
			m2 = Geom.linear_combination(0.5, p2.position, 0.5, p3.position)
			h1 = Math.tan(pitch_angle)*b1.length/2.0
			h2 = Math.tan(pitch_angle)*b2.length/2.0
			r1 = m1 + [0,0,h1]
			r2 = m2 + [0,0,h2]
			face.parent.entities.build{|builder|
				builder.add_face(r1, p1, p0)
				builder.add_face(r2, p3, p2)
				builder.add_edge(r1, p2).hidden = true
				builder.add_edge(r1, p3).hidden = true
				builder.add_face(r1, p2, p1)
				builder.add_face(r1, r2, p2)
				builder.add_face(r1, p0, p3)
				builder.add_face(r1, p3, r2)
			}
		end
	end
end
