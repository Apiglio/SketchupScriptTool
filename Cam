#Camera Tool
#Apiglio
#轨迹相机

module Cam
	
	def self.curve_vectors(curve,nparts)
		raise ArgumentError.new("Sketchup::Curve expected but #{curve.class} found.") unless curve.is_a?(Sketchup::Curve)
		raise ArgumentError.new("Fixnum expected but #{nparts.class} found.") unless nparts.is_a?(Fixnum)
		raise ArgumentError.new("nparts must be >=2.") unless nparts>=2
		#curve_len=curve.edges.map{|i|i.length}.inject{|a,b|a+=b}
		curve_len=curve.length
		lparts=curve_len/nparts
		result=[curve.first_edge.line]#起点的相机位置
		
		target_len=lparts
		current_edge=0
		current_len=0
		cnt=0
		
		while target_len<curve_len do
			case current_len+curve.edges[current_edge].length<=>target_len
				when -1
					current_len+=curve.edges[current_edge].length
					current_edge+=1
				when 0
					current_len+=curve.edges[current_edge].length
					current_edge+=1
					target_len+=lparts
					point=curve.edges[current_edge].start
					v1=curve.edges[current_edge-1].line[1]
					v2=curve.edges[current_edge].line[1]
					vector=Geom.linear_combination(0.5,v1,0.5,v2)
					result<<[point,vector]
				when 1
					target_len+=lparts
					cedg=curve.edges[current_edge]
					vector=cedg.line[1]
					point=cedg.line[0]
					vecofs=vector
					vecofs.length=target_len-current_len
					point=point+vecofs
					result<<[point,vector]
			end
			cnt+=1
			if cnt>5*nparts then return nil end
		end
		result
	end
	
	def self.curve_cam(curve,nparts,sec)
		t=Thread.new{
			pvs=curve_vectors(curve,nparts)
			time_unit=sec.to_f/nparts
			view=Sketchup.active_model.active_view
			pvs.each{|i|
				view.camera=Sketchup::Camera.new(i[0],i[1],[0,0,1])
				sleep(time_unit)
			}
		}
		return(t)
	end
	
end

