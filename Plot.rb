module ApiglioPlot
	def self.gen_xy_surface_rough(pixelcount=10,&block)
		block=proc{|x,y|0} if block.nil?
		step=2.0/pixelcount.to_f
		pts=[]
		Sketchup.active_model.start_operation("Apiglio: Surface R")
		t0=Time.now().to_f
		begin
			0.upto(pixelcount) do |i|
				pts.push([])
				0.upto(pixelcount) do |j|
					x=i*step-1
					y=j*step-1
					pts[-1].push([x,y,block.call(x,y)])
				end
			end
			0.upto(pixelcount-1) do |i|
				0.upto(pixelcount-1) do |j|
					Sketchup.active_model.entities.add_face(pts[i][j],pts[i+1][j],pts[i][j+1])
					Sketchup.active_model.entities.add_face(pts[i+1][j+1],pts[i][j+1],pts[i+1][j])
				end
			end
		rescue
			Sketchup.active_model.abort_operation()
			return RuntimeError.new("生成表面出错。")
		end
		t1=Time.now().to_f
		Sketchup.active_model.commit_operation()
		puts("用时#{t1-t0}秒。")
	end


	def self.gen_xy_surface_mesh(pixelcount=10,&block)
		block=proc{|x,y|0} if block.nil?
		step=2.0/pixelcount.to_f
		pts=[]
		i=-1.0
		Sketchup.active_model.start_operation("Apiglio: Surface M")
		mesh=Geom::PolygonMesh.new
		t0=Time.now().to_f
		begin
			0.upto(pixelcount) do |i|
				pts.push([])
				0.upto(pixelcount) do |j|
					x=i*step-1
					y=j*step-1
					pts[-1].push(mesh.add_point([x,y,block.call(x,y)]))
				end
			end
			0.upto(pixelcount-1) do |i|
				0.upto(pixelcount-1) do |j|
					mesh.add_polygon(pts[i][j],pts[i+1][j],pts[i][j+1])
					mesh.add_polygon(pts[i+1][j+1],pts[i][j+1],pts[i+1][j])
				end
			end
			Sketchup.active_model.entities.add_faces_from_mesh(mesh)
		rescue
			Sketchup.active_model.abort_operation()
			return RuntimeError.new("生成表面出错。")
		end
		t1=Time.now().to_f
		Sketchup.active_model.commit_operation()
		puts("用时#{t1-t0}秒。")
	end


	def self.gen_xy_surface_builder(pixelcount=10,&block)
		block=proc{|x,y|0} if block.nil?
		step=2.0/pixelcount.to_f
		pts=[]
		Sketchup.active_model.start_operation("Apiglio: Surface B")
		t0=Time.now().to_f
		begin
			0.upto(pixelcount) do |i|
				pts.push([])
				0.upto(pixelcount) do |j|
					x=i*step-1
					y=j*step-1
					pts[-1].push([x,y,block.call(x,y)])
				end
			end
			Sketchup.active_model.entities.build{|builder|
				0.upto(pixelcount-1) do |i|
					0.upto(pixelcount-1) do |j|
						builder.add_face(pts[i][j],pts[i+1][j],pts[i][j+1])
						builder.add_face(pts[i+1][j+1],pts[i][j+1],pts[i+1][j])
					end
				end
			}
		rescue
			Sketchup.active_model.abort_operation()
			return RuntimeError.new("生成表面出错。")
		end
		t1=Time.now().to_f
		Sketchup.active_model.commit_operation()
		puts("用时#{t1-t0}秒。")
	end
end