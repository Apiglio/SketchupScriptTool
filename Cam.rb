#Camera Tool
#Apiglio
#轨迹相机

module Cam
	
	def self.vworld
		Sketchup.active_model.active_view.zoom_extents
	end
	def self.vsel
		Sketchup.active_model.active_view.zoom Sketchup.active_model.selection
	end
	def self.vactive
		Sketchup.active_model.active_view.zoom Sketchup.active_model.active_entities
	end
	class << self
		alias vw vworld
		alias vs vsel
		alias va vactive
	end
	
	#平移视角的模块
	module Pan
		def self.do_pan(orientation,step=1)
			mod = Sketchup.active_model
			cam = mod.active_view.camera
			raise Exception.new('透视投影不能平移') if cam.perspective?
			vh  = cam.height
			up  = cam.up
			dir = cam.direction
			eye = cam.eye
			tar = cam.target
			hori_vec = dir.cross(up)
			vert_vec = Geom::Vector3d.new(up)
			vert_range = cam.height
			hori_range = vert_range * mod.active_view.vpwidth.to_f / mod.active_view.vpheight.to_f
			case orientation.downcase
			when "u"
				hori_vec.length = 0
				vert_vec.length = +vert_range*step
			when "d"
				hori_vec.length = 0
				vert_vec.length = -vert_range*step
			when "l"
				hori_vec.length = -hori_range*step
				vert_vec.length = 0
			when "r"
				hori_vec.length = +hori_range*step
				vert_vec.length = 0
			end
			new_eye = eye + hori_vec + vert_vec
			new_tar = tar + hori_vec + vert_vec
			new_camera = Sketchup::Camera.new(new_eye,new_tar,up,false)
			new_camera.height = vh
			mod.active_view.camera = new_camera
		end
		#private_class_method :do_pan
		def self.l()
			self.do_pan("l")
		end
		def self.r()
			self.do_pan("r")
		end
		def self.u()
			self.do_pan("u")
		end
		def self.d()
			self.do_pan("d")
		end
		# 批量导出分幅的画面
		def self.pan_export(path,count_cell=3)
			mod = Sketchup.active_model
			cam = mod.active_view.camera
			vh  = cam.height
			cam.height = vh/count_cell.to_f
			self.do_pan("l",(count_cell+1)/2.0)
			self.do_pan("u",(count_cell-1)/2.0)
			for i in 0..count_cell-1 do
				for j in 0..count_cell-1 do
					self.do_pan("r",1)
					mod.active_view.write_image(path+"\\ImageCell[#{i},#{j}].png")
				end
				self.do_pan("d",1)
				self.do_pan("l",count_cell)
			end
			self.do_pan("r",(count_cell+1)/2.0)
			self.do_pan("u",(count_cell+1)/2.0)
			cam.height = vh
		end
	end
	
	#按照比例尺设置视图
	module Scale
	
	# 在给定画面高的实际尺寸情况下返回Camera类对应的比例尺大小
		def self.camera_scale(camera,paper_height=297.mm)
			raise ArgumentError.new("相机不是平行投影") if camera.perspective?
			return paper_height / camera.height
		end
		def self.paper_size(name)
			case name
				when "A0" then return [1189,841]
				when "A1" then return [841,594]
				when "A2" then return [594,420]
				when "A3" then return [420,297]
				when "A4" then return [297,210]
				when "A5" then return [210,148]
				when "A6" then return [148,105]
				else return name
			end
		end
		#确定比例尺的顶视图
		def self.top(scale,paper="A3",margin=0)
			mod = Sketchup.active_model
			cam = mod.active_view.camera
			vph = mod.active_view.vpheight
			vpw = mod.active_view.vpwidth
			#计算图幅像素大小
			drawing_size = self.paper_size(paper)
			vpr=vpw/vph.to_f
			horizontal = vpr>=1 #判断横向还是纵向
			drawing_size.reverse! unless horizontal
			psheight = drawing_size[0].mm - 2*margin
			pswidth  = drawing_size[1].mm - 2*margin
			raise Exception.new('边缘尺寸过大') if psheight<0 or pswidth<0 or psheight * pswidth == 0
			psr=pswidth/psheight.to_f
			cam.perspective = false
			if psr<=vpr then
				cam.height = psheight * vph / vpw.to_f / scale.to_f
			else
				cam.height = pswidth / scale.to_f
			end
		end

	end
	
	
	module Vector
		def self.look_down(vector,angle)
			return nil if vector.to_a[0..1].map{|i|i.round(3)} == [0,0]
			origin_vector=Geom::Vector3d.new(vector)
			vert=Geom::Vector3d.new(0,0,1)
			vert.length=origin_vector.dot([0,0,1])
			hori=origin_vector-vert
			down=Geom::Vector3d.new(0,0,-1)
			down.length=origin_vector.length*Math.tan(angle)
			res=origin_vector+down
			res.length=origin_vector.length
			return res
		end
		# 根据一个不垂直与水平面的向量vector，返回一个向量res使得vector垂直于res且二者与z轴在同一平面内
		def self.up_perpendicular(vector,normal=[0,0,1])
			return nil if vector.to_a[0..1].map{|i|i.round(3)} == [0,0]
			tmp=Geom::Vector3d.new(vector) + normal
			ortho=vector.cross(tmp)
			res=ortho.cross(vector)
			res.length = 1
			res.length = -res.length unless res.dot(normal)>0
			return res
		end
	end
	
	# 根据曲线图元和分段数量计算一系列点位与向量，对于特定情况可能有部分分段数量不能正常工作，段时间内没有去优化的计划
	def self.curve_vectors(curve,nparts)
		raise ArgumentError.new("Sketchup::Curve expected but #{curve.class} found.") unless curve.is_a?(Sketchup::Curve)
		raise ArgumentError.new("Fixnum expected but #{nparts.class} found.") unless nparts.is_a?(Fixnum)
		raise ArgumentError.new("nparts must be >=2.") unless nparts>=2
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
	
	def self.curve_cam_sleep(curve,nparts,sec,down_angle=0.degrees)
		pvs=curve_vectors(curve,nparts)
		time_unit=sec.to_f/nparts
		view=Sketchup.active_model.active_view
		pvs.each{|i|
			vec=Vector.look_down(i[1],down_angle)
			Sketchup.active_model.active_view.camera=Sketchup::Camera.new(i[0],vec,Vector.up_perpendicular(vec,[0,0,1]))
			Sketchup.active_model.active_view.refresh
			sleep(time_unit)
		}
	end
	def self.curve_cam_thread(curve,nparts,sec,down_angle=0.degrees)
		t=Thread.new{
			pvs=curve_vectors(curve,nparts)
			time_unit=sec.to_f/nparts
			view=Sketchup.active_model.active_view
			pvs.each{|i|
				vec=Vector.look_down(i[1],down_angle)
				Sketchup.active_model.active_view.camera=Sketchup::Camera.new(i[0],vec,Vector.up_perpendicular(vec,[0,0,1]))
				Sketchup.active_model.active_view.refresh
				sleep(time_unit)
			}
		}
		return(t)
	end
	def self.curve_cam_timer(curve,nparts,sec,down_angle=0.degrees)
		$cam_curve_cam_timer_pvs=curve_vectors(curve,nparts)
		time_unit=sec.to_f/nparts
		view=Sketchup.active_model.active_view
		$cam_curve_cam_timer_state=0
		$cam_curve_cam_timer_handle=UI.start_timer(time_unit,true){
			i=$cam_curve_cam_timer_pvs[$cam_curve_cam_timer_state]
			vec=Vector.look_down(i[1],down_angle)
			Sketchup.active_model.active_view.camera=Sketchup::Camera.new(i[0],vec,Vector.up_perpendicular(vec,[0,0,1]))
			$cam_curve_cam_timer_state+=1
			UI.stop_timer($cam_curve_cam_timer_handle) unless $cam_curve_cam_timer_state < $cam_curve_cam_timer_pvs.length
		}
		return($cam_curve_cam_timer_handle)
	end
	def self.curve_cam(*arg)
		curve_cam_thread(*arg)
	end
	
	

	#用来做分级标注显示，等级较低的标注在距视点较远距离时会隐藏
	module LabelRanker
		@ents_lnk=0
		@ents_obs=0
		@view_lnk=0
		@view_obs=0
		$apiglio_Cam_LabelRanker_list=[]
		@mod_obs=nil

		
		class EntsObserver < Sketchup::EntitiesObserver
			def onElementAdded(entities, entity)
				$apiglio_Cam_LabelRanker_list|=[entity] if entity.is_a?(Sketchup::Text) or entity.is_a?(Sketchup::Dimension)
			end
			def onElementRemoved(entities, entity_id)
				$apiglio_Cam_LabelRanker_list.reject!{|i|i.deleted?}
				#$apiglio_Cam_LabelRanker_list.reject!{|i|i.entityID==entity_id}
			end
		end
		
		class ViewObserver < Sketchup::ViewObserver
			def text_world_position(text)
				tmp=text
				res=text.point
				mod=Sketchup.active_model
				while tmp.parent!=mod
					inst=tmp.parent.instances
					return nil unless inst.length==1 # 排除标注在组件（或有多个实例的群组）中的情况
					tmp=inst[0]
					res=tmp.transformation.inverse*res
				end
				return res
			end
			private :text_world_position
			
			def onViewChanged(view)
				#puts "onViewChanged: #{view}"
				$apiglio_Cam_LabelRanker_list.each{|text|
					if text.is_a?(Sketchup::Text) then
						next if text_world_position(text).nil?
						max_dist=Cam::LabelRanker.get_rank(text)
						next if max_dist.nil?
						distance=view.camera.eye.distance(text.point)
						text.visible=true if distance<=max_dist and text.hidden?
						text.hidden=true if  distance>max_dist and text.visible?
					elsif text.is_a?(Sketchup::Dimension) then
						#
					else
						#
					end
				}
			end
		end
		
		class ModObserver < Sketchup::ModelObserver
			def onActivePathChanged(model)
				LabelRanker.update_obs
			end
		end
		
		def self.test
			return [@ents_lnk,@ents_obs,@view_lnk,@view_obs,@mod_obs,$apiglio_Cam_LabelRanker_list]
		end
		
		def self.update_obs
			@ents_lnk.remove_observer(@ents_obs) if @ents_lnk!=0
			@view_lnk.remove_observer(@view_obs) if @view_lnk!=0
			
			if Sketchup.active_model.active_path.nil? then
				@ents_lnk=Sketchup.active_model
			else
				@ents_lnk=Sketchup.active_model.active_path.last
			end

			@ents_obs=EntsObserver.new
			@ents_lnk.entities.add_observer(@ents_obs)
			
			@view_lnk=Sketchup.active_model.active_view
			@view_obs=ViewObserver.new
			@view_lnk.add_observer(@view_obs)
		end
		
		def self.all_text_into_list(model_or_defs)
			model_or_defs.entities.grep(Sketchup::Text).each{|e|$apiglio_Cam_LabelRanker_list|=[e]}
			model_or_defs.entities.grep(Sketchup::Group).each{|g|all_text_into_list(g.definition)}
		end
		def self.all_dimension_into_list(model_or_defs)
			model_or_defs.entities.grep(Sketchup::Dimension).each{|e|$apiglio_Cam_LabelRanker_list|=[e]}
			model_or_defs.entities.grep(Sketchup::Group).each{|g|all_dimension_into_list(g.definition)}
		end
		private_class_method :all_text_into_list
		private_class_method :all_dimension_into_list
		
		def self.start
			Sketchup.active_model.remove_observer(@mod_obs) unless @mod_obs.nil?
			@mod_obs=ModObserver.new
			Sketchup.active_model.add_observer(@mod_obs)
			update_obs()
			all_text_into_list(Sketchup.active_model)
			all_dimension_into_list(Sketchup.active_model)
			Sketchup.active_model.active_view.invalidate
		end
		
		def self.stop
			@ents_lnk.remove_observer(@ents_obs)
			@view_lnk.remove_observer(@view_obs)
			$apiglio_Cam_LabelRanker_list.each{|l|l.visible=true}
			$apiglio_Cam_LabelRanker_list.clear
			GC.start
		end
		
		def self.set_rank(text,value)
			text.set_attribute("APIGLIO","LabelRank",value)
		end
		def self.get_rank(text)
			text.get_attribute("APIGLIO","LabelRank")
		end
		
	end
	
	module Colorize
		def self.by_depth(sels=nil,graduation=20,c1=[255,127,127],c2=[255,255,127],variation=0.8)
			sels=Sketchup.active_model.selection.to_a if sels.nil?
			Sketchup.active_model.start_operation("按高度设色")
			begin
				values=sels.map{|i|i.bounds.depth}
				min=values.min
				max=values.max
				minmax=max-min
				colors=[]
				0.upto(graduation-1){|i|
					pos=i.to_f/(graduation-1)
					pon=1-pos
					ct=[c1,c2].transpose.map{|i|pos*i[0]+pon*i[1]}
					colors<<ct.map{|i|i.round(0)}
				}
				sels.each{|i|
					position=(i.bounds.depth-min)/minmax.to_f
					position**=variation
					position*=(graduation-1)
					cidx=position.floor
					color=Sketchup::Color.new(colors[cidx])
					i.material=color
				}
			rescue
				Sketchup.active_model.abort_operation()
				return nil
			end
			Sketchup.active_model.commit_operation()
		end
	end
	
	
end

