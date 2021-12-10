#encoding "UTF-8"
#sca.rb
#Apiglio
#方向键调节选中的要素，根据视图的角度在某些特定角度缩放特定距离

require 'sketchup.rb'

module Sca
#这是一个高效键盘移动实体的模块，配合带方向键的快捷键使用，可以调节三个等级跳跃的具体距离
#selected entities' scaling module

	@movement_distance=300.mm
	@safety_threshold=100
	#安全阈值，如果原尺寸为缩放后尺寸的@safety_threshold倍以上触发保护
	
	def Sca.safety_threshold
		puts "安全阈值，如果原尺寸为缩放后尺寸的#{@safety_threshold}倍以上触发保护(推荐在10-100倍左右)"
		return @safety_threshold
	end
	def Sca.safety_threshold=(x)
		@safety_threshold=x.to_f
	end
	
	def Sca.abs(x)
		(x>0)? x : 0
	end
	def Sca.view
		Sketchup.active_model.active_view
	end
	def Sca.ents
		Sketchup.active_model.entities
	end
	def Sca.sels
		Sketchup.active_model.selection
	end
	
	puts "xi(深度mm)批量调整选择图元的高度"
	def Sca.xi(w)
		tmp=Sca.ents.add_group Sca.sels
		case w<=>0
		when 1 then
			ori=tmp.bounds.min
		when -1 then
			ori=tmp.bounds.max
		else
			puts "参数应为非零数值"
			return nil
		end
		xscale=(tmp.bounds.width+w)/tmp.bounds.width.to_f
		if xscale.abs < 1.0/@safety_threshold then
			UI.messagebox "缩放后尺寸太小，触发保护机制"
			return nil
		end
		t=Geom::Transformation.scaling ori,xscale,1,1
		Sca.ents.transform_entities t,tmp
		Sca.sels.clear
		Sca.sels.add(tmp.explode.collect{|i|if i.kind_of? Sketchup::Drawingelement then i else nil end}.compact)
	end
	puts "yi(宽度mm)批量调整选择图元的高度"
	def Sca.yi(h)
		tmp=Sca.ents.add_group Sca.sels
		case h<=>0
		when 1 then
			ori=tmp.bounds.min
		when -1 then
			ori=tmp.bounds.max
		else
			puts "参数应为非零数值"
			return nil
		end
		yscale=(tmp.bounds.height+h)/tmp.bounds.height.to_f
		if yscale.abs < 1.0/@safety_threshold then
			UI.messagebox "缩放后尺寸太小，触发保护机制"
			return nil
		end
		t=Geom::Transformation.scaling ori,1,yscale,1
		Sca.ents.transform_entities t,tmp
		Sca.sels.clear
		Sca.sels.add(tmp.explode.collect{|i|if i.kind_of? Sketchup::Drawingelement then i else nil end}.compact)
	end
	puts "zi(高度mm)批量调整选择图元的高度"
	def Sca.zi(d)
		tmp=Sca.ents.add_group Sca.sels
		case d<=>0
		when 1 then
			ori=tmp.bounds.min
		when -1 then
			ori=tmp.bounds.max
		else
			puts "参数应为非零数值"
			return nil
		end
		zscale=(tmp.bounds.depth+d)/tmp.bounds.depth.to_f
		if zscale.abs < 1.0/@safety_threshold then
			UI.messagebox "缩放后尺寸太小，触发保护机制"
			return nil
		end
		t=Geom::Transformation.scaling ori,1,1,zscale
		Sca.ents.transform_entities t,tmp
		Sca.sels.clear
		Sca.sels.add(tmp.explode.collect{|i|if i.kind_of? Sketchup::Drawingelement then i else nil end}.compact)
	end
	
	puts "xd(深度mm)批量调整选择图元的高度"
	def Sca.xd(w)
		tmp=Sca.ents.add_group Sca.sels
		case w<=>0
		when -1 then
			ori=tmp.bounds.min
		when 1 then
			ori=tmp.bounds.max
		else
			puts "参数应为非零数值"
			return nil
		end
		xscale=(tmp.bounds.width+w)/tmp.bounds.width.to_f
		if xscale.abs < 1.0/@safety_threshold then
			UI.messagebox "缩放后尺寸太小，触发保护机制"
			return nil
		end
		t=Geom::Transformation.scaling ori,xscale,1,1
		Sca.ents.transform_entities t,tmp
		Sca.sels.clear
		Sca.sels.add(tmp.explode.collect{|i|if i.kind_of? Sketchup::Drawingelement then i else nil end}.compact)
	end
	puts "yd(宽度mm)批量调整选择图元的高度"
	def Sca.yd(h)
		tmp=Sca.ents.add_group Sca.sels
		case h<=>0
		when -1 then
			ori=tmp.bounds.min
		when 1 then
			ori=tmp.bounds.max
		else
			puts "参数应为非零数值"
			return nil
		end
		yscale=(tmp.bounds.height+h)/tmp.bounds.height.to_f
		if yscale.abs < 1.0/@safety_threshold then
			UI.messagebox "缩放后尺寸太小，触发保护机制"
			return nil
		end
		t=Geom::Transformation.scaling ori,1,yscale,1
		Sca.ents.transform_entities t,tmp
		Sca.sels.clear
		Sca.sels.add(tmp.explode.collect{|i|if i.kind_of? Sketchup::Drawingelement then i else nil end}.compact)
	end
	puts "zd(高度mm)批量调整选择图元的高度"
	def Sca.zd(d)
		tmp=Sca.ents.add_group Sca.sels
		case d<=>0
		when -1 then
			ori=tmp.bounds.min
		when 1 then
			ori=tmp.bounds.max
		else
			puts "参数应为非零数值"
			return nil
		end
		zscale=(tmp.bounds.depth+d)/tmp.bounds.depth.to_f
		if zscale.abs < 1.0/@safety_threshold then
			UI.messagebox "缩放后尺寸太小，触发保护机制"
			return nil
		end
		t=Geom::Transformation.scaling ori,1,1,zscale
		Sca.ents.transform_entities t,tmp
		Sca.sels.clear
		Sca.sels.add(tmp.explode.collect{|i|if i.kind_of? Sketchup::Drawingelement then i else nil end}.compact)
	end
	
	puts "xmi X轴镜像选择的图元"
	def Sca.xmi
		tmp=Sca.ents.add_group Sca.sels
		ori=tmp.bounds.center
		t=Geom::Transformation.scaling ori,-1,1,1
		Sca.ents.transform_entities t,tmp
		Sca.sels.clear
		Sca.sels.add(tmp.explode.collect{|i|if i.kind_of? Sketchup::Drawingelement then i else nil end}.compact)
	end
	puts "ymi Y轴镜像选择的图元"
	def Sca.ymi
		tmp=Sca.ents.add_group Sca.sels
		ori=tmp.bounds.center
		t=Geom::Transformation.scaling ori,1,-1,1
		Sca.ents.transform_entities t,tmp
		Sca.sels.clear
		Sca.sels.add(tmp.explode.collect{|i|if i.kind_of? Sketchup::Drawingelement then i else nil end}.compact)
	end
	puts "zmi Z轴镜像选择的图元"
	def Sca.zmi
		tmp=Sca.ents.add_group Sca.sels
		ori=tmp.bounds.center
		t=Geom::Transformation.scaling ori,1,1,-1
		Sca.ents.transform_entities t,tmp
		Sca.sels.clear
		Sca.sels.add(tmp.explode.collect{|i|if i.kind_of? Sketchup::Drawingelement then i else nil end}.compact)
	end
	
	
	
	
	puts "setmovement打开新窗口设置微操距离"
	def Sca.set_movement
		res=UI.inputbox ["移动毫米数："],[@movement_distance],"设置缩放距离"
		if res==false then return end
		@movement_distance=res[0]
		res
	end
	def Sca.direction#返回当前视角的黄道角度分区
		ar=Sca.view.camera.direction
		if (ar[0]==ar[1])or(ar[0]==-ar[1]) then
			0
		else
			case [ar[0]<ar[1],-ar[0]<ar[1]]
			when [true,true] then return 1
			when [true,false] then return 4
			when [false,true] then return 2
			when [false,false] then return 3
			else return 0
			end
		end
	end
	def Sca.move_direction(str)#u/d/l/r/f/b 根据给定的六个视图方向返回实际xyz轴的方向
		strr=str[0]
		case strr
		when "U","u"
			return "z+"
		when "D","d"
			return "z-"
		else
			case Sca.direction
			when 4
				case strr
					when "L","l" then return "y-"
					when "F","f" then return "x-"
					when "R","r" then return "y+"
					when "B","b" then return "x+"
				end
			when 3
				case strr
					when "L","l" then return "x+"
					when "F","f" then return "y-"
					when "R","r" then return "x-"
					when "B","b" then return "y+"
				end
			when 2
				case strr
					when "L","l" then return "y+"
					when "F","f" then return "x+"
					when "R","r" then return "y-"
					when "B","b" then return "x-"
				end
			when 1
				case strr
					when "L","l" then return "x-"
					when "F","f" then return "y+"
					when "R","r" then return "x+"
					when "B","b" then return "y-"
				end
			else
				return false
			end
		end
	end
	def Sca.scai(direction,dis)#根据指定的六个方向和距离放大选中物体
		case Sca.move_direction(direction)
		when "z+" then Sca.zi dis
		when "z-" then Sca.zd dis
		when "x+" then Sca.xi dis
		when "x-" then Sca.xd dis
		when "y+" then Sca.yi dis
		when "y-" then Sca.yd dis
		else puts "Error direction"
		end
	end
	def Sca.scad(direction,dis)#根据指定的六个方向和距离缩小选中物体
		case Sca.move_direction(direction)
		when "z+" then Sca.zd -dis
		when "z-" then Sca.zi -dis
		when "x+" then Sca.xd -dis
		when "x-" then Sca.xi -dis
		when "y+" then Sca.yd -dis
		when "y-" then Sca.yi -dis
		else puts "Error direction"
		end
	end
	
	#定义命令对象
	
	@command_list=[]#命令列表
	
	@command_list<<set_mov=UI::Command.new("设置缩放距离") {Sca.set_movement}
	
	@command_list<<sri=UI::Command.new("右放大") {Sca.scai "r",@movement_distance}
	@command_list<<srd=UI::Command.new("右缩小") {Sca.scad "r",@movement_distance}
	#@command_list<<mrs=UI::Command.new("右微调") {Sca.mov "r",@movement_distance/@movement_division}
	
	@command_list<<sli=UI::Command.new("左放大") {Sca.scai "l",@movement_distance}
	@command_list<<sld=UI::Command.new("左缩小") {Sca.scad "l",@movement_distance}
	#@command_list<<mls=UI::Command.new("左微调") {Sca.mov "l",@movement_distance/@movement_division}
	
	@command_list<<sfi=UI::Command.new("前放大") {Sca.scai "f",@movement_distance}
	@command_list<<sfd=UI::Command.new("前缩小") {Sca.scad "f",@movement_distance}
	#@command_list<<mfs=UI::Command.new("前微调") {Sca.mov "f",@movement_distance/@movement_division}
	
	@command_list<<sbi=UI::Command.new("后放大") {Sca.scai "b",@movement_distance}
	@command_list<<sbd=UI::Command.new("后缩小") {Sca.scad "b",@movement_distance}
	#@command_list<<mbs=UI::Command.new("后微调") {Sca.mov "b",@movement_distance/@movement_division}
	
	@command_list<<sui=UI::Command.new("上放大") {Sca.scai "u",@movement_distance}
	@command_list<<sud=UI::Command.new("上缩小") {Sca.scad "u",@movement_distance}
	#@command_list<<mus=UI::Command.new("上微调") {Sca.mov "u",@movement_distance/@movement_division}
	
	@command_list<<sdi=UI::Command.new("下放大") {Sca.scai "d",@movement_distance}
	@command_list<<sdd=UI::Command.new("下缩小") {Sca.scad "d",@movement_distance}
	#@command_list<<mds=UI::Command.new("下微调") {Sca.mov "d",@movement_distance/@movement_division}
	
	@command_list<<xmr=UI::Command.new("X镜像") {Sca.xmi}
	@command_list<<ymr=UI::Command.new("Y镜像") {Sca.ymi}
	@command_list<<zmr=UI::Command.new("Z镜像") {Sca.zmi}
	
	
	@command_list.each{|i|
		if i.instance_of? UI::Command then
			#i.small_icon="Image.Sca\\"+i.menu_text+"_small.png"
			#i.large_icon="Image.Sca\\"+i.menu_text+"_large.png"
			i.small_icon="Image.Sca\\"+i.menu_text+".svg"
			i.large_icon="Image.Sca\\"+i.menu_text+".svg"
			
		end
	}
	
	
	#定义工具栏
	
	@toolbar=UI::Toolbar.new "Apiglio 快速轴缩"
	@toolbar.add_item set_mov
	@toolbar.add_separator
	@toolbar.add_item sli
	@toolbar.add_item sri
	@toolbar.add_item sui
	@toolbar.add_item sdi
	@toolbar.add_item sfi
	@toolbar.add_item sbi
	@toolbar.add_separator
	@toolbar.add_item sld
	@toolbar.add_item srd
	@toolbar.add_item sud
	@toolbar.add_item sdd
	@toolbar.add_item sfd
	@toolbar.add_item sbd
	@toolbar.add_separator
	@toolbar.add_item xmr
	@toolbar.add_item ymr
	@toolbar.add_item zmr
	@toolbar.show
	
	#定义菜单栏
	
	ext=UI.menu "Tool"
	@menu_item_list=[]
	@menu=ext.add_submenu "Apiglio 快速轴缩"
	@menu_item_list<<@menu.add_item(set_mov)
	@menu.add_separator
	
	@menu_item_list<<@menu.add_item(sli)
	@menu_item_list<<@menu.add_item(sri)
	@menu_item_list<<@menu.add_item(sui)
	@menu_item_list<<@menu.add_item(sdi)
	@menu_item_list<<@menu.add_item(sfi)
	@menu_item_list<<@menu.add_item(sbi)
	@menu.add_separator
	
	@menu_item_list<<@menu.add_item(sld)
	@menu_item_list<<@menu.add_item(srd)
	@menu_item_list<<@menu.add_item(sud)
	@menu_item_list<<@menu.add_item(sdd)
	@menu_item_list<<@menu.add_item(sfd)
	@menu_item_list<<@menu.add_item(sbd)
	@menu.add_separator
	
	@menu_item_list<<@menu.add_item(xmr)
	@menu_item_list<<@menu.add_item(ymr)
	@menu_item_list<<@menu.add_item(zmr)
	
	@menu_item_list.each{|i|
		@menu.set_validation_proc(i){MF_ENABLED}
	}
	
	#模块变量外部调用程序
	
	def Sca.toolbar
		@toolbar
	end
	def Sca.commands
		@command_list
	end
	def Sca.menu
		@menu
	end
	def Sca.menu_item_list
		@menu_item_list
	end
	
	puts "#Module Mov has been loaded."
end

	
