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
	
	
	def self.project_line_to_plane(line,plane)
		if plane.length==4 then normal=plane[0..2]
		elsif plane.length==2 then normal=plane[1]
		else raise ArgumentError.new("invalid plane format, 2 or 4-sized Array expected.")
		end
		if line[1].dot(normal)==0 then
			#直线平行于平面
			inters=line[0].project_to_plane(plane)
			return [inters,line[1]]
		else
			#直线相交于平面
			inters=Geom.intersect_line_plane(line,plane)
			delta=(inters+line[1]).project_to_plane(plane)
			return [inters,delta-inters]
		end
	end

	def self.projected_intersects(line1,line2,plane)
		pl_1=self.project_line_to_plane(line1,plane)
		pl_2=self.project_line_to_plane(line2,plane)
		pp=Geom.intersect_line_line(pl_1,pl_2)
		return [nil,nil] if pp.nil?
		normal=[pp,plane[0..2]]
		pt_1=Geom.intersect_line_line(line1,normal)
		pt_2=Geom.intersect_line_line(line2,normal)
		return [pt_1,pt_2]
	end

	def self.project_point_to_surface(point,surface)
		plumb_line=[point,[0,0,1]]
		pi=nil
		if surface.find{|f|
			pi=Geom.intersect_line_plane(plumb_line,f.plane)
			if pi.nil? then false
			elsif f.classify_point(pi)==Sketchup::Face::PointOutside then false
			else true end
		}.nil? then
			return(nil)
		else
			return(pi)
		end
	end

	def self.falling_onto_surface(grp,surf)
		b=grp.bounds
		bc=b.center-Geom::Vector3d.new([0,0,b.depth])
		proj=self.project_point_to_surface(bc,surf)
		t=Geom::Transformation.new(proj-bc)
		grp.parent.entities.transform_entities(t,grp)
	end

	def self.falling_selected_onto_surface(surface)
		Sketchup.active_model.start_operation("Falling Onto Surface",true)
		sels=Sketchup.active_model.selection.to_a
		sels.each{|g|
			if g.is_a?(Sketchup::ComponentInstance) or g.is_a?(Sketchup::Group) then
				self.falling_onto_surface(g,surface)
			else
				Sketchup.active_model.abort_operation
				return nil
			end
		}
		Sketchup.active_model.commit_operation
	end
	
end
