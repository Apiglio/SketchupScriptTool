
module Geo
	# 将EsriJSON中的面数据导入SketchUp并将字段值赋值给面要素
	def self.importFacesFromEsriJSON(filename)
		json_file = File.open(filename,"r")
		json_string = json_file.read()
		json = JSON.parse(json_string)
		json_file.close()
		
		if json["geometryType"] != "esriGeometryPolygon" then
			raise ArgumentError.new("Geometry type of EsriJSON is not Polygon.")
		end
		Sketchup.active_model.start_operation("Import Faces From EsriJson")
		begin
			Sketchup.active_model.entities.build{|builder|
				json["features"].each{|feature|
					loops = feature["geometry"]["rings"]
					outer_loop = (loops[0][0..-2]).map{|point|point.map(&:m)}
					inner_loops = loops[1..-1].map{|loop|loop[0..-2].map{|point|point.map(&:m)}}
					puts "outer_loop count=#{outer_loop.count}  inner_loop count=#{inner_loops.map(&:count)}"
					face = builder.add_face(outer_loop, holes: inner_loops)
					feature["attributes"].each{|key, value|
						face.set_attribute("EsriJSONAttribute",key,value)
					}
				}
			}
		rescue
			Sketchup.active_model.abort_operation()
			raise ArgumentError.new("FacesDrawingError.")
		end
		Sketchup.active_model.commit_operation()
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




