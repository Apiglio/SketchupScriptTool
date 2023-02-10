#encoding "UTF-8"
#ins.rb
#Apiglio
#这不是一个打包好的插件模块
#只能直接在ruby控制台中通过load来调用
#代码发布在微信公众号Apiglio中

require 'sketchup.rb'

module Ins

	def self.model() Sketchup.active_model end
	def self.ents() Sketchup.active_model.entities end
	def self.sels() Sketchup.active_model.selection end
	def self.lyrs() Sketchup.active_model.layers end
	
	
	#=================================常量部==================================
	
	E  = Sketchup::Edge unless defined?(E)
	F  = Sketchup::Face unless defined?(F)
	C  = Sketchup::ComponentInstance unless defined?(C)
	G  = Sketchup::Group unless defined?(G)
	CD = Sketchup::ComponentDefinition unless defined?(CD)
	CL = Sketchup::ConstructionLine unless defined?(CL)
	CP = Sketchup::ConstructionPoint unless defined?(CP)
	D  = Sketchup::Dimension if Sketchup.version_number > 14000000 unless defined?(D)
	I  = Sketchup::Image unless defined?(I)
	SP = Sketchup::SectionPlane unless defined?(SP)
	T  = Sketchup::Text unless defined?(T)
	
	OriTrans = Geom::Transformation.new unless defined?(OriTrans)
	
	#=========================================================================
	
	#组件实例的坐标工具
	module Corr
		def bound_correction(instance,global_trans)
		
		end
		def bound_reduction(instance)
		
		end
		
	end
	
	#=========================================================================
	
	module Move
		def self.trans_down(distance)
			return Geom::Transformation.translation([0,0,-distance])
		end
		def self.ground(sels=nil)
			sels=Sketchup.active_model.selection.to_a if sels.nil?
			sels.select!{|ent|ent.respond_to?(:transformation)}
			Sketchup.active_model.start_operation("Ins::Move组件下落",false)
			begin
				sels.each{|ent|
					z_value = ent.bounds.min.z
					ent.parent.entities.transform_entities(self.trans_down(z_value),ent)
				}
				Sketchup.active_model.commit_operation()
			rescue
				Sketchup.active_model.abort_operation()
			end
		end
	end
	

	
end
