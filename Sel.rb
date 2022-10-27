#encoding "UTF-8"
#sel.rb
#Apiglio
#这不是一个打包好的插件模块
#只能直接在ruby控制台中通过load来调用
#代码发布在微信公众号Apiglio中

require 'sketchup.rb'

module Sel

	def Sel.model() Sketchup.active_model end
	def Sel.ents() Sketchup.active_model.entities end
	def Sel.sels() Sketchup.active_model.selection end
	def Sel.lyrs() Sketchup.active_model.layers end
	
	
	#=================================常量部==================================
	
	E=Sketchup::Edge unless defined?(E)
	F=Sketchup::Face unless defined?(F)
	C=Sketchup::ComponentInstance unless defined?(C)
	G=Sketchup::Group unless defined?(G)
	CD=Sketchup::ComponentDefinition unless defined?(CD)
	CL=Sketchup::ConstructionLine unless defined?(CL)
	CP=Sketchup::ConstructionPoint unless defined?(CP)
	D=Sketchup::Dimension if Sketchup.version_number > 14000000 unless defined?(D)
	I=Sketchup::Image unless defined?(I)
	SP=Sketchup::SectionPlane unless defined?(SP)
	T=Sketchup::Text unless defined?(T)
	Error=Exception.new("~BlockError") unless defined?(Error)
	
	
	#===============================匿名函数部================================
	
	ProcTypename=Proc.new{|i|i.typename} unless defined?(ProcTypename)
	ProcTrue=Proc.new{true} unless defined?(ProcTrue)
	ProcHashReport=Proc.new{|reg,instance|
		shown=0
		total=0
		if Float.constants.include?(:INFINITY) then
			max=-Float::INFINITY
			min=Float::INFINITY
		else
			max=-Float::MAX
			min=Float::MAX
		end
		sum=0
		if instance.nil? then
			hashobj=self
		else
			hashobj=instance
		end
		hashobj.each{|k,v|
			if k.to_s=~reg or reg==// then
				puts "#{k}".ljust(18)+"|#{v}"
				shown+=v
				unless max.nil? then
					if k.is_a?(Numeric) then
						max=k if k>max
						min=k if k<min
					else
						max=nil
						min=nil
					end
				end
				unless sum.nil? then
					if k.is_a?(Numeric) then
						sum+=k*v
					else
						sum=nil
					end
				end
			end
			total+=v
		}
		puts "------------------+----"
		unless shown==0 then
			puts "Max  :".ljust(18)+"|#{max}" unless max.nil?
			puts "Min  :".ljust(18)+"|#{min}" unless min.nil?
			puts "Mean :".ljust(18)+"|#{sum/shown}" unless sum.nil?
			puts "------------------+----" unless max.nil? and min.nil? and sum.nil?
		end
		puts "Shown:".ljust(18)+"|#{shown}" if shown!=total
		puts "Total:".ljust(18)+"|#{total}"
	} unless defined?(ProcHashReport)
	ProcCircum=Proc.new{|instance|
		res=0
		faceobj = instance.nil? ? self : instance
		faceobj.loops.each{|loop|
			res+=loop.edges.map{|i|i.length}.inject{|a,b|a+=b}
		}
		res
	} unless defined?(ProcCircum)
	ProcSI=Proc.new{|instance|
		faceobj = instance.nil? ? self : instance
		ProcCircum.call(faceobj)**2 / faceobj.area / Math::PI / 4
	} unless defined?(ProcSI)
	
	
	#===============================数据对接部================================
	
	#导出选中的图元
	def Sel.to_a
		sels.to_a
	end
	#选择数组中的图元
	def Sel.<<(arr)
		unless arr.is_a?(::Array) then
			puts "\"Array\" expected but \"#{arr.class}\" found."
			return nil
		end
		sels.clear
		sels.add arr
		nil
	end
	
	
	#===============================基础迭代部================================
	
	def Sel.each(list=Sel.sels,&block)
		list.each{|ent|
			if ent.is_a? Sketchup::Group then
				Sel.each(ent.entities,&block)
			else
				block.call(ent)
			end
		}
		return nil
	end
	def Sel.map(list=Sel.sels,&block)
		res=[]
		list.each{|ent|
			if ent.is_a? Sketchup::Group then
				res<<(Sel.map(ent.entities,&block))
			else
				res<<block.call(ent)
			end
		}
		return res
	end
	def Sel.flat_map(list=Sel.sels,&block)
		res=[]
		list.each{|ent|
			if ent.is_a? Sketchup::Group then
				res+=Sel.flat_map(ent.entities,&block)
			else
				res<<(block.call(ent))
			end
		}
		return res
	end
	
	def Sel.each_group(list=Sel.sels,&block)
		list.each{|ent|
			if ent.is_a? Sketchup::Group then
				block.call(ent)
				Sel.each_group(ent.entities,&block)
			elsif ent.is_a? Sketchup::ComponentInstance then
				block.call(ent)
			end
		}
		return nil
	end
	def Sel.map_group(list=Sel.sels,&block)
		res=[]
		list.each{|ent|
			if ent.is_a? Sketchup::Group then
				res<<([block.call(ent)]+Sel.map_group(ent.entities,&block))
			elsif ent.is_a? Sketchup::ComponentInstance then
				res<<block.call(ent)
			end
		}
		return res
	end
	def Sel.flat_map_group(list=Sel.sels,&block)
		res=[]
		list.each{|ent|
			if ent.is_a? Sketchup::Group then
				res<<block.call(ent)
				res+=Sel.flat_map_group(ent.entities,&block)
			elsif ent.is_a? Sketchup::ComponentInstance then
				res<<block.call(ent)
			end
		}
		return res
	end
	
	
	#===============================基础选区部================================
	
	#从模型根容器中选择
	def Sel.select(&block)
		res=0
		ents.each{|ent|
			if block.call(ent) then
				sels.add(ent)
				res+=1
			end
		}
		return res
	end
	#从模型根容器中递归选择
	def Sel.select_all(&block)
		res=0
		each(ents){|ent|
			if block.call(ent) then
				sels.add(ent)
				res+=1
			end
		}
		return res
	end
	#从模型根容器中递归选择群组
	def Sel.select_group(&block)
		res=0
		each_group(ents){|ent|
			if block.call(ent) then
				sels.add(ent)
				res+=1
			end
		}
		return res
	end
	#从选区中继续选择图元
	def Sel.reselect(&block)
		res=sels.count
		list=[]
		sels.each{|ent|
			unless block.call(ent) then
				list<<ent
				res-=1
			end
		}
		sels.remove(list)
		return res
	end
	#从选区中排除选择图元
	def Sel.deselect(&block)
		res=0
		list=[]
		sels.each{|ent|
			if block.call(ent) then
				list<<ent
				res+=1
			end
		}
		sels.remove(list)
		return res
	end
	
	
	#===============================类型选择部================================
	
	#取消选择指定类图元
	def Sel.-(class_name)
		#deletelist=sels.to_a.select{|ent|ent.is_a? class_name}
		#sels.remove deletelist
		deselect{|ent|ent.is_a? class_name}
	end
	#只选择指定类图元
	def Sel.*(class_name)
		#deletelist=sels.to_a.reject{|ent|ent.is_a? class_name}
		#sels.remove deletelist
		reselect{|ent|ent.is_a? class_name}
	end
	#增加选择模型中所有指定类图元
	def Sel.+(class_name)
		#selectlist=ents.to_a.select{|ent|ent.is_a? class_name}
		#sels.add selectlist
		select{|ent|ent.is_a? class_name}
	end	
	
	class << self
		define_method(:f){Sel*Sel::F}
		define_method(:e){Sel*Sel::E}
		define_method(:g){Sel*Sel::G}
		define_method(:c){Sel*Sel::C}
		
		define_method(:nf){Sel-Sel::F}
		define_method(:ne){Sel-Sel::E}
		define_method(:ng){Sel-Sel::G}
		define_method(:nc){Sel-Sel::C}
		
		define_method(:af){Sel+Sel::F}
		define_method(:ae){Sel+Sel::E}
		define_method(:ag){Sel+Sel::G}
		define_method(:ac){Sel+Sel::C}
		
	end
	
	
	#===============================尺寸选择部================================
	
	module Size
		def compare(size,mtd=:<=>)
			Sel.reselect{|ent|
				if ent.respond_to? :bounds then
					ent.bounds.method(key_method).call.method(mtd).call(size)
				else false end
			}
		end
		[">","<",">=","<=","==","!="].each{|sym|
			define_method(sym.to_sym){|size|compare(size,sym.to_sym)}
		}
	end

	module Depth
		def self.key_method
			return(:depth)
		end
		extend Sel::Size
	end
	
	module Width
		def self.key_method
			return(:width)
		end
		extend Sel::Size
	end
	
	module Height
		def self.key_method
			return(:height)
		end
		extend Sel::Size
	end
	
	#===============================显示隐藏部================================
	
	@hidden=[]
	#隐藏所选图元并记录
	def Sel.hide(&block)
		if block.nil? then block=ProcTrue end
		sels.each{|ent|
			ent.hidden=true if block.call(ent)
			@hidden<<ent
		}
		return @hidden.length
	end
	#显示所有hide方法隐藏的图元
	def Sel.show
		@hidden.each{|ent|
			ent.hidden=false
		}
		@hidden.clear
		return 0
	end
	
	
	#===============================平面选择部================================
	
	#返回Loop类对象是否不是“螺烷”型
	def Sel.loop_simple?(loop)
		loop.vertices.each{|i|
			in_loop=0
			i.edges.each{|j|
				if loop.edges.index(j)!=nil then in_loop+=1 end
			}
			if in_loop!=2 then return false end
		}
		return true
	end
	private_class_method :loop_simple?
	
	#返回Face类对象是否所辖的每一个Loop类对象都不是“螺烷”型
	def Sel.face_simple?(face)
		face.loops.each{|i|
			if not loop_simple?(i) then return false end
		}
		return true
	end
	private_class_method :face_simple?
	
	#只选择奇异的面
	def Sel.oddface
		Sel.reselect{|ent|
			if ent.is_a? Sketchup::Face then
				not face_simple?(ent)
			else false end
		}
	end
	#只选择有岛的面
	def Sel.loopface
		Sel.reselect{|ent|
			if ent.is_a? Sketchup::Face then
				ent.loops.length>1
			else false end
		}
	end
	#只选择岛面
	def Sel.island
		Sel.reselect{|ent|
			if ent.is_a? Sketchup::Face then
				(ent.loops[0].edges.map(&:faces).flatten.uniq-[ent]).length==1
			else false end
		}
	end
	
	#只选择水平面
	def Sel.horizon_face(preserve_horizon=true)
		Sel.reselect{|ent|
			if ent.is_a?(F) then
				ent.normal.parallel?([0,0,1])
			else false end ^ !preserve_horizon
		}
	end
	#只选择垂直面
	def Sel.vertical_face(preserve_vertical=true)
		Sel.reselect{|ent|
			if ent.is_a?(F) then
				ent.normal.perpendicular?([0,0,1])
			else false end ^ !preserve_vertical
		}
	end
	
	
	
	#形状指数选择
	module SI
		def self.>(si=1.2732395447351628)
			Sel.reselect{|ent|
				if ent.is_a? Sketchup::Face then
					(Object.method_defined?(:instance_exec) ? \
					ent.instance_exec(&ProcSI) : \
					ProcSI.call(ent))>si
				else false end
			}
		end
		def self.<(si=1.2732395447351628)
			Sel.reselect{|ent|
				if ent.is_a? Sketchup::Face then
					(Object.method_defined?(:instance_exec) ? \
					ent.instance_exec(&ProcSI) : \
					ProcSI.call(ent))<si
				else false end
			}
		end
	end
	

	
	#===============================边线选择部================================
	
	#只选择线头
	def Sel.thrum
		Sel.reselect{|ent|
			if ent.is_a? Sketchup::Edge then
				ent.faces.length == 0
			else false end
		}
	end
	#只选择垂直线
	def Sel.vert
		Sel.reselect{|ent|
			if ent.is_a? Sketchup::Edge then
				ent.line[1].parallel? [0,0,1]
			else false end
		}
	end
	#只选择弧线
	def Sel.curve
		Sel.reselect{|ent|
			if ent.is_a? Sketchup::Edge then
				not ent.curve.nil?
			else false end
		}
	end
	#选择平面内边线
	def Sel.inner
		Sel.reselect{|edg|
			if edg.is_a?(Sketchup::Edge) then
				if edg.faces.length !=2 then
					false
				else
					edg.faces[0].normal.parallel?(edg.faces[1].normal)
				end
			else
				false
			end
		}
	end
	#共用点交角
	def Sel.angle_between(a,b)
		if a.start==b.start or a.end==b.end then
			return a.line[1].angle_between(b.line[1])
		else
			return a.line[1].angle_between(b.line[1].reverse)
		end
	end
	private_class_method :angle_between
	#选择最大轮廓（最大轮廓段数）
	def Sel.bound(max=50)
		unless sels.length==1 then return nil end
		init=sels[0]
		unless init.is_a?(Sketchup::Edge) then return nil end
		edges_mightbe=[]
		edge_now=init
		vertex_now=init.start
		while true do
			edge_new=(vertex_now.edges - [edge_now]).sort{|a,b|angle_between(a,edge_now)<=>angle_between(b,edge_now)}[-1]
			vertex_now=(edge_new.vertices-edge_now.vertices)[0]
			edges_mightbe<<edge_new
			edge_now=edge_new
			if vertex_now==init.end or vertex_now.edges.length<2 or edges_mightbe.length>max then break end
		end
		sels.add edges_mightbe
	end
	#选中的边线根据首尾相连排序
	def self.find_seq(edges=nil,reverse=false)
		edges=Sketchup.active_model.selection.grep(Sketchup::Edge) if edges.nil?
		return nil if edges.empty?
		res=[edges.pop]
		rev=[-1] # 从start开始找下一个条边，因此初始段的end在start前，记为-1
		pts=res[0].start
		while not edges.empty? do
			es=edges.select{|e|e.vertices.include?(pts)}.reject{|e|e==res[-1]}
			case es.length
				when 0
					break
				when 1
					res.push(es[0])
					if es[0].start==pts then rev.push(1) else rev.push(-1) end
					pts=es[0].other_vertex(pts)
				else
					raise RuntimeError.new("发现分叉")
			end
		end
		pts=res[0].end
		while not edges.empty? do
			es=edges.select{|e|e.vertices.include?(pts)}.reject{|e|e==res[0]}
			case es.length
				when 0
					break
				when 1
					res.unshift(es[0])
					if es[0].end==pts then rev.unshift(1) else rev.unshift(-1) end
					pts=es[0].other_vertex(pts)
				else
					raise RuntimeError.new("发现分叉")
			end
		end
		if reverse then
			return [res,rev].transpose
		else
			return res
		end
	end
	
	#===============================线面综合部================================
	
	#拓展到线面一致
	def Sel.extend
		edges=sels.grep(Sketchup::Edge)
		faces=sels.grep(Sketchup::Face)
		faces_mightbe=edges.collect{|e|e.faces}.flatten.uniq.reject{|f|f.edges.collect{|e|edges.include?(e)}.uniq.include?(false)}
		edges_mightbe=faces.collect{|f|f.edges}.flatten.uniq
		return(sels.add(faces_mightbe)+sels.add(edges_mightbe))
	end
	#缩减到线面一致
	def Sel.compact
		edges=sels.grep(Sketchup::Edge)
		faces_mightnotbe=sels.grep(Sketchup::Face).select{|f|f.edges.collect{|e|edges.include?(e)}.uniq.include?(false)}
		nf=sels.remove(faces_mightnotbe)
		edges_mightnotbe=edges - sels.grep(Sketchup::Face).collect(&:edges).flatten
		return(sels.remove(edges_mightnotbe)+nf)
	end
	def Sel.extcpt
		return [Sel.extend,Sel.compact]
	end
	
	
	#===============================群组选择部================================
	
	#选择形变的组件或群组
	def Sel.deform(tolerance=0.0000003)
		Sel.reselect{|ent|
			if ent.is_a? Sketchup::ComponentInstance or ent.is_a? Sketchup::Group then
				t=ent.transformation
				(t.xscale-1.0).abs+(t.yscale-1.0).abs+(t.zscale-1.0).abs > tolerance
			else false end
		}
	end
	#选择具体实例名称的组件或群组
	def Sel.name=(namestr)
		Sel.reselect{|ent|
			if ent.respond_to? :name then
				ent.name==namestr
			else false end
		}
	end
	#选择具体定义名称的组件或群组
	def Sel.defname=(defnamestr)
		Sel.reselect{|ent|
			if ent.respond_to? :definition then
				ent.definition.name==defnamestr
			else false end
		}
	end
	#选择具体属性值的组件或群组
	def Sel.[]=(attr,key,value)
		Sel.reselect{|ent|
			if ent.respond_to? :get_attribute then
				ent.get_attribute(attr,key)==value
			else false end
		}
	end
	
	def Sel.name_eql!(namestr) Sel.name=namestr end
	def Sel.defname_eql!(defnamestr) Sel.defname=defnamestr end
	def Sel.attribute_eql!(attr,key,value) Sel[attr,key]=value end
	
	
	#===============================统计报表部================================
	
	def Sel.analyse(&block)
		res=Hash.new
		sels.each{|ent|
			begin
				item=block.call(ent)
			rescue
				item=Error
			end
			if res.has_key?(item) then
				res[item]+=1
			else
				res[item]=1
			end
		}
		return res
	end
	def Sel.analyse_all(&block)
		res=Hash.new
		each{|ent|
			begin
				item=block.call(ent)
			rescue
				item=Error
			end
			if res.has_key?(item) then
				res[item]+=1
			else
				res[item]=1
			end
		}
		return res
	end
	def Sel.analyse_group(&block)
		res=Hash.new
		each_group{|ent|
			begin
				item=block.call(ent)
			rescue
				item=Error
			end
			if res.has_key?(item) then
				res[item]+=1
			else
				res[item]=1
			end
		}
		return res
	end
	def Sel.analyse_instance(arr,&block)
		res=Hash.new
		arr.each{|ent|
			begin
				item=block.call(ent)
			rescue
				item=Error
			end
			if res.has_key?(item) then
				res[item]+=1
			else
				res[item]=1
			end
		}
		return res
	end
	
	def Sel.report(reg=//,&block)
		if block.nil? then block=Sel::ProcTypename end
		ha=analyse(&block)
		if Object.method_defined? :instance_exec then
			ha.instance_exec(reg,&ProcHashReport)
		else
			ProcHashReport.call(reg,ha) #倒霉催的1.8没有instance_exec
		end
	end
	def Sel.report_all(reg=//,&block)
		if block.nil? then block=Sel::ProcTypename end
		ha=analyse_all(&block)
		if Object.method_defined? :instance_exec then
			ha.instance_exec(reg,&ProcHashReport)
		else
			ProcHashReport.call(reg,ha) #倒霉催的1.8没有instance_exec
		end
	end
	def Sel.report_group(reg=//,&block)
		if block.nil? then block=Sel::ProcTypename end
		ha=analyse_group(&block)
		if Object.method_defined? :instance_exec then
			ha.instance_exec(reg,&ProcHashReport)
		else
			ProcHashReport.call(reg,ha) #倒霉催的1.8没有instance_exec
		end
	end
	def Sel.report_instance(instance,reg=//,&block)
		if block.nil? then block=Sel::ProcTypename end
		ha=analyse_instance(instance.definition.entities,&block)
		if Object.method_defined? :instance_exec then
			ha.instance_exec(reg,&ProcHashReport)
		else
			ProcHashReport.call(reg,ha) #倒霉催的1.8没有instance_exec
		end
	end
	
	
	#===============================属性修改部================================
	
	module Edit
		def self.layer=(lyr)
			unless lyr.class==Sketchup::Layer then
				lyr=Sketchup.active_model.layers[lyr.to_s]
			end
			Sel.sels.each{|ent|
				ent.layer=lyr
			}
		end
		def self.name=(value)
			Sel.reselect{|ent|
				if ent.respond_to? :name= then
					ent.name=value
				else false end
			}
		end
		def self.[]=(attr,key,value)
			Sel.reselect{|ent|
				if ent.respond_to? :get_attribute then
					ent.set_attribute(attr,key,value)
				else false end
			}
		end
		
	end
	
	
	#===============================表面修改部================================
	
	module Surf
		#将选中的多个平面创建成表面
		def self.soft!
			Sel.sels.grep(Sel::F).each{|f|
				f.edges.each{|e|
					if e.faces.all?{|ff|Sel.sels.include?(ff)} and e.faces.length>1 then e.soft=true end
				}
			}.length
		end
		#将选中表面重新拆解
		def self.unsoft!
			Sel.sels.grep(Sel::F).each{|f|
				f.edges.each{|e|
					e.soft=false
				}
			}.length
		end
		#将选中的多个平面平滑光照
		def self.smooth!
			Sel.sels.grep(Sel::F).each{|f|
				f.edges.each{|e|
					if e.faces.all?{|ff|Sel.sels.include?(ff)} and e.faces.length>1 then e.smooth=true end
				}
			}.length
		end
		#将选中的表面取消平滑光照
		def self.unsmoothen!
			Sel.sels.grep(Sel::F).each{|f|
				f.edges.each{|e|
					e.smooth=false
				}
			}.length
		end
		#通过一个给定平面返回通过柔滑的边线能够连接到的所有平面
		def self.find_surface_by_face(face)
			surf=[face]
			len_old=0
			len=surf.length
			while len != len_old do
				surf.to_a[len_old..-1].each{|f|
					f.edges.each{|e|
						if e.soft? then
							e.faces.each{|nf|surf<<nf unless surf.include?(nf)}
						end
					}
				}
				len_old=len
				len=surf.length
			end
			return surf
		end
		#返回选中表面的轮廓
		def self.bounds
			return Sel.sels.grep(Sel::F).map{|f|f.edges}.flatten.uniq.select{|e|e.faces.length==1}
		end
		#
		def self.line_to_base_plane(edg,base_height=0)
			p1=edg.start.position
			p2=edg.end.position
			p1.z=base_height
			p2.z=base_height
			return edg.parent.entities.add_line(p1,p2)
		end
		private_class_method :line_to_base_plane
		#表面下拉为固实体
		def self.to_solid(min_height=10.m)
			Sketchup.active_model.start_operation("Sel::Surf 创建固实体")
			begin
				bs=bounds
				z_min=bs.map{|e|e.vertices}.flatten.uniq.min{|v|v.position.z}.position.z
				base_height=z_min-min_height
				es=[]
				bs.each{|e|
					ne=line_to_base_plane(e,base_height)
					es<<ne
					e.parent.entities.add_face(e.vertices+ne.vertices.reverse)
				}
				#Sel.sels[0].parent.entities.add_face(es.map{|v|v.start.position})
				es[0].find_faces
				Sketchup.active_model.commit_operation
			rescue
				Sketchup.active_model.abort_operation
			end
		end
	end
	
	
	#===============================视角场景部================================
	
	def self.zoom
		self.model.active_view.zoom self.sels
	end
	
	def self.vertex_visible?(pos)
		view=Sketchup.active_model.active_view
		res=view.screen_coords(pos)
		return(res[0]>=0 and res[0]<view.vpwidth and res[1]>=0 and res[1]<view.vpheight)
	end
	
	def self.edge_visible(edg)
		return (vertex_visible?(edg.start.position) and vertex_visible?(edg.end.position))
	end
	
	
	
end
