#encoding "UTF-8"
#Apiglio
#这不是一个打包好的插件模块
#只能直接在ruby控制台中通过load来调用


#编辑动态属性
#


D:
{
	"_formatversion"=>1.0, 
	"_has_movetool_behaviors"=>0.0, 
	"_lastmodified"=>"2022-12-20 20:07", 
	"_lengthunits"=>"CENTIMETERS", 
	"_name"=>"组件#1", 
	"_name_label"=>"Name", 
	"name"=>nil
}
{
	"_formatversion"=>1.0, 
	"_has_movetool_behaviors"=>0.0, 
	"_lastmodified"=>"2022-12-20 20:07", 
	"_lengthunits"=>"CENTIMETERS", 
	"_name"=>"组件#1"
}

I:
{
	"_has_movetool_behaviors"=>0.0, 
	"_lengthunits"=>"CENTIMETERS", 
	"_name"=>"组件#1", 
	"name"=>nil
}
{
	"_has_movetool_behaviors"=>0.0, 
	"_lengthunits"=>"CENTIMETERS", 
	"_name"=>"组件#1"
}






module DC
	class DCHelper
		include Enumerable
		def initialize(dc_instance)
			@_dc_instance_ = dc_instance
		end
		def each(&block)
			@_dc_instance_.attribute_dictionaries["dynamic_attributes"].to_h.each(&block)
		end
		def has_key?(key)
			
		end
		def get_key?(key)
			
		end
		
	end
	
end








