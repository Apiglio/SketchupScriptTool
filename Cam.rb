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
				$apiglio_Cam_LabelRanker_list|=[entity] if entity.is_a?(Sketchup::Text)
			end
			def onElementRemoved(entities, entity_id)
				$apiglio_Cam_LabelRanker_list.reject!{|i|i.deleted?}
			end
		end
		
		class ViewObserver < Sketchup::ViewObserver
			def onViewChanged(view)
				#puts "onViewChanged: #{view}"
<<<<<<< HEAD
				eye_point=view.eye.position
=======
				$apiglio_Cam_LabelRanker_list.each{|text|
					next if text.point.nil?
					max_dist=Cam::LabelRanker.get_rank(text)
					next if max_dist.nil?
					distance=view.camera.eye.distance(text.point)
					text.visible=true if distance<=max_dist and text.hidden?
					text.hidden=true if  distance>max_dist and text.visible?
				}
				
>>>>>>> 583668f (LabelRanker)
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
		
		def self.start
			Sketchup.active_model.remove_observer(@mod_obs) unless @mod_obs.nil?
			@mod_obs=ModObserver.new
			Sketchup.active_model.add_observer(@mod_obs)
			
			update_obs()
			Sketchup.active_model.entities.each{|e|
				if e.is_a?(Sketchup::Text) or e.is_a?(Sketchup::Dimension) then
					$apiglio_Cam_LabelRanker_list|=[e]
				end
			}
			
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
	
	
end

