require_relative "../class/instpath_helper.rb"
class AxesInstance
	MINSCALE = 0.001
	COLOR_POINT = "black"
	COLOR_XAXIS = "red"
	COLOR_YAXIS = "green"
	COLOR_ZAXIS = "blue"
	COLOR_FACES = "white"
	COLOR_EDGES = "gray"
	def initialize()
		clear
	end
	def clear
		@@confirm_origin = false
		@@confirm_x_axis = false
		@@confirm_y_axis = false
		@@confirm_z_axis = false
		@@confirm_place = false
		@@current_point = Geom::Point3d.new([0,0,0])
		@@origin = Geom::Point3d.new([0,0,0])
		@@x_axis = Geom::Vector3d.new([1,0,0])
		@@y_axis = Geom::Vector3d.new([0,1,0])
		@@z_axis = Geom::Vector3d.new([0,0,1])
		@@x_scale = 1.0
		@@y_scale = 1.0
		@@z_scale = 1.0
		@@trans  = Geom::Transformation.new
	end
	def get_definition()
		defname = UI.inputbox(["放置组件"],[""],[Sketchup.active_model.definitions.map(&:name).join("|")],"选择组件").first
		return defname == "" ? nil : Sketchup.active_model.definitions[defname]
	end
	def refresh_origin()
		@@origin = @@current_point
	end
	def refresh_x_axis()
		vec = @@current_point - @@origin
		@@x_scale = vec.length / @@definition.bounds.width
		@@x_scale = MINSCALE if @@x_scale < MINSCALE
		@@x_axis = vec
	end
	def refresh_y_axis()
		vec = @@current_point - @@origin
		@@y_scale = vec.length / @@definition.bounds.height
		@@y_scale = MINSCALE if @@y_scale < MINSCALE
		@@y_axis = vec
	end
	def refresh_z_axis()
		vec = @@current_point - @@origin
		@@z_scale = vec.length / @@definition.bounds.depth
		@@z_scale = MINSCALE if @@z_scale < MINSCALE
		@@z_axis = vec
	end
	def refresh_trans()
		te = Geom::Transformation.new
		return te if @@x_axis.length == 0
		return te if @@y_axis.length == 0
		return te if @@z_axis.length == 0
		ts = Geom::Transformation.scaling(@@x_scale, @@y_scale, @@z_scale)
		ta = Geom::Transformation.axes(@@origin, @@x_axis, @@y_axis, @@z_axis)
		@@trans = ta * ts
	end
	def do_place()
		Sketchup.active_model.start_operation("三轴组件放置工具")
		Sketchup.active_model.active_entities.add_instance(@@definition, @@trans)
		Sketchup.active_model.commit_operation()
	end
	def activate()
		@@definition = get_definition()
		clear
	end
	def onMouseMove(flags,x,y,view)
		ip = view.inputpoint(x,y)
		@@current_point = ip.position
		if not @@confirm_origin then
			refresh_origin()
		elsif not @@confirm_x_axis then
			refresh_x_axis()
		elsif not @@confirm_y_axis then
			refresh_y_axis()
		elsif not @@confirm_z_axis then
			refresh_z_axis()
		end
		refresh_trans()
		draw(view)
	end
	def onLButtonUp(flags,x,y,view)
		ip = view.inputpoint(x,y)
		@@current_point = ip.position
		if not @@confirm_origin then
			@@confirm_origin = true
		elsif not @@confirm_x_axis then
			@@confirm_x_axis = true
		elsif not @@confirm_y_axis then
			@@confirm_y_axis = true
		elsif not @@confirm_z_axis then
			@@confirm_z_axis = true
			do_place()
			clear
		end
		refresh_trans
		draw(view)
	end
	def onCancel(reason, view)
		clear
	end
	def getExtents
		bb = Geom::BoundingBox.new
		0.upto(7).each{|i|
			bb.add(@@definition.bounds.corner(i).transform(@@trans))
		}
		return bb
	end
	def draw_definition(view, face_color="white", edge_color="black")
		paths = InstancePathTree.check_subordinate(@@definition).subordinates
		paths.reject!{|ent|ent.leaf.hidden?}
		edge_paths = paths.clone
		face_paths = paths
		face_paths.select!{|path|path.leaf.is_a?(Sketchup::Face)}
		edge_paths.select!{|path|path.leaf.is_a?(Sketchup::Edge)}
		if face_color.downcase != "none" then
			view.drawing_color = face_color
			face_paths.each{|path|
				face = path.leaf
				ms = face.mesh
				vs = ms.polygons.map{|tri|tri.map{|idx|ms.point_at(idx.abs)}}
				tr = @@trans * path.transformation
				vs.map!{|tri|tri.map{|v|tr*v}}
				vs.flatten!
				view.draw(GL_TRIANGLES, vs, normals:[face.normal]*vs.length)
			}
		end
		if edge_color.downcase != "none" then
			view.drawing_color = edge_color
			edge_paths.each{|path|
				v1 = path.leaf.start.position
				v2 = path.leaf.end.position
				tr = path.transformation
				view.draw_polyline(v1.transform(@@trans*tr),v2.transform(@@trans*tr))
			}
		end
	end
	def draw(view)
		view.line_width = 2
		draw_definition(view, COLOR_FACES, COLOR_EDGES)
		if not @@confirm_origin then
			Sketchup.set_status_text("点击确定原点。", SB_PROMPT)
			view.draw_points(@@current_point, 6, 1, COLOR_POINT)
		else
			view.line_width = 5
			if not @@confirm_x_axis then
				Sketchup.set_status_text("点击确定X轴。", SB_PROMPT)
				view.drawing_color = COLOR_XAXIS
			elsif not @@confirm_y_axis then
				Sketchup.set_status_text("点击确定Y轴。", SB_PROMPT)
				view.drawing_color = COLOR_YAXIS
			elsif not @@confirm_z_axis then
				Sketchup.set_status_text("点击确定Z轴。", SB_PROMPT)
				view.drawing_color = COLOR_ZAXIS
			else
				view.line_width = 0
			end
			view.draw_polyline(@@origin, @@current_point)
			view.draw_points(@@origin, 6, 2, COLOR_POINT)
			view.draw_points(@@current_point, 6, 1, COLOR_POINT)
		end
		view.invalidate
	end
end