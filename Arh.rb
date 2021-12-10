#建筑建模脚本辅助
#arh.rb
#by Apiglio


module Arh

	module BuildTool
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
