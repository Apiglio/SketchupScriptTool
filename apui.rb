#encoding "UTF-8"
require __dir__+'/class/instpath_helper.rb'

module APUI
	#存储选项的inputbox
	class StoredInputBox
		def initialize(prompts, defaults, list, title)
			raise Exception.new("prompts: Array expected but #{prompts.class} found.") unless prompts.is_a?(Array)
			raise Exception.new("defaults: Array expected but #{defaults.class} found.") unless defaults.is_a?(Array)
			raise Exception.new("title: String expected but #{title.class} found.") unless title.is_a?(String)
			@_prompts_  = prompts
			@_defaults_ = defaults
			@_list_     = list
			@_title_    = title
		end
		def execute()
			result = UI.inputbox(@_prompts_,@_defaults_,@_list_,@_title_)
			@_defaults_ = result.clone if result
			return(result)
		end
	end
	
	module EntityFilter
		def self.search_for_entities(typelist, orientlist, min_length, max_length)
			list = InstancePathTree.check_subordinate(nil).subordinates
			list.select!{|p|typelist.include?(p.leaf.class)}
			result_list = [];
			list.each{|path|
				case path.leaf
					when Sketchup::Text
						vec = path.leaf.vector ? path.transformation*path.leaf.vector : Geom::Vector3d.new([0,0,0])
					when Sketchup::DimensionLinear
						vec = path.transformation*path.leaf.offset_vector
					when Sketchup::DimensionRadial
						pts = path.leaf.leader_points
						vec = pts[2] - pts[1]
						vec = path.transformation*vec
					else
						raise TypeError.new("Unexpected type of InstancePath leaf Entity #{path.leaf}.")
				end
				len = vec.length
				if len>0 then
					next unless len>=min_length and len<=max_length
					# Elsif地狱，可以修改逻辑
					if vec.parallel?([0,0,1]) then
						next unless orientlist.include?('z')
					elsif vec.parallel?([0,1,0]) then
						next unless orientlist.include?('y')
					elsif vec.parallel?([1,0,0]) then
						next unless orientlist.include?('x')
					elsif vec.perpendicular?([0,0,1]) then
						next unless orientlist.include?('xy')
					elsif vec.perpendicular?([0,1,0]) then
						next unless orientlist.include?('xz')
					elsif vec.perpendicular?([1,0,0]) then
						next unless orientlist.include?('yz')
					else
						next unless orientlist.include?('xyz')
					end
				else
					next unless orientlist.include?('0')
				end
				result_list << path
			}
			return result_list
		end
		def self.showUI()
			unless defined?(@window) then
				@window = UI::HtmlDialog.new(
				{
				  :dialog_title => "Apiglio Entity Filter",
				  :preferences_key => "- Apiglio -",
				  :scrollable => true,
				  :resizable => true,
				  :width => 300,
				  :height => 600,
				  :min_width => 300,
				  :min_height => 600,
				  :style => UI::HtmlDialog::STYLE_UTILITY
				})
				@window.set_file(__dir__+"/UI/EntityFilter.html")
			end
			
			@window.add_action_callback("do_filter"){
				|action_context, typelist, orientlist, e1, e2, u1, u2|
				typelist.map!{|t|eval("Sketchup::"+t)}
				min_length = eval(e1.to_s+"."+u1)
				max_length = eval(e2.to_s+"."+u2)
				res = search_for_entities(typelist, orientlist, min_length, max_length)
				res.each{|path|
					@window.execute_script("appendItem(\"#{("      "+path.leaf.typename)[-6..-1]}\", \"#{path.leaf.text}\", #{path.persistent_id_path})")
				}
			}
			@window.add_action_callback("do_zoom"){
				|action_context, pid|
				instpath = Sketchup.active_model.instance_path_from_pid_path(pid)
				Sketchup.active_model.active_path = instpath
				ent = instpath.leaf
				sup = instpath.to_a[-2]
				if sup.nil? then
					Sketchup.active_model.active_view.zoom_entents
				else
					Sketchup.active_model.active_view.zoom(sup)
				end
				Sketchup.active_model.selection.clear
				Sketchup.active_model.selection.add(ent)
			}
			@window.show
		end
		unless defined?(@command) then
			@command = UI::Command.new("Open Filter Window") {
				self.showUI
			}
			@command.menu_text = "打开筛选器窗口"
			@command.tooltip = "打开筛选器窗口"
			@command.status_bar_text = "打开 Apiglio Entity Filter 的筛选器窗口"
			@command.small_icon = __dir__+"/UI/EntityFilter_S.png"
			@command.large_icon = __dir__+"/UI/EntityFilter_L.png"
			@command.set_validation_proc { MF_ENABLED }
			@toolbar = UI::Toolbar.new("Apiglio Entity Filter")
			@toolbar = @toolbar.add_item(@command)
			@toolbar.show
		end
	end
end