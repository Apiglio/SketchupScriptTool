# RotatedBoundingBox.rb
# Minimal oriented bounding box with canonical sorted lengths and third axis validation
# plus add_point and make_box methods respecting axis-length mapping
#test-1
#t=RotatedBoundingBox.new(origin:[0,0,0],axes:[[1,0,0],[0,1,0],[0,0,1]],lengths:[1.m,1.m,1.m])
#t.contains_point?([0.5.m,0.5.m,0.5.m])
class RotatedBoundingBox
	attr_reader :origin, :axes, :lengths
	
	def initialization(origin:, axes:, lengths:)
		# origin: 原点
		# axes: [u_vector, v_vector, w_vector]    w_vector为可选项，可验证正交
		# lengths: [l1, l2, l3]  遇到负数时平移原点
		# 轴和长度序号一一对应不能随意更改顺序
		raise ArgumentError.new("axes应包含三个向量") unless axes.is_a?(Array) && axes.size == 3
		raise ArgumentError.new("lengths应包含三个数值") unless lengths.is_a?(Array) && lengths.size == 3
		@origin = Geom::Point3d.new(origin)
		u = Geom::Vector3d.new(axes[0]).normalize
		v = Geom::Vector3d.new(axes[1]).normalize
		w = u.cross(v).normalize
		raise ArgumentError.new("axes[0]和axes[1]应不共线") if w.to_a.all?(&:zero?)
		input_w = Geom::Vector3d.new(axes[2]).normalize
		# unless w.samedirection?(input_w)
			# warn "警告：给定的axes[3]不与前两轴正交，已经重新计算并替换"
		# end
		@axes = [u, v, w]
		@lengths = lengths.map(&:to_f)
	end
	
	def create_by_vertex(vert)
		initialization(origin:vert.position, axes:[[1,0,0],[0,1,0],[0,0,1]], lengths:[0,0,0])
		self
	end
	
	def create_by_edge(edge)
		u = edge.line[1]
		if u.parallel?([0,0,1]) then
			v=[1,0,0]
			w=[0,1,0]
		else
			w=[0,0,1]
			v=u.cross(w)
		end
		initialization(origin:edge.line[0], axes:[u,v,w], lengths:[edge.length,0,0])
	end
	
	def create_by_face(face)
		w = face.normal
		edgeuses = face.loops[0].edgeuses
		longest_eu = edgeuses.max_by{|eu|eu.edge.length}
		u = longest_eu.edge.line[1]
		v = u.cross(w)
		p = longest_eu.reversed? ? longest_eu.edge.end : longest_eu.edge.start
		initialization(origin:p.position, axes:[u,v,w], lengths:[0,0,0])
		face.vertices.each{|v|self.add_point(v.position)}
		self
	end
	
	def create_by_group(group)
		g_bbox = group.definition.bounds
		g_orig = Geom::Point3d.new(g_bbox.min)
		g_axes = [
			Geom::Vector3d.new(g_bbox.width, 0, 0),
			Geom::Vector3d.new(0, g_bbox.height, 0),
			Geom::Vector3d.new(0, 0, g_bbox.depth)
		]
		@origin = group.transformation*g_orig
		@axes = g_axes.map{|axis|group.transformation*axis}
		@lengths = @axes.map{|axis|Geom::Vector3d.new(axis).length}
		@axes.map!{|axis|axis.normalize}
		self
	end
	
	def create_by_entities(ents)
		return nil if ents.empty?
		rest_of_elems = ents.to_a
		groups,    rest_of_elems = rest_of_elems.partition{|i|i.is_a?(Sketchup::Group)}
		instances, rest_of_elems = rest_of_elems.partition{|i|i.is_a?(Sketchup::ComponentInstance)}
		faces,     rest_of_elems = rest_of_elems.partition{|i|i.is_a?(Sketchup::Face)}
		edges,     rest_of_elems = rest_of_elems.partition{|i|i.is_a?(Sketchup::Edge)}
		inst_n_grp = groups+instances
		inst_n_grp.sort_by!{|g|
			b = g.definition.bounds
			t = g.transformation
			# 这里需要动态组件的x/y/zscale方法
			- b.width * b.height * b.depth * t.xscale * t.yscale * t.zscale
		}
		faces.sort_by!{|f|-f.area}
		edges.select!{|edge|(edge.faces&faces).empty?}
		ordered_ents = inst_n_grp + faces + edges
		res = ordered_ents.map{|ent|RotatedBoundingBox.new(ent)}.inject(&:add_rbound)
		@origin  = res.origin
		@axes    = res.axes
		@lengths = res.lengths
		self
	end
	
	def initialize(entity_of_array)
		clear
		case entity_of_array
			when Sketchup::Vertex then create_by_vertex(entity_of_array)
			when Sketchup::Edge then create_by_edge(entity_of_array)
			when Sketchup::Face then create_by_face(entity_of_array)
			when Sketchup::ComponentInstance, Sketchup::Group then create_by_group(entity_of_array)
			when Array then create_by_entities(entity_of_array)
			else nil
		end
	end
	
	def clear
		@origin = nil
		@axes = nil
		@lengths = [-Float::INFINITY, -Float::INFINITY, -Float::INFINITY]
	end
	
	def empty?
		@origin.nil? || @lengths.all?{|l|l<=0}
	end
	
	def valid?
		!empty?
	end
	
	def corner(i)
		raise "box is empty" if empty?
		dx = (i & 1) != 0 ? @lengths[0] : 0
		dy = (i & 2) != 0 ? @lengths[1] : 0
		dz = (i & 4) != 0 ? @lengths[2] : 0
		dx_vec = Geom::Vector3d.new(@axes[0].to_a.map{|c|c*dx})
		dy_vec = Geom::Vector3d.new(@axes[1].to_a.map{|c|c*dy})
		dz_vec = Geom::Vector3d.new(@axes[2].to_a.map{|c|c*dz})
		@origin + dx_vec + dy_vec + dz_vec
	end
	
	LineVertexIndice = [
		[0, 1], [1, 3], [3, 2], [2, 0],
		[4, 5], [5, 7], [7, 6], [6, 4],
		[0, 4], [1, 5], [3, 7], [2, 6]
	].freeze
	def line(i)
		LineVertexIndice[i].tap{|i,j|
			a = corner(i)
			b = corner(j)
			return [a, b-a]
		}
	end
	
	def plane(i)
		min_point = @origin.to_a
		max_point = corner(7).to_a
		get_plane = proc{|orig,axis|[*(axis.to_a),-axis.to_a.zip(orig.to_a).sum{|i|i.inject(&:*)}]}
		case i
			when 0 then get_plane.call(min_point, @axes[2])
			when 1 then get_plane.call(min_point, @axes[0])
			when 2 then get_plane.call(max_point, @axes[1].to_a.map(&:-@))
			when 3 then get_plane.call(max_point, @axes[0].to_a.map(&:-@))
			when 4 then get_plane.call(min_point, @axes[1])
			when 5 then get_plane.call(max_point, @axes[2].to_a.map(&:-@))
		end
	end
	
	def center
		@origin +
		Geom::Vector3d.new(@axes[0].to_a.map{|c| c * @lengths[0] * 0.5}) +
		Geom::Vector3d.new(@axes[1].to_a.map{|c| c * @lengths[1] * 0.5}) +
		Geom::Vector3d.new(@axes[2].to_a.map{|c| c * @lengths[2] * 0.5})
	end
	
	def volume
		return 0 if empty?
		@lengths.reduce(:*)
	end
	
	def coordinate_system
		@axes[2].dot(@axes[0].cross(@axes[1]))
	end
	
	def dimension_rank
		3-@lengths.count(&:zero?)
	end
	
	def parallel?(rbb)
		@axes.zip(rbb.axes).all?{|axis_pair|axis_pair[0].parallel?(axis_pair[1])}
	end
	
	def contains_point?(point)
		p = Geom::Point3d.new(point)
		vec = p - @origin
		dx = vec.dot(@axes[0])
		dy = vec.dot(@axes[1])
		dz = vec.dot(@axes[2])
		dx.between?(0, @lengths[0]) && dy.between?(0, @lengths[1]) && dz.between?(0, @lengths[2])
	end
	
	def add_point(point)
		raise TypeError, "point must be point-like" unless point.respond_to?(:to_a)
		newpoint     = Geom::Point3d.new(point)
		pos_origin   = @axes.map{|axis|axis.dot(@origin.to_a)}
		pos_newpoint = @axes.map{|axis|axis.dot(newpoint.to_a)}
		3.times.each{|i|
			offset = pos_newpoint[i] - pos_origin[i]
			if offset>@lengths[i] then
				@lengths[i] = offset
			elsif offset<0 then
				@lengths[i] -= offset
				origin_offset = Geom::Vector3d.new(@axes[i])
				origin_offset.length = offset
				@origin += origin_offset
			end
		}
		self
	end
	
	def add_rbound(rbound)
		8.times{|i|self.add_point(rbound.corner(i))}
		self
	end
	
	def make_box
		return nil if empty?
		model = Sketchup.active_model
		grp = model.entities.add_group
		c = 8.times.map {|i|corner(i)}
		
		if (@lengths[0]*@lengths[1]).abs > 1e-3 then
			grp.entities.add_face(c[0], c[1], c[3], c[2])                       # bottom
			grp.entities.add_face(c[4], c[5], c[7], c[6]) unless @lengths[2]==0 # top
		end
		
		if (@lengths[0]*@lengths[2]).abs > 1e-3 then
			grp.entities.add_face(c[0], c[1], c[5], c[4])                       # front
			grp.entities.add_face(c[2], c[3], c[7], c[6]) unless @lengths[1]==0 # back
		end
		
		if (@lengths[1]*@lengths[2]).abs > 1e-3 then
			grp.entities.add_face(c[1], c[3], c[7], c[5])                       # right
			grp.entities.add_face(c[0], c[2], c[6], c[4]) unless @lengths[0]==0 # left
		end
		
		grp
	end
	
	def norm_by!(rbb)
		raise ArgumentError.new("RotatedBoundingBox expected") unless rbb.is_a?(RotatedBoundingBox)
		return self if empty? || rbb.empty?
		used = [false,false,false]
		new_axes    = [0,0,0]
		new_lengths = [0,0,0]
		origin_shift = Geom::Vector3d.new(0,0,0)
		rbb.axes.each_with_index{|ref_axis, i|
			best_j   = nil
			best_dot = -1.0
			@axes.each_with_index do |ax, j|
				next if used[j]
				d = ax.dot(ref_axis).abs
				if d > best_dot
					best_dot = d
					best_j   = j
				end
			end
			used[best_j] = true
			ax  = @axes[best_j]
			len = @lengths[best_j]
			if ax.dot(ref_axis) < 0
				origin_shift += Geom::Vector3d.new(ax.to_a.map{|c|c*len})
				ax = Geom::Vector3d.new(ax.to_a.map{|c|-c})
			end
			new_axes[i]    = ax
			new_lengths[i] = len
		}
		@origin  += origin_shift
		@axes     = new_axes
		@lengths  = new_lengths
		self
	end
	
	def norm_by(rbb)
		dup.tap{|b|b.norm_by!(rbb)}
	end
	
	def align_to(rbb, vector)
		# 返回当前范围朝vector方向和给定rbb对齐所需要的平移变换
		raise ArgumentError unless rbb.is_a?(RotatedBoundingBox)
		raise ArgumentError.new("RotatedBoundingBoxes should be parallel") unless parallel?(rbb)
		d = Geom::Vector3d.new(vector).normalize
		idx = @axes.find_index {|a|a.parallel?(d)}
		raise ArgumentError.new("vector must be parallel to both RotatedBoundingBoxes") unless idx
		sign = @axes[idx].dot(d) > 0 ? 1 : -1
		dir  = Geom::Vector3d.new(d.to_a.map{|c|c*sign})
		s_self = 8.times.map {|i|Geom::Vector3d.new(corner(i).to_a).dot(dir)}.min
		s_rbb  = 8.times.map {|i|Geom::Vector3d.new(rbb.corner(i).to_a).dot(dir)}.min
		delta = s_rbb - s_self
		Geom::Transformation.translation(dir.to_a.map{|c|c*delta})
	end
	
	def twist_to(rbb)
		# 返回当前范围通过角度微调达到给定rbb所需要的旋转变换
		raise ArgumentError unless rbb.is_a?(RotatedBoundingBox)
		ct = center
		axes_self = @axes.clone
		axes_give = rbb.axes.clone
		axis_pairs = Array.new(3).map.with_index{|elem,i|
			best_axis = axes_give.max_by{|a|a.dot(axes_self[i])}
			axes_give.delete(best_axis)
			[axes_self[i], best_axis]
		}
		t1 = Geom::Transformation.axes(ct, *axis_pairs.map(&:first))
		t2 = Geom::Transformation.axes(ct, *axis_pairs.map(&:last))
		t2 * t1.inverse
	end
	
	def knock_to(rbb, vector)
		# 返回当前范围朝vector方向接触到给定rbb所需要的平移变换
		best_plane = 6.times.map{|i|rbb.plane(i)}.min_by{|p|Geom::Vector3d.new(vector).angle_between(p[..2])}
		corners    = 8.times.map{|i|corner(i)}
		prj_pts    = corners.map{|i|i.project_to_plane(best_plane)}
		offsets    = prj_pts.zip(corners).map{|targ,orig|targ-orig}
		raise RuntimeError.new("已经重合或超过目标平面") unless offsets.all?{|vec|vec.dot(vector)>0}
		best_move  = offsets.min_by{|vec|vec.length}
		Geom::Transformation.translation(best_move)
	end
	
	
end
