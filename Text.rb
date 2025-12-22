#与文字、标注相关的功能
#text.rb
#by Apiglio

module ApText
	module EndpointFinder
		def self.centers(ents)
			raise Exception.new("unimplemented")
			# 适用条件如：多个圆柱的圆心间距识别
		end
		def self.parallel_faces(ents, normal, leader_vector)
			# 查找ents中所有垂直于normal的平面
			raise ArgumentError.new('argument ents need to be in one parent.') unless ents.map(&:parent).uniq.length==1
			raise ArgumentError.new('argument normal should be Geom::Vector3d or Array.') unless normal.respond_to?(:cross)
			vec_up = normal.cross(leader_vector)
			raise ArgumentError.new('leader_vector should not be parallel to normal nor a zero vector.') if vec_up.length == 0
			leader_vector = vec_up.cross(normal)
			ents.grep(Sketchup::Face).sort_by{|f|-f.area}
		end
	end
end
