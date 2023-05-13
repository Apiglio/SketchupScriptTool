#encoding "UTF-8"
#CG.rb
#Apiglio
#纯组件群组编辑方式


module Cge

	@selist=[]
	def Cge.selist
		@selist
	end


	#快捷定义区
	def Cge.sam
		Sketchup.active_model
	end
	def Cge.ents
		Sketchup.active_model.entities
	end
	def Cge.lyrs
		Sketchup.active_model.layers
	end
	def Cge.sels
		Sketchup.active_model.selection
	end
	def Cge.view
		Sketchup.active_model.active_view
	end
	
	#快速抓取定义
	
	def self.selected_one
		sels=Sketchup.active_model.selection
		if sels.length==1 then return sels[0] else return nil end
	end
	
	def self.definition(ge=nil)
		ge=selected_one if ge.nil?
		raise ArgumentError.new("A ComponentInstance or Group expected but #{ge.class} found.") unless ge.respond_to?(:definition)
		return ge.definition
	end
	def self.defin(ge)
		definition(ge)
	end
	def self.attributes(ge=nil)
		ge=selected_one if ge.nil?
		raise ArgumentError.new("A ComponentInstance or Group expected but #{ge.class} found.") unless ge.respond_to?(:definition)
		return ge.attribute_dictionaries
	end
	def self.attrs(ge)
		attributes(ge)
	end
	def self.dynamic?(ge)
		ge=selected_one if ge.nil?
		raise ArgumentError.new("A ComponentInstance or Group expected but #{ge.class} found.") unless ge.respond_to?(:definition)
		return ge.attribute_dictionaries["dynamic_attributes"]
	end
	def self.dc?(ge)
		dynamic?(ge)
	end
	def self.dynamic_group?(ge)
		ge=selected_one if ge.nil?
		raise ArgumentError.new("A Group expected but #{ge.class} found.") unless ge.is_a?(Sketchup::Group)
		return ge.attribute_dictionaries["Apiglio CGE DC Data"]
	end
	def self.dg?(ge)
		dynamic_group?(ge)
	end
	
	
	#主体功能区
	
	puts "	show_selist     将默认集selist作为选区"
	def Cge.show_selist
		while (Cge.sels.length>0)
			Cge.sels.remove Cge.sels[0]
		end
		@selist.each{|i|Cge.sels.add i}
		true
	end
	
	puts "	add_by_name(name)     将名称等于name的组件或群组加入默认集selist"
	def Cge.add_by_name(name)
		Sel.all_groups(Cge.ents).each{|i|
			case i.typename
			when "Group"
			if i.name==name then @selist<<i end
			when "ComponentInstance"
			if i.definition.name==name then @selist<<i end
			else
			#
			end
		}
		@selist
	end
	
	puts "	remove_by_name(name)     将名称等于name的组件或群组加入默认集selist"
	def Cge.remove_by_name(name)
		Sel.all_groups(Cge.ents).each{|i|
			case i.typename
			when "Group"
			if i.name==name then @selist.delete(i) end
			when "ComponentInstance"
			if i.definition.name==name then @selist.delete(i) end
			else
			#
			end
		}
		@selist
	end
	
	puts "	add_by_layer(lyr)     将图层名称等于lyr的组件或群组加入默认集selist"
	def Cge.add_by_layer(lyr)
		Sel.all_groups(Cge.ents).each{|i|
			case i.typename
			when "Group","ComponentInstance"
			if i.layer.name==lyr then @selist<<i end
			else
			#其他类型不在考虑范围内
			end
		}
		@selist
	end
	
	puts "	remove_by_layer(lyr)     将图层名称等于lyr的组件或群组加入默认集selist"
	def Cge.remove_by_layer(lyr)
		Sel.all_groups(Cge.ents).each{|i|
			case i.typename
			when "Group","ComponentInstance"
			if i.layer.name==lyr then @selist.delete(i) end
			else
			#其他类型不在考虑范围内
			end
		}
		@selist
	end
	
	#私有方法：用于查找ent所在的路径，以Hash为树结构，递归。
	def self.find_path(ent)
		res={ent=>[]}
		p=ent.parent
		res[ent]=ent.parent.instances.map{|inst|find_path(inst)} unless p.is_a?(Sketchup::Model)
		return res
	end
	private_class_method :find_path
	#私有方法：用于将Hash的树结构遍历出路径，递归。
	@hash_paths=[]
	def self.path_traverse(hash,list=nil)
		if list.nil? then
			list=[]
			@hash_paths=[]
		end
		ins=hash.keys[0]
		lst=hash.values[0]
		if lst.empty? then
			@hash_paths<<list
		else
			lst.each{|inst|
				path_traverse(inst,list+[inst])
			}
		end
		return @hash_paths
	end
	private_class_method :path_traverse
	#查找某个图元的所有可能路径
	def self.find_paths(ent)
		hash=find_path(ent)
		return path_traverse(hash).map{|i|Sketchup::InstancePath.new(i.reverse.map{|i|i.keys[0]})}
	end
	#查找当前路径中的可能图元路径
	def self.find_paths_in_active(ent,ap=Sketchup.active_model.active_path)
		list=find_paths(ent)
		ap=[] if ap.nil?
		list.reject!{|path|
			path.to_a[0...ap.length]!=ap
		} unless ap.empty?
		return list
	end
	
	#给定一个图元，向下查找[entity,InstancePath]
	def self.find_paths_downward(entity,instance_path=[],init_res=[])
		res = init_res
		case entity
		when Sketchup::Group
			entity.definition.entities.each{|ent|
				res=find_paths_downward(ent,instance_path+[entity],res)
			}
		when Sketchup::ComponentInstance
			entity.definition.entities.each{|ent|
				res=find_paths_downward(ent,instance_path+[entity],res)
			}
		else
			res.push(instance_path+[entity])
		end
		return res
	end

	def self.build_connective_group(arr)
		Sketchup.active_model.start_operation("非接触组件创建",true)
		list=arr.to_a
		while list.length !=0 do
			begin
				tmp=list[0].all_connected
				pp=list[0].parent
				pp=Sketchup.active_model if pp.nil?
				pp.entities.add_group(tmp)
				list-=tmp
			rescue
				break
			end
		end
		Sketchup.active_model.commit_operation
	end
	
	module MoveTool
		#这里更新一个根据选择的组件坐标轴的平移操作
		
		@move_unit=100.mm
		@move_copy=false
		
		def self.xaxis(ins)
			ins.transformation.xaxis.normalize
		end
		def self.yaxis(ins)
			ins.transformation.yaxis.normalize
		end
		def self.zaxis(ins)
			ins.transformation.zaxis.normalize
		end
		
		def self.move_unit=(value)
			@move_unit=value
		end
		def self.move_unit
			@move_unit
		end
		def self.move_copy=(value)
			@move_copy=value
		end
		def self.move_copy
			@move_copy
		end
		
		def self.attribute_copy(src,dest)
			src.attribute_dictionaries.each{|attr|
				src.attribute_dictionaries[attr.name].each{|k,v|
					dest.set_attribute(attr.name,k,v)
				}
			}unless src.attribute_dictionaries.nil?
			dest.layer=src.layer
		end		
		
		def self.x_move(ins,dist)
			return nil if ins.nil?
			Sketchup.active_model.start_operation("Apiglio Cge MovTool",true)
			vec=xaxis(ins)
			vec.length=dist
			t=Geom::Transformation.translation(vec)
			if @move_copy then
				g=ins.parent.entities.add_instance(ins.definition,t*ins.transformation)
				attribute_copy(ins,g)
				Sketchup.active_model.selection.clear
				Sketchup.active_model.selection.add(g)				
			else
				ins.parent.entities.transform_entities(t,ins)
			end
			Sketchup.active_model.commit_operation
		end
		def self.y_move(ins,dist)
			return nil if ins.nil?
			Sketchup.active_model.start_operation("Apiglio Cge MovTool",true)
			vec=yaxis(ins)
			vec.length=dist
			t=Geom::Transformation.translation(vec)
			if @move_copy then
				g=ins.parent.entities.add_instance(ins.definition,t*ins.transformation)
				attribute_copy(ins,g)
				Sketchup.active_model.selection.clear
				Sketchup.active_model.selection.add(g)				
			else
				ins.parent.entities.transform_entities(t,ins)
			end
			Sketchup.active_model.commit_operation
		end
		def self.z_move(ins,dist)
			return nil if ins.nil?
			Sketchup.active_model.start_operation("Apiglio Cge MovTool",true)
			vec=zaxis(ins)
			vec.length=dist
			t=Geom::Transformation.translation(vec)
			if @move_copy then
				g=ins.parent.entities.add_instance(ins.definition,t*ins.transformation)
				attribute_copy(ins,g)
				Sketchup.active_model.selection.clear
				Sketchup.active_model.selection.add(g)
			else
				ins.parent.entities.transform_entities(t,ins)
			end
			Sketchup.active_model.commit_operation
		end
		def self.get_the_only_sel
			sels=Sketchup.active_model.selection
			if sels.length==1 then return sels[0]
			else return nil end
		end
		private_class_method :get_the_only_sel
		def self.show_window
			@viewerWindow = UI::HtmlDialog.new(
			{
			  :dialog_title => "Apiglio Cge MovTool",
			  :preferences_key => "- Apiglio -",
			  :scrollable => true,
			  :resizable => true,
			  :width => 100,
			  :height => 200,
			  :left => 100,
			  :top => 100,
			  :min_width => 50,
			  :min_height => 50,
			  :max_width =>400,
			  :max_height =>600,
			  :style => UI::HtmlDialog::STYLE_UTILITY
			})
			_html=File.read(__dir__+"/UI/MovTool.html")

			@viewerWindow.add_action_callback("x_positive"){|action_context,value|
				x_move(get_the_only_sel,@move_unit) unless get_the_only_sel.nil?}
			@viewerWindow.add_action_callback("x_negative"){|action_context,value|
				x_move(get_the_only_sel,-@move_unit) unless get_the_only_sel.nil?}
			@viewerWindow.add_action_callback("y_positive"){|action_context,value|
				y_move(get_the_only_sel,@move_unit) unless get_the_only_sel.nil?}
			@viewerWindow.add_action_callback("y_negative"){|action_context,value|
				y_move(get_the_only_sel,-@move_unit) unless get_the_only_sel.nil?}
			@viewerWindow.add_action_callback("z_positive"){|action_context,value|
				z_move(get_the_only_sel,@move_unit) unless get_the_only_sel.nil?}
			@viewerWindow.add_action_callback("z_negative"){|action_context,value|
				z_move(get_the_only_sel,-@move_unit) unless get_the_only_sel.nil?}
			@viewerWindow.add_action_callback("set_move_unit"){|action_context,value|
				@move_unit=value.to_f.mm}
			@viewerWindow.add_action_callback("get_move_unit"){|action_context|
				return @move_unit.to_mm.to_s}
			@viewerWindow.add_action_callback("set_move_copy"){|action_context,value|
				@move_copy=value}
			@viewerWindow.add_action_callback("get_move_copy"){|action_context|
				return @move_copy}
			@viewerWindow.add_action_callback("value_update"){|action_context|
				@viewerWindow.execute_script("dialogInit(#{@move_copy},#{@move_unit.to_mm.to_s})")}
			@viewerWindow.set_html(_html)
			@viewerWindow.show
		end

		
		class OrthoMov
			def activate
				MoveTool.show_window()
				Sketchup.active_model.select_tool(nil)
			end
		end
		
	end
	
	
	module Move
	
		def self.ground(sels=nil)
			Sketchup.active_model.start_operation("Cge::Move.ground",true)
			sels=Sketchup.active_model.selection.to_a if sels.nil?
			sels.select{|i|i.respond_to?(:definition)}.each{|i|
				v=i.bounds.corner(0)-i.bounds.corner(2)
				v.length=v.length/2
				p=i.bounds.corner(2)+v
				t=Geom::Transformation.translation([0,0,-p[2]])
				i.parent.entities.transform_entities(t,i)
			}
			Sketchup.active_model.commit_operation
		end
		
		def self.align(mode,sels=nil)
			sels=Sketchup.active_model.selection.to_a if sels.nil?
			limit=(mode[1]=="+")? -Float::INFINITY : Float::INFINITY
			sels.select{|i|i.respond_to?(:definition)}.each{|i|
				case mode
					when "x+" then limit=(limit<i.bounds.max.x)? i.bounds.max.x : limit
					when "y+" then limit=(limit<i.bounds.max.y)? i.bounds.max.y : limit
					when "z+" then limit=(limit<i.bounds.max.z)? i.bounds.max.z : limit
					when "x-" then limit=(limit>i.bounds.min.x)? i.bounds.min.x : limit
					when "y-" then limit=(limit>i.bounds.min.y)? i.bounds.min.y : limit
					when "z-" then limit=(limit>i.bounds.min.z)? i.bounds.min.z : limit
				end
			}
			raise ArgumentError.new("Not Any Instance Found") if limit.nil?
			#p limit
			Sketchup.active_model.start_operation("Cge::Move.align",true)
			t=nil
			sels.select{|i|i.respond_to?(:definition)}.each{|i|
				case mode
					when "x+" then t=Geom::Transformation.translation([limit-i.bounds.max.x,0,0])
					when "y+" then t=Geom::Transformation.translation([0,limit-i.bounds.max.y,0])
					when "z+" then t=Geom::Transformation.translation([0,0,limit-i.bounds.max.z])
					when "x-" then t=Geom::Transformation.translation([limit-i.bounds.min.x,0,0])
					when "y-" then t=Geom::Transformation.translation([0,limit-i.bounds.min.y,0])
					when "z-" then t=Geom::Transformation.translation([0,0,limit-i.bounds.min.z])
				end
				i.parent.entities.transform_entities(t,i)
			}
			Sketchup.active_model.commit_operation
		end
		
		def self.axp(sel=nil) align("x+",sel) end
		def self.axn(sel=nil) align("x-",sel) end
		def self.ayp(sel=nil) align("y+",sel) end
		def self.ayn(sel=nil) align("y-",sel) end
		def self.azp(sel=nil) align("z+",sel) end
		def self.azn(sel=nil) align("z-",sel) end
		
		
		
		
		
	end
	
	#形变判断工具
	module Deform
	
		def self.each_pair(enmerable_instance,&block)
			list_1=enmerable_instance.to_a
			list_2=enmerable_instance.to_a
			for i in 0..list_1.length-1 do
				for j in i+1..list_2.length-1 do
					block.call(list_1[i],list_2[j])
				end
			end
			nil
		end
		private_class_method :each_pair
		
		#判断组件变换是否正交
		def self.orthogonal?(ins)
			return nil unless ins.respond_to?(:transformation)
			t=ins.transformation
			return nil if t.nil?
			return (t.xaxis.perpendicular?(t.yaxis) and t.zaxis.perpendicular?(t.yaxis) and t.xaxis.perpendicular?(t.zaxis))
		end
		#判断组件内平面的边线是否相互垂直
		def self.edge_orthogonal?(ins,tolerance=3)
			return nil unless ins.respond_to?(:definition)
			d=ins.definition
			edges=d.entities.grep(Sketchup::Edge)
			vecs=edges.map!{|i|i.line[1].to_a.map{|n|n.round(tolerance)*(n<0 ? -1 :1)}}.uniq
			return false if vecs.length>3
			each_pair(vecs){|i,j|return false unless Geom::Vector3d.new(i).perpendicular?(j)}
			return true
		end
		
		def self.edge_vectors(ins,tolerance=3)
			return nil unless ins.respond_to?(:definition)
			d=ins.definition
			edges=d.entities.grep(Sketchup::Edge)
			vecs=edges.map!{|i|i.line[1].to_a.map{|n|n.round(tolerance)*(n<0 ? -1 :1)}}.uniq
			return vecs
		end
		
		
		
	end
	
	#定义冲突协调与清理
	module Defs
		
		#清除未使用的组件定义
		#这不就是purge_unused吗？？？
		def self.cleaner
			defs=Sketchup.active_model.definitions
			useless=defs.select{|i|i.instances.empty?}
			useless.each{|i|defs.remove(i)}.length
		end
		
		#独立每一个群组
		def self.group_uniq!
			defs=Sketchup.active_model.definitions.to_a
			defs.select!(&:group?)
			acc=0
			defs.each{|d|
				instances=d.instances
				instances.shift
				acc+=instances.length
				instances.each(&:make_unique)
			}
			acc
		end
		
		#合并两个组件定义，并删去后一个定义
		def self.combine(def_1,def_2)
			unless def_1.is_a?(Sketchup::ComponentDefinition) then
				raise ArgumentError.new("主定义不是ComponentDefinition") unless def_1.is_a?(String)
				def_1=Sketchup.active_model.definitions[def_1]
			end
			unless def_2.is_a?(Sketchup::ComponentDefinition) then
				raise ArgumentError.new("副定义不是ComponentDefinition") unless def_2.is_a?(String)
				def_2=Sketchup.active_model.definitions[def_2]
			end
			list=def_2.instances
			list.each{|i|
				i.definition=def_1
			}
			Sketchup.active_model.definitions.remove(def_2)
			nil
		end
		
		#合并所有带#号的组件定义（保留不带星号的）
		def self.restore
			list=Sketchup.active_model.definitions.reject{|i|i.group? or i.image?}
			list.reject!{|i|i.name.index("#").nil?}
			list.each{|i|
				ori_name=i.name[0,i.name.index("#")]
				if Sketchup.active_model.definitions[ori_name].nil? then
					puts "将组件“#{i.name}”重命名为“#{ori_name}”。"
					i.name=ori_name
				else
					puts "将组件“#{i.name}”还原至组件“#{ori_name}”。"
					self.combine(ori_name,i.name)
				end
			}
			nil
		end
		
		#合并所有带#号的组件定义（保留不带星号的）
		def self.update
			list=Sketchup.active_model.definitions.reject{|i|i.group? or i.image?}
			list.reject!{|i|i.name.index("#").nil?}
			list.each{|i|
				ori_name=i.name[0,i.name.index("#")]
				if Sketchup.active_model.definitions[ori_name].nil? then
					puts "将组件“#{i.name}”重命名为“#{ori_name}”。"
					i.name=ori_name
				else
					puts "将组件“#{i.name}”更新成组件“#{ori_name}”，名称保留。"
					self.combine(i,ori_name)
					i.name=ori_name
				end
			}
			nil
		end
		
		#将aDef全部原位置提取到最外层以达到扁平化组件结构的效果
		def self.flat(aDef)
			Sketchup.active_model.start_operation("Cge::Defs扁平化")
			need_to_placed=[]
			need_to_flatten=[]
			aDef.instances.each{|ins|
				p=ins.parent
				if p.is_a?(Sketchup::ComponentDefinition) then
					need_to_placed+=Cge.find_paths(ins).map{|p|ins.transformation*p.transformation}
					need_to_flatten<<p
				end
			}
			need_to_placed.each{|trans|
				Sketchup.active_model.entities.add_instance(aDef,trans)
			}
			need_to_deleted=[]
			need_to_flatten.uniq.each{|defi|
				need_to_erased=defi.entities.select{|ent|ent.respond_to?(:definition)}
				need_to_erased.select!{|ent|ent.definition==aDef}
				defi.entities.erase_entities(need_to_erased.uniq)
				need_to_deleted<<defi if defi.entities.length==0
			}
			need_to_deleted.each{|defi|Sketchup.active_model.definitions.remove(defi)}
			Sketchup.active_model.commit_operation()
		end
		
		#原位置原大小替换组件
		def self.replace_by_trse(aIns,aDef)
			#保持aIns的BoundingBox属性替换定义为aDef
			raise ArgumentError unless aIns.is_a?(Sketchup::ComponentInstance)
			raise ArgumentError unless aDef.is_a?(Sketchup::ComponentDefinition)
			#判断参数类型是否正确
			Sketchup.active_model.start_operation("replace by trse",true)
			#开始一个新的可撤销操作，用于撤销
			b1=aIns.definition.bounds
			b2=aDef.bounds
			sw=b1.width/b2.width
			sh=b1.height/b2.height
			sd=b1.depth/b2.depth
			#获取定义内图元范围的尺度比例
			#即替换前后定义的EBCD的长高宽比例
			ts=Geom::Transformation.scaling(sw,sh,sd)   #计算用于调整组件大小的缩放变换
			trse=aIns.cge.trse                          #因式分解组件实例的位置
			aIns.definition=aDef                        #替换组件实例的定义
			aIns.transformation=trse[0]*trse[1]*trse[2]*trse[3]*ts
			#将新的组合变换赋值给组件实例
			Sketchup.active_model.commit_operation
			#提交可撤销操作，用于撤销
		end
		
		
	end
	
	#动态组件工具
	module DC
		
		def self.grp_hash(instance)
			raise ArgumentError.new("Group expected but #{instance.class} found.") unless instance.is_a?(Sketchup::Group)
			raise ArgumentError.new("Parameter is NOT a dynamic component.") unless instance.attribute_dictionary("dynamic_attributes")
			return instance.attribute_dictionaries["dynamic_attributes"].to_h
		end
		def self.ins_hash(instance)
			raise ArgumentError.new("ComponentInstance expected but #{instance.class} found.") unless instance.is_a?(Sketchup::ComponentInstance)
			raise ArgumentError.new("Parameter is NOT a dynamic component.") unless instance.attribute_dictionary("dynamic_attributes")
			return instance.attribute_dictionaries["dynamic_attributes"].to_h
		end
		def self.def_hash(instance)
			raise ArgumentError.new("ComponentInstance expected but #{instance.class} found.") unless instance.is_a?(Sketchup::ComponentInstance)
			raise ArgumentError.new("Parameter is NOT a dynamic component.") unless instance.definition.attribute_dictionary("dynamic_attributes")
			return instance.definition.attribute_dictionaries["dynamic_attributes"].to_h
		end
		
		def self.set_hash(instance,hash,is_redraw=true)
			hash.each{|k,v|
				instance.set_attribute("dynamic_attributes",k,v)
			}
			redraw(instance) if is_redraw
		end
		def self.add_hash_if_not_defined(instance,hash,is_redraw=true)
			hash.each{|k,v|
				tmp=instance.get_attribute("dynamic_attributes",k)
				#p tmp
				if tmp.nil? then
					instance.set_attribute("dynamic_attributes",k,v)
				end
			}
			redraw(instance) if is_redraw
		end
		
		# by @DanRathbun https://forums.sketchup.com/t/method-to-ask-a-dynamic-component-instance-to-recalc-itself/13905
		# partially modified
		def self.redraw(inst,with_undo=true)
		  return nil unless defined?($dc_observers)
		  if inst.is_a?(Sketchup::ComponentInstance) &&
		  inst.attribute_dictionary('dynamic_attributes')
		    if with_undo then
			  $dc_observers.get_latest_class.redraw_with_undo(inst)
			else
			  $dc_observers.get_latest_class.redraw(inst)
			end
		  end
		  nil # (there is no particular return value)
		end
		
		#更新组件并重绘
		def self.update(defi,sels=nil)
			raise ArgumentError.new("ComponentDefinition expected but #{defi.class} found.") unless defi.is_a?(Sketchup::ComponentDefinition)
			raise ArgumentError.new("Parameter is NOT a dynamic component.") unless defi.attribute_dictionary("dynamic_attributes")
			sels=Sketchup.active_model.selection.to_a if sels.nil?
			sels=[sels] unless sels.is_a?(Array)
			sels.each{|i|
				next unless i.is_a?(Sketchup::ComponentInstance)
				next unless i.attribute_dictionary("dynamic_attributes")
				hash=i.attribute_dictionary("dynamic_attributes").to_h
				i.definition=defi
				hash.each{|k,v|
					i.set_attribute("dynamic_attributes",k,v)
				}
				redraw(i)
			}
			nil
		end
		
		#将动态组件炸开成CGE_DC群组
		def self.dc_to_dg(instance)
			mat=instance.transformation.to_a
			hash=ins_hash(instance)
			new_group=instance.parent.entities.add_group(instance)
			set_hash(new_group,hash)
			new_group.set_attribute("Apiglio CGE DC Data","transformation",mat)
			instance.explode
		end
		
		#将CGE_DC群组重新转化成动态组件
		def self.dg_to_dc(group,definition)
			raise ArgumentError.new("Param1: Group expected but #{group.class} found.") unless group.is_a?(Sketchup::Group)
			raise ArgumentError.new("Param2: ComponentDefinition expected but #{definition.class} found.") unless definition.is_a?(Sketchup::ComponentDefinition)
			raise ArgumentError.new("Parameter is NOT a CGE_DC group.") unless group.attribute_dictionary("Apiglio CGE DC Data")
			mat=group.get_attribute("Apiglio CGE DC Data","transformation")
			t=Geom::Transformation.new(mat)
			new_instance=group.parent.entities.add_instance(definition,t)
			hash=grp_hash(group)
			set_hash(new_instance,hash)
			group.erase!
			redraw(new_instance)
		end
		
		def self.dg!(arr=nil)
			arr=Sketchup.active_model.selection.to_a if arr.nil?
			return nil if arr.nil?
			arr.select!{|i|i.is_a?(Sketchup::ComponentInstance)}
			arr.select!{|i|Cge.dc?(i)}
			Sketchup.active_model.start_operation("动态组件解构保存",true)
			begin
				arr.each{|i|
					dc_to_dg(i)
				}
			rescue
				Sketchup.active_model.abort_operation
				return false
			end
			Sketchup.active_model.commit_operation
		end
		
		def self.dc!(definition,arr=nil)
			raise ArgumentError.new("ComponentDefinition is expected but #{definition.class} found.") unless definition.is_a?(Sketchup::ComponentDefinition)
			arr=Sketchup.active_model.selection.to_a if arr.nil?
			return nil if arr.nil?
			arr.select!{|i|i.is_a?(Sketchup::ComponentInstance)}
			arr.select!{|i|Cge.dc?(i)}
			Sketchup.active_model.start_operation("解构的动态组件恢复",true)
			begin
				arr.each{|i|
					dg_to_dc(i,definition)
				}
			rescue
				Sketchup.active_model.abort_operation
				return false
			end
			Sketchup.active_model.commit_operation
		end
		
		#each_attr("Wall_Height"){|attr|puts attr}
		def self.each_attr(attr_name,arr=nil,need_redraw=true,&block)
			arr=Sketchup.active_model.selection.to_a if arr.nil?
			arr=[arr] unless arr.respond_to?(:[])
			arr.each{|i|
				next unless Cge.dc?(i)
				block.call(
					i.get_attribute("dynamic_attributes",attr_name.downcase)
				)
			}
		end
		#each_attr!("Wall_Height"){|attr|90.m}
		def self.each_attr!(attr_name,arr=nil,need_redraw=true,&block)
			arr=Sketchup.active_model.selection.to_a if arr.nil?
			arr=[arr] unless arr.respond_to?(:[])
			Sketchup.active_model.start_operation("Cge::DC.each_attr!",true)
			attr_name.downcase!
			arr.each{|i|
				next unless Cge.dc?(i)
				next unless i.attribute_dictionaries["dynamic_attributes"].keys.include?(attr_name)
				res=block.call(i.get_attribute("dynamic_attributes",attr_name))
				case i.get_attribute("dynamic_attributes","_lengthunits")
					when "CENTIMETERS" then res=res.to_f.to_s
					when "INCHES" then res=res.to_f.to_s
				end
				i.set_attribute("dynamic_attributes",attr_name,res)
				self.redraw(i,false) if need_redraw
			}
			Sketchup.active_model.commit_operation
		end
		
		def self.dynamize!(ins)
			ins.definition.set_attribute("dynamic_attributes","_formatversion",1.0)
			ins.definition.set_attribute("dynamic_attributes","_has_movetool_behaviors",0.0)
			ins.definition.set_attribute("dynamic_attributes","_lastmodified",Time.now.to_s[0..-7])
			ins.definition.set_attribute("dynamic_attributes","_lengthunits","CENTIMETERS")
			ins.definition.set_attribute("dynamic_attributes","_name",ins.definition.name)
			ins.set_attribute("dynamic_attributes","_has_movetool_behaviors",0.0)
			ins.set_attribute("dynamic_attributes","_lengthunits","CENTIMETERS")
			ins.set_attribute("dynamic_attributes","_name",ins.definition.name)
		end
		
		def self.new_attrs(ins,name,other_option={})
			dynamize!(ins) unless Cge.dc?(ins)
			
			label=other_option[:label]
			access=other_option[:access]
			formulaunits=other_option[:formulaunits]
			options=other_option[:options]
			units=other_option[:units]
			value=other_option[:value]
			
			label=name.capitalize if label.nil?
			access="NONE" if access.nil?
			formulaunits="CENTIMETERS" if formulaunits.nil?
			options="&" if options.nil?
			units="CENTIMETERS" if units.nil?
			
			#_access        #|TEXTBOX|LIST|VIEW|NONE
			#_formulaunits  #|FLOAT|STRING|INCHES|CENTIMETERS
			#_options       #|&|&k1=1&k2=2&k3=3&
			#_units         #|DEGREES|DEFAULT|INTEGER|FLOAT|BOOLEAN|PERCENT|INCHES|FEET|MILLIMETERS|CENTIMETERS|METER|DOLLARS|EUROS|YEN|POUNDS|KILOGRAMS
			
			ins.definition.set_attribute("dynamic_attributes",name,value)
			ins.set_attribute("dynamic_attributes",name,value)
			ins.definition.set_attribute("dynamic_attributes","_"+name+"_label",label)
			ins.definition.set_attribute("dynamic_attributes","_"+name+"_access",access)
			ins.definition.set_attribute("dynamic_attributes","_"+name+"_formulaunits",formulaunits)
			ins.definition.set_attribute("dynamic_attributes","_"+name+"_options",options)
			ins.definition.set_attribute("dynamic_attributes","_"+name+"_units",units)
			
		end
		
	end
	

	module PlaceTool
		class AxesInstance
			STATE_DEFAULT = 0 #未选择原点或设置尺寸大小
			STATE_X_AXIS  = 1 #设置x轴方向
			STATE_Y_AXIS  = 2 #设置y轴方向
			STATE_Z_AXIS  = 3 #设置z轴方向
			#STATE_SCALES = 4 #设置尺寸大小
			STATE_XY_AXIS = 5 #设置xy轴方向
			STATE_XZ_AXIS = 6 #设置xz轴方向
			STATE_YZ_AXIS = 7 #设置yz轴方向
			def initialize(min_scale=1.mm,min_angle=1.degrees)
				@scale_limit = min_scale
				@angle_limit = min_angle
			end
			def activate()
				@point1 = Geom::Point3d.new([0,0,0]) #原点
				@point2 = Geom::Point3d.new([0,0,0]) #始终表示鼠标指针的位置
				@has_origin = false
				@x_axis = Geom::Vector3d.new([1,0,0])
				@y_axis = Geom::Vector3d.new([0,1,0])
				@z_axis = Geom::Vector3d.new([0,0,1])
				@trans  = Geom::Transformation.new
				@state  = STATE_DEFAULT
				defname = UI.inputbox(["放置组件"],[""],[Sketchup.active_model.definitions.map(&:name).join("|")],"选择组件")
				if not defname then
					Sketchup.active_model.select_tool(nil)
					return defname
				end
				raise Exception.new('未找到对应组件') if defname==[""]
				@defin  = Sketchup.active_model.definitions[defname[0]]
				@x_axis_rs = Geom::Vector3d.new(@x_axis)
				@y_axis_rs = Geom::Vector3d.new(@y_axis)
				@z_axis_rs = Geom::Vector3d.new(@z_axis)
				@x_axis_rs.length = @defin.bounds.width
				@y_axis_rs.length = @defin.bounds.height
				@z_axis_rs.length = @defin.bounds.depth
				save_args()
				@xaxis_shift = false
				@yaxis_ctrl  = false
				@zaxis_alt   = false
			end
			def update_axes()
				vec = @point2 - @point1
				case @state
				when STATE_DEFAULT
					x_len = @x_axis.dot(vec) / @x_axis.length
					y_len = @y_axis.dot(vec) / @y_axis.length
					z_len = @z_axis.dot(vec) / @z_axis.length
					x_len = @defin.bounds.width  unless x_len.abs > @scale_limit
					y_len = @defin.bounds.height unless y_len.abs > @scale_limit
					z_len = @defin.bounds.depth  unless z_len.abs > @scale_limit
					if @has_origin then
						@x_axis_rs.length = x_len
						@y_axis_rs.length = y_len
						@z_axis_rs.length = z_len
					end
					x_len /= @defin.bounds.width
					y_len /= @defin.bounds.height
					z_len /= @defin.bounds.depth
					if @has_origin then
						@x_axis.length = x_len
						@y_axis.length = y_len
						@z_axis.length = z_len
					end
				else
					return nil unless @has_origin
					case @state
					when STATE_X_AXIS
						@x_axis_rs = vec
						@x_axis = @x_axis_rs.clone
						@x_axis.length = @x_axis_rs.length / @defin.bounds.width
					when STATE_Y_AXIS
						@y_axis_rs = vec
						@y_axis = @y_axis_rs.clone
						@y_axis.length = @y_axis_rs.length / @defin.bounds.height
					when STATE_Z_AXIS
						@z_axis_rs = vec
						@z_axis = @z_axis_rs.clone
						@z_axis.length = @z_axis_rs.length / @defin.bounds.depth
					when STATE_YZ_AXIS
						@x_axis_rs = vec - @y_axis_rs - @z_axis_rs
						@x_axis = @x_axis_rs.clone
						@x_axis.length = @x_axis_rs.length / @defin.bounds.width
					when STATE_XZ_AXIS
						@y_axis_rs = vec - @x_axis_rs - @z_axis_rs
						@y_axis = @y_axis_rs.clone
						@y_axis.length = @y_axis_rs.length / @defin.bounds.height
					when STATE_XY_AXIS
						@z_axis_rs = vec - @x_axis_rs - @y_axis_rs
						@z_axis = @z_axis_rs.clone
						@z_axis.length = @z_axis_rs.length / @defin.bounds.depth
					end
					x_len = @x_axis.length
					y_len = @y_axis.length
					z_len = @z_axis.length
				end
				ta = Geom::Transformation.axes(@point1,@x_axis,@y_axis,@z_axis)
				ts = Geom::Transformation.scaling(x_len,y_len,z_len)
				@trans = ta*ts
			end
			def save_args()
				@preserve_axes = [@point1,@x_axis_rs,@y_axis_rs,@z_axis_rs,@x_axis,@y_axis,@z_axis]
			end
			def reset_args()
				@point1,@x_axis_rs,@y_axis_rs,@z_axis_rs,@x_axis,@y_axis,@z_axis = *@preserve_axes
			end
			def update_state()
				t = true
				f = false
				case [@xaxis_shift,@yaxis_ctrl,@zaxis_alt]
					when [t,t,t] then
						@state = STATE_DEFAULT
						@x_axis = Geom::Vector3d.new([1,0,0])
						@y_axis = Geom::Vector3d.new([0,1,0])
						@z_axis = Geom::Vector3d.new([0,0,1])
						save_args()
					when [t,t,f] then @state = STATE_XY_AXIS
					when [t,f,t] then @state = STATE_XZ_AXIS
					when [t,f,f] then @state = STATE_X_AXIS
					when [f,t,t] then @state = STATE_YZ_AXIS
					when [f,t,f] then @state = STATE_Y_AXIS
					when [f,f,t] then @state = STATE_Z_AXIS
					when [f,f,f] then @state = STATE_DEFAULT
				end
				reset_args()
			end
			def do_place()
				Sketchup.active_model.start_operation("自定义轴放置组件")
				Sketchup.active_model.active_entities.add_instance(@defin,@trans)
				Sketchup.active_model.commit_operation()
			end
			def onLButtonUp(flags,x,y,view)
				ip = view.inputpoint(x,y)
				tmp = ip.position
				case @state
				when STATE_DEFAULT
					if @has_origin then
						do_place()
						@has_origin = false
					else
						@point1 = tmp
						@has_origin = true
						save_args()
					end
				when STATE_X_AXIS,STATE_Y_AXIS,STATE_Z_AXIS
					@state = STATE_DEFAULT
					save_args()
				when STATE_XY_AXIS,STATE_XZ_AXIS,STATE_YZ_AXIS
					@state = STATE_DEFAULT
					do_place()
					@has_origin = false
				end
			end
			def onCancel(reason, view)
				@has_origin = false
			end
			def onMouseMove(flags,x,y,view)
				ip = view.inputpoint(x,y)
				@point2 = ip.position
				case @state
				when STATE_DEFAULT
					@point1 = @point2 unless @has_origin
				end
				update_axes()
				draw(view)
			end
			def onKeyDown(key,repeat,flags,view)
				case key
					when VK_SHIFT   then @xaxis_shift = true
					when VK_CONTROL then @yaxis_ctrl  = true
					when VK_ALT     then @zaxis_alt   = true
				end
				update_state()
				if key == VK_ALT then return true else return false end
			end
			def onKeyUp(key,repeat,flags,view)
				case key
					when VK_SHIFT   then @xaxis_shift = false
					when VK_CONTROL then @yaxis_ctrl  = false
					when VK_ALT     then @zaxis_alt   = false
				end
				update_state()
				if key == VK_ALT then return true else return false end
			end
			def getExtents
				bb = Geom::BoundingBox.new
				pts = 0.upto(7).map{|i|@defin.bounds.corner(i)}
				bb.add(pts)
				bb.add(@point2)
				bb.add(@point1)
				return bb
			end
			def draw_entity(view,entity,trans,face_color="gray",edge_color="red")
				paths = Cge.find_paths_downward(entity)
				paths.reject!{|ent|ent.last.hidden?}
				edge_paths=paths.clone
				face_paths=paths
				face_paths.select!{|path|
					path.last.is_a?(Sketchup::Face)
				}
				edge_paths.select!{|path|
					path.last.is_a?(Sketchup::Edge)
				}
				if face_color.downcase != "none" then
					view.drawing_color=face_color
					face_paths.each{|path|
						face = path.last
						ms = face.mesh
						vs = ms.polygons.map{|tri|tri.map{|idx|ms.point_at(idx.abs)}}
						tr = trans * Sketchup::InstancePath.new(path).transformation
						vs.map!{|tri|tri.map{|v|tr*v}}
						view.draw(GL_TRIANGLES,vs.flatten,normals:[face.normal]*vs.flatten.length)
					}
				end
				if edge_color.downcase != "none" then
					view.drawing_color=edge_color
					edge_paths.each{|path|
						v1 = path.last.start.position
						v2 = path.last.end.position
						tr = Sketchup::InstancePath.new(path).transformation
						view.draw_polyline(v1.transform(trans*tr),v2.transform(trans*tr))
					}
				end
			end
			def draw(view)
				if @has_origin then
				case @state
				when STATE_X_AXIS
					view.drawing_color="red"
					view.line_width=5
					view.draw_polyline(@point1,@point2)
				when STATE_Y_AXIS
					view.drawing_color="green"
					view.line_width=5
					view.draw_polyline(@point1,@point2)
				when STATE_Z_AXIS
					view.drawing_color="blue"
					view.line_width=5
					view.draw_polyline(@point1,@point2)
				when STATE_XY_AXIS
					px  = @point1 + @x_axis_rs
					py  = @point1 + @y_axis_rs
					pxy = @point1 + @x_axis_rs + @y_axis_rs
					view.drawing_color="yellow"
					view.line_width=5
					view.draw_polyline(@point1,px,pxy,py,@point1)
					view.drawing_color="blue"
					view.line_width=5
					view.draw_polyline(pxy,@point2)
				when STATE_XZ_AXIS
					px  = @point1 + @x_axis_rs
					pz  = @point1 + @z_axis_rs
					pxz = @point1 + @x_axis_rs + @z_axis_rs
					view.drawing_color="violet"
					view.line_width=5
					view.draw_polyline(@point1,px,pxz,pz,@point1)
					view.drawing_color="green"
					view.line_width=5
					view.draw_polyline(pxz,@point2)
				when STATE_YZ_AXIS
					py  = @point1 + @y_axis_rs
					pz  = @point1 + @z_axis_rs
					pyz = @point1 + @y_axis_rs + @z_axis_rs
					view.drawing_color="cyan"
					view.line_width=5
					view.draw_polyline(@point1,py,pyz,pz,@point1)
					view.drawing_color="red"
					view.line_width=5
					view.draw_polyline(pyz,@point2)
				end
				end
				#view.drawing_color="gray"
				#view.drawing_color="red"
				view.line_width=2
				@defin.entities.each{|ent|
					draw_entity(view,ent,@trans,"gray","red")
				}
				view.draw_points(@point1,6,2,"black")
				view.draw_points(@point2,6,1,"black")
				tip_vice = "|Shift键 = 调整组件x轴。|Ctrl键 = 调整组件y轴。|Alt键 = 调整组件z轴。|两键组合 = 固定两轴模式。|三键组合 = 重置组件轴方向。"
				case @state
					when STATE_DEFAULT
						if @has_origin then
							Sketchup.set_status_text("点击确定对角线端点。"+tip_vice,SB_PROMPT)
						else
							Sketchup.set_status_text("点击设置组件放置原点。",SB_PROMPT)
						end
					when STATE_X_AXIS  then Sketchup.set_status_text("设置组件x轴。"+tip_vice,SB_PROMPT)
					when STATE_Y_AXIS  then Sketchup.set_status_text("设置组件y轴。"+tip_vice,SB_PROMPT)
					when STATE_Z_AXIS  then Sketchup.set_status_text("设置组件z轴。"+tip_vice,SB_PROMPT)
					when STATE_XY_AXIS then Sketchup.set_status_text("固定组件xy轴放置组件。"+tip_vice,SB_PROMPT)
					when STATE_XZ_AXIS then Sketchup.set_status_text("固定组件xz轴放置组件。"+tip_vice,SB_PROMPT)
					when STATE_YZ_AXIS then Sketchup.set_status_text("固定组件yz轴放置组件。"+tip_vice,SB_PROMPT)
				end
				view.invalidate
			end
		end
	end
	
	
	
	#工具栏命令初始化
	
	
	
	class CgeHelper
		def initialize(sender)
			@cg=sender
		end
		def test
			UI.messagebox(@cg)
		end

		#将一个变换分解出平移(T)、旋转(R)、缩放(S)三个变换及其计算的残余(E)
		def CgeHelper.trans_to_trse(trans)
			tmp=Geom::Transformation.new(trans)
			t=Geom::Transformation.new([1,0,0,0,0,1,0,0,0,0,1,0]+tmp.to_a[12..15])
			tmp=t.inverse*tmp
			#分解出平移分量，并从变换组合中移除此变换
			xx=tmp.xaxis       #获取剩余变换后的x轴
			yy=tmp.yaxis       #获取剩余变换后的y轴
			xx.length=1        #标准化x轴方向长度
			yy.length=1        #标准化y轴方向长度
			unless xx.perpendicular?(yy) then
			xtmp=xx
			xtmp.length=yy.dot(xx)
			yy=yy-xtmp
			end
			#在xy平面中重新确定y轴方向以保证其与x轴垂直
			zz=xx.cross(yy)    #计算垂直于xy平面的z轴方向
			zz.length=1        #标准化z轴方向长度
			#这里没有判断轴方向是否符合右手系
			r=Geom::Transformation.axes(tmp.origin,xx,yy,zz)
			#分解出旋转分量
			tmp=r.inverse*tmp  #移除旋转分量
			arr=tmp.to_a
			s=Geom::Transformation.new([arr[0],0,0,0,0,arr[5],0,0,0,0,arr[10],0,0,0,0,arr[15]])
			#分解出轴线缩放分量
			tmp=s.inverse*tmp
			#剩余的变换直接作为最后一个参数输出
			#若为正交变换则tmp.identity?为真。
			return [t,r,s,tmp]
		end
		def trse
			CgeHelper.trans_to_trse(@cg.transformation)
		end
		
		def is_flatten?
			@cg.definition.entities.select{|i|i.is_a?(Sketchup::Group) or i.is_a?(Sketchup::ComponentInstance)}.empty?
		end
		
		#将组件转化为群组，参数表示是否保存组件定义中的属性
		def to_group(preserve_definition_attribute=false)
			raise ArgumentError.new("ComponentInstance expected but #{@cg.class} found.") unless @cg.is_a?(Sketchup::ComponentInstance)
			Sketchup.active_model.start_operation("Cge:转为群组")
			d=@cg.definition
			grp=@cg.parent.entities.add_group([@cg])
			@cg.attribute_dictionaries.entries.each{|ad|
				ad.to_h.each{|k,v|
					grp.set_attribute(ad.name,k,v)
				}
			}
			d.attribute_dictionaries.entries.each{|ad|
				grp.set_attribute("Apiglio Cge ComponentGroup",ad.name,ad.to_h.to_s)
			} if preserve_definition_attribute
			grp.name=d.name
			@cg.explode
			Sketchup.active_model.definitions.remove(d) if d.instances.length==0
			Sketchup.active_model.commit_operation()
			return(grp)
		end
		
		#将群组转化回组件，动态组件也有效
		def back_to_compoent
			raise ArgumentError.new("Group expected but #{@cg.class} found.") unless @cg.is_a?(Sketchup::Group)
			Sketchup.active_model.start_operation("Cge:转回组件")
			attrs=@cg.attribute_dictionaries.entries.map{|i|[i.name,i.to_h]}
			attrd=attrs.find{|i|i[0]=="Apiglio Cge ComponentGroup"}
			attrs.delete(attrd)
			oriname=@cg.name
			ins=@cg.to_component
			ins.definition.name=Sketchup.active_model.definitions.unique_name(oriname)
			attrd[1].each{|k,v|
				h=eval(v)
				h.each{|kk,vv|
					begin
						ins.definition.set_attribute(k,kk,vv)
					rescue
						puts "属性#{k}.#{kk}赋值（#{vv}）失败。"
					end
				}
			} unless attrd.nil?
			ins.attribute_dictionaries.delete("Apiglio Cge ComponentGroup")
			Cge::DC.redraw(ins,false)
			Sketchup.active_model.commit_operation()
			return(ins)
		end
		
		#具体instance的transformation转换到世界坐标系中
		def global_trans
			model=Sketchup.active_model
			ap=model.active_path
			ap=[] if ap.nil?
			lst=Cge.find_paths_in_active(@cg,ap)
			lst.map{|p|p.transformation*model.edit_transform}
		end
	end
	
	[Sketchup::Group,Sketchup::ComponentInstance].each{|klass|
		if klass.instance_methods.include?(:cge) then
			if klass.instance_method(:cge).parameters[0][1]!=:author_apiglio then
				UI.messagebox("Class #{klass} already has :cge method. Failed to attach.")
				next
			end
		end
		eval("class #{klass.to_s}\r\ndef cge(author_apiglio='')\r\nreturn(Cge::CgeHelper.new(self))\r\nend\r\nend")
	}
	
	
	
	
	
end