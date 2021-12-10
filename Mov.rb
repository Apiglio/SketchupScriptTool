#encoding "UTF-8"
#mov2.rb
#Apiglio
#重要想法实现！
#方向键调节选中的要素，根据视图的角度在某些特定角度移动特定距离

require 'sketchup.rb'

module Mov
#这是一个高效键盘移动实体的模块，配合带方向键的快捷键使用，可以调节三个等级跳跃的具体距离
#selected entities' transform module
	#@small_movement=1000.mm
	#@midium_movement=5000.mm
	#@large_movement=20000.mm
	@movement_distance=3000.mm
	@movement_distance_vertical=2700.mm
	@movement_division=10.0
	
	@major_movement_direction=Geom::Vector3d.new 1,0,0
	@minor_movement_direction=Geom::Vector3d.new 0,1,0
	
	
	def Mov.division
		return @movement_division
	end
	def Mov.division=(x)
		@movement_division=x.to_f
	end
	
	#def Mov.abs(x)
	#	(x>0)? x : 0
	#end
	def Mov.view
		Sketchup.active_model.active_view
	end
	def Mov.ents
		#Sketchup.active_model.entities
		Sketchup.active_model.active_entities
	end
	def Mov.sels
		Sketchup.active_model.selection
	end
	
	##解决非轴向的运动方法（通过设定自定义正方向）
	
	def Mov.norm(a)
		Math.sqrt(a[0]**2+a[1]**2+a[2]**2)
	end
	
	def Mov.sine_angle(a,b)
		(a.cross b).z / Mov.norm(a) / Mov.norm(b)
	end
	
	def Mov.cosine_angle(a,b)
		(a.dot b) / Mov.norm(a) / Mov.norm(b)
	end
	
	puts "	clock_angle(a,b) 返回向量a到向量b的顺时针夹角"
	def Mov.clock_angle(a,b)
		pi=Math.acos(-1)
		sine=Mov.sine_angle(a,b)
		cosine=Mov.cosine_angle(a,b)
		if sine<0 then
			return pi-Math.acos(cosine)
		else
			return pi+Math.acos(cosine)
		end
	end	
	
	
	puts "d0(深度mm)批量调整选择图元的高度"
	def Mov.d0(len)
		Mov.ents.transform_entities @major_movement_direction.to_a.collect{|i|i*len},Mov.sels
	end
	puts "d1(宽度mm)批量调整选择图元的高度"
	def Mov.d1(len)
		Mov.ents.transform_entities @minor_movement_direction.to_a.collect{|i|i*len},Mov.sels
	end
	puts "z(高度mm)批量调整选择图元的高度"
	def Mov.z(h)
		Mov.ents.transform_entities [0,0,h],Mov.sels
	end
	
	puts "d0c(深度mm)批量调整选择图元的高度（复制）"
	def Mov.d0c(len)
		tmp=Mov.ents.add_group Mov.sels
		grp=tmp.copy
		tmp.explode
		grp.transform! @major_movement_direction.to_a.collect{|i|i*len}
		list=grp.explode
		Mov.sels.clear
		Mov.sels.add list.collect{|i|if i.kind_of? Sketchup::Drawingelement then i else nil end}.compact
	end
	puts "d1c(宽度mm)批量调整选择图元的高度（复制）"
	def Mov.d1c(len)
		tmp=Mov.ents.add_group Mov.sels
		grp=tmp.copy
		tmp.explode
		grp.transform! @minor_movement_direction.to_a.collect{|i|i*len}
		list=grp.explode
		Mov.sels.clear
		Mov.sels.add list.collect{|i|if i.kind_of? Sketchup::Drawingelement then i else nil end}.compact
	end
	puts "zc(高度mm)批量调整选择图元的高度（复制）"
	def Mov.zc(h)
		tmp=Mov.ents.add_group Mov.sels
		grp=tmp.copy
		tmp.explode
		Mov.ents.transform_entities [0,0,h],grp
		list=grp.explode
		Mov.sels.clear
		Mov.sels.add list.collect{|i|if i.kind_of? Sketchup::Drawingelement then i else nil end}.compact
	end
	
	
	puts "setdirection设置自定义轴线方向"
	def Mov.set_direction
		begin
			@major_movement_direction=Mov.sels[0].line[1].clone
			@major_movement_direction[2]=0
			@major_movement_direction.normalize
			@minor_movement_direction=[-@major_movement_direction[1],@major_movement_direction[0],0]
			@minor_movement_direction.normalize
			
			puts "major="+@major_movement_direction.to_s
			puts "minor="+@minor_movement_direction.to_s
			
			UI.messagebox "设置成功！"
			
		rescue
			UI.messagebox "错误的轴方向设置方式，需要选择唯一的一个边线图元！"
		end
	end
	
	puts "setmovement打开新窗口设置2种步进距离"
	def Mov.set_movement
		res=UI.inputbox ["水平移动毫米数：","垂直移动毫米数："],[@movement_distance,@movement_distance_vertical],"设置移动长度"
		if res==false then return end
		@movement_distance=res[0]
		@movement_distance_vertical=res[1]
		res
	end
	def Mov.direction#返回当前视角的黄道角度分区
		ar=Mov.view.camera.direction
		ar[2]=0
		ar.normalize
		ang=Mov.clock_angle(ar,@major_movement_direction).radians
		
		#puts "ar=#{ar}"
		#puts "major=#{@major_movement_direction}"
		#puts "ang=#{ang}.degrees"
		
		if ang>45 and ang <135 then
			return 1
		elsif ang>135 and ang <225 then
			return 2
		elsif ang>225 and ang <315 then
			return 3
		elsif ang>315 or ang<45 then
			return 4
		else
			return 0
		end
	end
	def Mov.move_direction(str)#u/d/l/r/f/b 根据给定的六个视图方向返回实际xyz轴的方向
		strr=str[0]
		case strr
		when "U","u"
			return "z+"
		when "D","d"
			return "z-"
		else
			case Mov.direction
			when 4
				case strr
					when "L","l" then return "p3"
					when "F","f" then return "p2"
					when "R","r" then return "p1"
					when "B","b" then return "p0"
				end
			when 3
				case strr
					when "L","l" then return "p0"
					when "F","f" then return "p3"
					when "R","r" then return "p2"
					when "B","b" then return "p1"
				end
			when 2
				case strr
					when "L","l" then return "p1"
					when "F","f" then return "p0"
					when "R","r" then return "p3"
					when "B","b" then return "p2"
				end
			when 1
				case strr
					when "L","l" then return "p2"
					when "F","f" then return "p1"
					when "R","r" then return "p0"
					when "B","b" then return "p3"
				end
			else
				return false
			end
		end
	end
	def Mov.mov(direction,dis)#根据指定的六个方向和移动距离移动选中物体
		Sketchup.active_model.start_operation("Apiglio Move",true)
		case Mov.move_direction(direction)
			when "z+" then Mov.z dis
			when "z-" then Mov.z -dis
			when "p0" then Mov.d0 dis
			when "p1" then Mov.d1 dis
			when "p2" then Mov.d0 -dis
			when "p3" then Mov.d1 -dis
			else puts "Error direction"
		end
		Sketchup.active_model.commit_operation
	end
	def Mov.movc(direction,dis)#根据指定的六个方向和移动距离移动选中物体（复制）
		Sketchup.active_model.start_operation("Apiglio MoveCopy",true)
		case Mov.move_direction(direction)
			when "z+" then Mov.zc dis
			when "z-" then Mov.zc -dis
			when "p0" then Mov.d0c dis
			when "p1" then Mov.d1c dis
			when "p2" then Mov.d0c -dis
			when "p3" then Mov.d1c -dis
			else puts "Error direction"
		end
		Sketchup.active_model.commit_operation
	end
	
	#定义命令对象
	
	@command_list=[]#命令列表
	
	@command_list<<set_mov=UI::Command.new("设置移动长度") {Mov.set_movement}
	@command_list<<set_dir=UI::Command.new("设置主轴方向") {Mov.set_direction}
	
	@command_list<<mrm=UI::Command.new("右移动") {Mov.mov "r",@movement_distance}
	@command_list<<mrc=UI::Command.new("右复制") {Mov.movc "r",@movement_distance}
	@command_list<<mrs=UI::Command.new("右微调") {Mov.mov "r",@movement_distance/@movement_division}
	
	@command_list<<mlm=UI::Command.new("左移动") {Mov.mov "l",@movement_distance}
	@command_list<<mlc=UI::Command.new("左复制") {Mov.movc "l",@movement_distance}
	@command_list<<mls=UI::Command.new("左微调") {Mov.mov "l",@movement_distance/@movement_division}
	
	@command_list<<mfm=UI::Command.new("前移动") {Mov.mov "f",@movement_distance}
	@command_list<<mfc=UI::Command.new("前复制") {Mov.movc "f",@movement_distance}
	@command_list<<mfs=UI::Command.new("前微调") {Mov.mov "f",@movement_distance/@movement_division}
	
	@command_list<<mbm=UI::Command.new("后移动") {Mov.mov "b",@movement_distance}
	@command_list<<mbc=UI::Command.new("后复制") {Mov.movc "b",@movement_distance}
	@command_list<<mbs=UI::Command.new("后微调") {Mov.mov "b",@movement_distance/@movement_division}
	
	@command_list<<mum=UI::Command.new("上移动") {Mov.mov "u",@movement_distance_vertical}
	@command_list<<muc=UI::Command.new("上复制") {Mov.movc "u",@movement_distance_vertical}
	@command_list<<mus=UI::Command.new("上微调") {Mov.mov "u",@movement_distance_vertical/@movement_division}
	
	@command_list<<mdm=UI::Command.new("下移动") {Mov.mov "d",@movement_distance_vertical}
	@command_list<<mdc=UI::Command.new("下复制") {Mov.movc "d",@movement_distance_vertical}
	@command_list<<mds=UI::Command.new("下微调") {Mov.mov "d",@movement_distance_vertical/@movement_division}
	
	
	@command_list.each{|i|
		if i.instance_of? UI::Command then
			i.small_icon="Image.Mov\\"+i.menu_text+".svg"
			i.large_icon="Image.Mov\\"+i.menu_text+".svg"
			
		end
	}
	
	#定义工具栏
	
	@toolbar=UI::Toolbar.new "Apiglio 快速轴动"
	@toolbar.add_item set_mov
	@toolbar.add_item set_dir
	@toolbar.add_separator
	
	@toolbar.add_item mlm
	@toolbar.add_item mrm
	@toolbar.add_item mum
	@toolbar.add_item mdm
	@toolbar.add_item mfm
	@toolbar.add_item mbm
	
	@toolbar.add_separator
	
	@toolbar.add_item mlc
	@toolbar.add_item mrc
	@toolbar.add_item muc
	@toolbar.add_item mdc
	@toolbar.add_item mfc
	@toolbar.add_item mbc
	
	@toolbar.add_separator
	
	@toolbar.add_item mls
	@toolbar.add_item mrs
	@toolbar.add_item mus
	@toolbar.add_item mds
	@toolbar.add_item mfs
	@toolbar.add_item mbs
	
	@toolbar.show
	
	#定义菜单栏
	
	ext=UI.menu "Tool"
	@menu_item_list=[]
	@menu=ext.add_submenu "Apiglio 快速轴动"
	@menu_item_list<<@menu.add_item(set_mov)
	@menu_item_list<<@menu.add_item(set_dir)
	@menu.add_separator
	
	@menu_item_list<<@menu.add_item(mlm)
	@menu_item_list<<@menu.add_item(mrm)
	@menu_item_list<<@menu.add_item(mum)
	@menu_item_list<<@menu.add_item(mdm)
	@menu_item_list<<@menu.add_item(mfm)
	@menu_item_list<<@menu.add_item(mbm)
	@menu.add_separator
	
	@menu_item_list<<@menu.add_item(mlc)
	@menu_item_list<<@menu.add_item(mrc)
	@menu_item_list<<@menu.add_item(muc)
	@menu_item_list<<@menu.add_item(mdc)
	@menu_item_list<<@menu.add_item(mfc)
	@menu_item_list<<@menu.add_item(mbc)
	@menu.add_separator
	
	@menu_item_list<<@menu.add_item(mls)
	@menu_item_list<<@menu.add_item(mrs)
	@menu_item_list<<@menu.add_item(mus)
	@menu_item_list<<@menu.add_item(mds)
	@menu_item_list<<@menu.add_item(mfs)
	@menu_item_list<<@menu.add_item(mbs)
	
	@menu_item_list.each{|i|
		@menu.set_validation_proc(i){MF_ENABLED}
	}
	
	#模块变量外部调用程序
	
	def Mov.toolbar
		@toolbar
	end
	def Mov.commands
		@command_list
	end
	def Mov.menu
		@menu
	end
	def Mov.menu_item_list
		@menu_item_list
	end
	
	puts "#Module Mov has been loaded."
end

	
