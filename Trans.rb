#一些有关变换的函数
module Trans

	Iden=Geom::Transformation.new unless defined?(Iden)
	MovX=Geom::Transformation.translation([1,0,0]) unless defined?(MovX)
	MovY=Geom::Transformation.translation([0,1,0]) unless defined?(MovY)
	MovZ=Geom::Transformation.translation([0,0,1]) unless defined?(MovZ)
	
	def self.tx(dist) Geom::Transformation.translation([dist,0,0]) end
	def self.ty(dist) Geom::Transformation.translation([0,dist,0]) end
	def self.tz(dist) Geom::Transformation.translation([0,0,dist]) end
	
	module ViewDraw
		def self.circle_points(center,normal,radius,segment=24)
			raise ArgumentError.new("段数小于3") if segment<3
			cen=Geom::Point3d.new(center)
			nor=Geom::Vector3d.new(normal)
			if nor.parallel?([0,0,1]) then
				rdv=nor+[0,1,0]
			else
				rdv=nor+[0,0,1]
			end
			fir=nor.cross(rdv)
			fir.length=radius
			fir=cen+fir
			ang=360.degrees/segment
			res=[fir]
			1.upto(segment-1){|i|
				res.push(fir.transform(Geom::Transformation.rotation(cen,normal,i*ang)))
			}
			res
		end
	end
	
	module Reduction
		def self.triangle_area(p1,p2,p3)
			a=(p1-p2).length.abs
			b=(p2-p3).length.abs
			c=(p3-p1).length.abs
			p=a+b+c
			p/=2.0
			return p*(p-a)*(p-b)*(p-c)
		end
		def self.triangle_cog(points)
			xx,yy,zz=0,0,0
			points.each{|i|
				xx+=i.x
				yy+=i.y
				zz+=i.z
			}
			return [xx/3.0,yy/3.0,zz/3.0]
		end
		#平面的重心，通过三角形网络合并，精度似乎有一点问题
		def self.centroid(face)
			return nil unless face.is_a?(Sketchup::Face)
			mesh=face.mesh
			cgs=[]
			1.upto(mesh.count_polygons) do |i|
				idx=mesh.polygon_at(i)
				pos=idx.map{|i|mesh.point_at(i)}
				cgs<<[triangle_area(*pos),triangle_cog(pos)]
			end
			while cgs.length>1 do
				toto=cgs[0][0]+cgs[1][0]
				w1=cgs[0][0]/toto
				w2=cgs[1][0]/toto
				p1=cgs[0][1]
				p2=cgs[1][1]
				ncg=Geom.linear_combination(w1,p1,w2,p2)
				cgs[0]=[toto,ncg]
				cgs.delete_at(1)
			end
			return Geom::Point3d.new(cgs[0][1])
		end
		def self.centroid_circle(face,seg=24)
			center=centroid(face)
			radius=Math.sqrt(face.area/Math::PI)
			normal=face.normal
			g=face.parent.entities.add_group
			g.definition.entities.add_circle(center,normal,radius,seg)
		end
	end

	module Rand
		def self.rotation2D(ent)
			center=ent.bounds.center
			angle=rand()*360.degrees
			normal=[0,0,1]
			t=Geom::Transformation.rotation(center,normal,angle)
			Sketchup.active_model.entities.transform_entities(t,ent)
		end
		def self.movement2D(ent,max_radius=1000.mm)
			angle=rand()*360.degrees
			radius=rand()*max_radius
			vector=Geom::Vector3d.new(radius,0,0)
			tmp=Geom::Transformation.rotation([0,0,0],[0,0,1],angle)
			vector.transform!(tmp)
			t=Geom::Transformation.translation(vector)
			Sketchup.active_model.entities.transform_entities(t,ent)
		end
		def self.random_vector()
			result=Geom::Vector3d.new(1,0,0)
			normal=Geom::Vector3d.new(0,1,0)
			phi=rand()*360.degrees
			theta=rand()*360.degrees
			th=Geom::Transformation.rotation([0,0,0],[0,0,1],phi)
			normal.transform!(th)
			t=Geom::Transformation.rotation([0,0,0],normal,theta)
			return result.transform(th*t)
		end	
		private_class_method :random_vector
		def self.rotation3D(ent)
			center=ent.bounds.center
			vector=random_vector()
			angle=rand()*360.degrees
			t=Geom::Transformation.rotation(center,vector,angle)
			Sketchup.active_model.entities.transform_entities(t,ent)
		end
		def self.movement3D(ent,max_radius=1000.mm)
			vector=random_vector()
			radius=rand()*max_radius
			vector.length=radius
			t=Geom::Transformation.translation(vector)
			Sketchup.active_model.entities.transform_entities(t,ent)
		end
		def self.scaling(ent,range)
			raise ArgumentError.new("Range expected but #{range.class} found.") unless range.is_a?(Range)
			centre=ent.bounds.center
			factor=range.begin+(range.end-range.begin)*rand
			trans=Geom::Transformation.scaling(centre,*[factor]*3)
			Sketchup.active_model.entities.transform_entities(trans,ent)
		end
		
		
		
		def self.action(action_name,arr,&block)
			arr=Sketchup.active_model.selection.to_a if arr.nil?
			arr=[arr] unless arr.respond_to?(:[])
			Sketchup.active_model.start_operation(action_name,true)
			arr.each{|ent|
				block.call(ent)
			}
			Sketchup.active_model.commit_operation
		end
		private_class_method :action
		
		def self.r2d(arr=nil) action("Apiglio Trans: 水平面随机旋转",arr){|e|rotation2D(e)} end
		def self.r3d(arr=nil) action("Apiglio Trans: 三维随机旋转",arr){|e|rotation3D(e)} end
		def self.m2d(dist,arr=nil) action("Apiglio Trans: 水平面随机平移",arr){|e|movement2D(e,dist)} end
		def self.m3d(dist,arr=nil) action("Apiglio Trans: 三维随机平移",arr){|e|movement3D(e,dist)} end
		def self.sca(range,arr=nil) action("Apiglio Trans: 随机等比例缩放",arr){|e|scaling(e,range)} end
				
	end
	
	module Curve
		#三点弧的代码版本
		def self.add_arc_3point(*arg)
			if arg.length==3 then pts=arg.to_a else
				if arg[0].is_a? Array then pts=arg[0].to_a
				else raise ArgumentError.new("3 Point3 Required.") end
			end

			pos=pts.map{|p|Geom::Point3d.new(p)}
			v1=pos[0]-pos[1];v2=pos[2]-pos[1]
			v1.length=v1.length/2
			v2.length=v2.length/2
			m1=pos[1]+v1;m2=pos[1]+v2

			plane=Geom.fit_plane_to_points(pos)
			normal=Geom.intersect_plane_plane([m1,v1],[m2,v2])
			center=Geom.intersect_line_plane(normal,plane)
			radius=center.distance(pos[0])

			vector_0=pos[0]-center
			vector_1=pos[1]-center
			vector_2=pos[2]-center
			ang01=vector_0.angle_between(vector_1)
			ang02=vector_0.angle_between(vector_2)
			ang12=vector_1.angle_between(vector_2)

			if (ang02-(ang01+ang12)).abs<0.000001 then
				normal[1].reverse! unless normal[1].samedirection?(vector_1*vector_2)
				ea=ang02
			else
				ea=2*Math::PI-ang02
				if (ang01-(ang12+ang02)).abs<0.000001 then
					normal[1].reverse! unless normal[1].samedirection?(vector_1*vector_2)
				else
					normal[1].reverse! unless normal[1].samedirection?(vector_0*vector_1)
				end
			end

			Sketchup.active_model.entities.add_arc(center,vector_0,normal[1],radius,0,ea)
			return nil
		end
		
		#两点弧的代码版本
		def self.add_arc_2point(pt1,pt2,vec)
			raise ArgumentError.new("Point3d or Array required.") unless pt1.respond_to?(:on_line?)
			raise ArgumentError.new("Point3d or Array required.") unless pt2.respond_to?(:on_line?)
			raise ArgumentError.new("Vector3d or Array required.") unless vec.respond_to?(:normalize)

			pos1=Geom::Point3d.new(pt1)
			pos2=Geom::Point3d.new(pt2)
			vector=Geom::Vector3d.new(vec)
			chord=pos2-pos1
			mid_chord=chord
			mid_chord.length=chord.length/2
			mid=pos1+mid_chord
			
			normal_vector=chord*vector
			depth_vector=normal_vector*chord
			depth_vector.length=depth_vector.dot(vector)/depth_vector.length
			pos3=mid+depth_vector
			
			add_arc_3point(pos1,pos3,pos2)

		end
	end
	
end
