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
		unless w.samedirection?(input_w)
			warn "警告：给定的axes[3]不与前两轴正交，已经重新计算并替换"
		end
		@axes = [u, v, w]
		@lengths = lengths.map(&:to_f)
	end
	
	def create_by_vertex(vert)
		initialization(origin:vert.position, axes:[[1,0,0],[0,1,0],[0,0,1]], lengths:[0,0,0])
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
	end
	def create_by_entities(ents)
		return nil if ents.empty?
		rest_of_elems = ents.to_a
		groups,    rest_of_elems = rest_of_elems.partition{|i|i.is_a?(Sketchup::Group)}
		instances, rest_of_elems = rest_of_elems.partition{|i|i.is_a?(Sketchup::ComponentInstance)}
		faces,     rest_of_elems = rest_of_elems.partition{|i|i.is_a?(Sketchup::Face)}
		edges,     rest_of_elems = rest_of_elems.partition{|i|i.is_a?(Sketchup::Edge)}
		edges.select!{|edge|(edge.faces&faces).empty?}
		ordered_ents = groups + instances + faces + edges
		p ordered_ents
		res = ordered_ents.map{|ent|RotatedBoundingBox.new(ent)}.inject(&:add_rbound)
		@origin  = res.origin
		@axes    = res.axes
		@lengths = res.lengths
	end
	
	def initialize(entity_of_array)
		clear
		case entity_of_array
			when Sketchup::Vertex then create_by_vertex(entity_of_array)
			when Sketchup::Edge then create_by_edge(entity_of_array)
			when Sketchup::Face then create_by_face(entity_of_array)
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

	def volume
		return 0 if empty?
		@lengths.reduce(:*)
	end

	def contains_point?(point)
		raise TypeError, "point must be point-like" unless point.respond_to?(:to_a)
		return false if empty?
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
end
