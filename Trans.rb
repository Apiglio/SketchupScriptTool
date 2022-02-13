#一些有关变换的函数
module Trans

	Iden=Geom::Transformation.new unless defined?(Iden)
	MovX=Geom::Transformation.translation([1,0,0]) unless defined?(MovX)
	MovY=Geom::Transformation.translation([0,1,0]) unless defined?(MovY)
	MovZ=Geom::Transformation.translation([0,0,1]) unless defined?(MovZ)
	
	def self.tx(dist) Geom::Transformation.translation([dist,0,0]) end
	def self.ty(dist) Geom::Transformation.translation([0,dist,0]) end
	def self.tz(dist) Geom::Transformation.translation([0,0,dist]) end
	
	
	
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
				
	end
end
