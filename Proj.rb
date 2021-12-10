#encoding "UTF-8"
#proj.rb
#Apiglio
#这不是一个打包好的插件模块
#只能直接在ruby控制台中通过load来调用
#代码发布在微信公众号Apiglio中

require 'sketchup.rb'

module Proj
	def self.project_to_sphere(point,ori,radius)
		o=Geom::Point3d.new(ori)
		p=Geom::Point3d.new(point)
		v=Geom::Vector3d.new(p-o)
		v.length=radius
		return o+v
	end
	def self.project_to_plane(point,ori,plane)
		o=Geom::Point3d.new(ori)
		p=Geom::Point3d.new(point)
		v=Geom::Vector3d.new(p-o)
		return Geom.intersect_line_plane([o,v],plane)
	end
	
	def self.edges_proj_sphere(ori,radius)
		ents=Sketchup.active_model.entities
		arr=ents.grep(Sketchup::Edge)
		arr.each{|edg|
			p1=edg.start.position
			p2=edg.end.position
			p1=project_to_sphere(p1,ori,radius)
			p2=project_to_sphere(p2,ori,radius)
			ents.add_line(p1,p2)
		}
	end
	def self.edges_proj_plane(ori,plane)
		ents=Sketchup.active_model.entities
		arr=ents.grep(Sketchup::Edge)
		arr.each{|edg|
			p1=edg.start.position
			p2=edg.end.position
			p1=project_to_plane(p1,ori,plane)
			p2=project_to_plane(p2,ori,plane)
			ents.add_line(p1,p2)
		}
	end
	
end
