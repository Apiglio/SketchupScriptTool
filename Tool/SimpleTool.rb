module SimpleTool
#需要加载APUI模块
	module SelTool
	#需要加载Sel模块
		class TypeTool
			@@inputbox = APUI::StoredInputBox.new(
				["图元类型",                 "模式"],
				['边线',                     "选择"],
				["边线|平面|组件|群组|图像", "选择|反选"],
				"选择图元"
			)
			@@typelist={"边线"=>Sketchup::Edge,
						"平面"=>Sketchup::Face,
						"组件"=>Sketchup::ComponentInstance,
						"群组"=>Sketchup::Group,
						"图像"=>Sketchup::Image
			}
			def activate
				result = @@inputbox.execute()
				if result then
					type = @@typelist[result[0]]
					case result[1]
						when "选择" then Sel*type
						when "反选" then Sel-type
					end
				end
				Sketchup.active_model.select_tool(nil)
			end
		end
		
		class VolumeTool
			@@inputbox = APUI::StoredInputBox.new(
				["图元类型",             "模式",          "阈值", "单位"],
				['组件和群组',           ">",             1000,   "m³"],
				["组件|群组|组件和群组", ">|>=|<|<=|==",  "",     "m³|L|mL|in³"],
				"选择图元"
			)
			def activate
				result = @@inputbox.execute()
				if result then
					case result[0]
						when "组件"       then Sel.reselect{|e|e.is_a?(Sketchup::Group)}
						when "群组"       then Sel.reselect{|e|e.is_a?(Sketchup::ComponentInstance)}
						when "组件和群组" then Sel.reselect{|e|e.respond_to?(:volume)}
					end
					threshold = result[2].to_f
					case result[3]
						when "m³"  then threshold = threshold.m.m.m
						when "L"   then threshold = threshold.mm.mm.m
						when "mL"  then threshold = threshold.mm.mm.mm
						when "in³" then threshold = threshold
					end
					Sel.reselect{|e|e.manifold?}
					operator = result[1].to_sym
					Sel.reselect{|e|e.volume.method(operator).call(threshold)}
				end
				Sketchup.active_model.select_tool(nil)
			end
		end
	end
end