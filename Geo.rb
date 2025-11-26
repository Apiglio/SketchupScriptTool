
module Geo
	# 将EsriJSON中的面数据导入SketchUp并将字段值赋值给面要素
	# 不能读取多部件，请在GIS中将多部件转至单部件
	# 创建的平面自动打组并平移到原点附近，平移参数保存在群组的EsriJSONAttribute属性中
	
	def self.importFacesFromEsriJSON(filename)
		
		#读取EsriJSON
		json_file = File.open(filename,"r")
		json_string = json_file.read()
		json = JSON.parse(json_string)
		json_file.close()
		if json["geometryType"] != "esriGeometryPolygon" then
			raise ArgumentError.new("Geometry type of EsriJSON is not Polygon.")
		end
		
		#创建面操作
		failure_count = 0
		Sketchup.active_model.start_operation("Import Faces From EsriJSON")
		begin
			face_generated = []
			Sketchup.active_model.entities.build{|builder|
				json["features"].each{|feature|
					loops = feature["geometry"]["rings"]
					if loops.respond_to?(:[]) then
						outer_loop = (loops[0][0..-2]).map{|point|point.map(&:m)}
						inner_loops = loops[1..-1].map{|loop|loop[0..-2].map{|point|point.map(&:m)}}
						face = builder.add_face(outer_loop, holes: inner_loops)
						feature["attributes"].each{|key, value|
							face.set_attribute("EsriJSONAttribute",key,value)
						}
						face_generated << face
					else
						failure_count += 1
					end
				}
			}
			Sketchup.active_model.entities.weld(face_generated.map{|f|f.edges}.flatten.uniq) if Sketchup.active_model.entities.respond_to?(:weld)
			group = Sketchup.active_model.entities.add_group(face_generated.map(&:all_connected).flatten.uniq)
			offset = group.bounds.min
			trans = Geom::Transformation.translation(offset)
			group.transform!(trans.inverse)
			group.set_attribute("EsriJSONAttribute","Offset_X",offset[0])
			group.set_attribute("EsriJSONAttribute","Offset_Y",offset[1])
		rescue
			Sketchup.active_model.abort_operation()
			raise RuntimeError.new("FacesDrawingError.")
		end
		Sketchup.active_model.commit_operation()
		return failure_count
	end
end




#测试代码

# Geo.importFacesFromEsriJSON("F:\\Apiglio\\WorkPath\\tmp\\lmc_esrijson.json")
# load "F:\\Apiglio\\SketchupScriptTool\\Sel.rb"
# load "F:\\Apiglio\\SketchupScriptTool\\Cam.rb"
# Cam.vw
# Sel.sels[0].attribute_dictionaries["EsriJSONAttribute"].to_h
# Sel.sels[0].loops[0].edges.each_with_index{|e,i|Sketchup.active_model.entities.add_text(i.to_s,e.bounds.center)}
# Sel.reselect{|i|i.is_a?Sketchup::Text}

# Sel.f
# Sketchup.active_model.start_operation("Pushpull by FAR")
# Sel.sels.to_a.each{|f|
	# floor_area_ratio = f.get_attribute("EsriJSONAttribute","FAR")
	# f.pushpull(-floor_area_ratio*50.m) if floor_area_ratio!=0
	# puts floor_area_ratio
# }
# Sketchup.active_model.commit_operation()



