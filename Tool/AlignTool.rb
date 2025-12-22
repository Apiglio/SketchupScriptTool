class AlignTool
	def quit_and_show_msg(error_msg=nil)
		UI.messagebox(error_msg) if error_msg
		Sketchup.active_model.select_tool(nil)
		error_msg
	end
	def confirm_transform_scale_method()
		unless Geom::Transformation.instance_methods.include?(:xscale)
			raise NotImplementedError.new("Geom::Transformation has no xscale method.")
		end
	end
	def calc_ranges(instance_list)
		@@instances = instance_list.clone
		@@instances_trans = instance_list.map(&:transformation)
		first_one = instance_list.pop()
		trans = first_one.transformation
		@@axes_vectors = [trans.xaxis, trans.yaxis, trans.zaxis]
		@@axes_origin = trans.origin
		@@axes_ranges = []
		@@axes_ranges.push(
			[trans.origin.x, trans.origin.x + first_one.bounds.width , 
			 trans.origin.y, trans.origin.y + first_one.bounds.height, 
			 trans.origin.z, trans.origin.z + first_one.bounds.depth ]
		)
		instance_list.each{|ent|
			trans = ent.transformation
			norm_axes = @@axes_vectors.clone
			ranges = [nil,nil,nil]
			whd = [:width, :height, :depth]
			xyz = [:x, :y, :z]
			axes = [:xaxis, :yaxis, :zaxis]
			scales = [:xscale, :yscale, :zscale]
			0.upto(2).each{|idx_1|
				idx_2 = @@axes_vectors.find_index{|vec|
					vec.parallel?(trans.method(axes[idx_1]).call)
				}
				return quit_and_show_msg("待对齐的图元需要轴方向一致。") if idx_2.nil?
				bb = ent.definition.bounds
				size = bb.method(whd[idx_1]).call * trans.method(scales[idx_1]).call
				ranges[idx_1] = [trans.origin.method(xyz[idx_2]).call]
				if @@axes_vectors[idx_2].samedirection?(trans.method(axes[idx_1]).call) then
					ranges[idx_1] << trans.origin.method(xyz[idx_2]).call + size
				else
					ranges[idx_1] << trans.origin.method(xyz[idx_2]).call - size
				end
				ranges[idx_1].sort!
			}
			@@axes_ranges.push(ranges.flatten.flatten)
		}
		bb = Geom::BoundingBox.new
		@@instances.each{|ent|bb.add(ent.bounds)}
		@@selected_center = bb.center
		@@selected_pxaxis = @@selected_center + @@axes_vectors[0]
		@@selected_nxaxis = @@selected_center - @@axes_vectors[0]
		@@selected_pyaxis = @@selected_center + @@axes_vectors[1]
		@@selected_nyaxis = @@selected_center - @@axes_vectors[1]
		@@selected_pzaxis = @@selected_center + @@axes_vectors[2]
		@@selected_nzaxis = @@selected_center - @@axes_vectors[2]
		@@axes_ranges.each{|i|p i.map{|j|j.round(1)}}
	end
	def screen_coord_state(x,y,view)
		#center = view.screen_coords(@@selected_center).to_a[0..1].distance([x,y])
		dist_nx = view.screen_coords(@@selected_nxaxis).to_a[0..1].distance([x,y])
		dist_px = view.screen_coords(@@selected_pxaxis).to_a[0..1].distance([x,y])
		dist_ny = view.screen_coords(@@selected_nyaxis).to_a[0..1].distance([x,y])
		dist_py = view.screen_coords(@@selected_pyaxis).to_a[0..1].distance([x,y])
		dist_nz = view.screen_coords(@@selected_nzaxis).to_a[0..1].distance([x,y])
		dist_pz = view.screen_coords(@@selected_pzaxis).to_a[0..1].distance([x,y])
		dists = [dist_nx, dist_px, dist_ny, dist_py, dist_nz, dist_pz]
		return dists.index(dists.min)
	end
	def preview_align(status)
		min_or_max = status % 2
		x_y_or_z = status / 2
		if min_or_max == 0 then
			sels_min = @@axes_ranges.min{|range|range[status]}[status]
			@@instances.each_with_index{|ent, index|
				inst_min = @@axes_ranges[index][status]
				move_dist = inst_min - sels_min
				move_vec = [0]*x_y_or_z + [move_dist] + [0]*(2-x_y_or_z)
				move_trans = Geom::Transformation.translation(move_vec)
				ent.transformation = move_trans * @@instances_trans[index]
			}
		else
			sels_max = @@axes_ranges.max{|range|range[status]}[status]
			@@instances.each_with_index{|ent, index|
				inst_max = @@axes_ranges[index][status]
				move_dist = inst_max - sels_max
				move_vec = [0]*x_y_or_z + [move_dist] + [0]*(2-x_y_or_z)
				move_trans = Geom::Transformation.translation(move_vec)
				ent.transformation = move_trans * @@instances_trans[index]
			}
		end
	end
	def activate
		confirm_transform_scale_method()
		selected_instances = Sketchup.active_model.selection.to_a
		if selected_instances.empty? then
			return quit_and_show_msg("请选择需要对齐的组件或群组。")
		elsif selected_instances.map(&:parent).uniq.length != 1
			return quit_and_show_msg("待对齐的图元需要在同一层次。")
		elsif not selected_instances.all?{|e|e.respond_to?(:transformation)}
			return quit_and_show_msg("待对齐的图元须为组件或群组。")
		end
		calc_ranges(selected_instances)
		Sketchup.active_model.start_operation("Apiglio AlignTool")
	end
	def onCancel(reason, view)
		Sketchup.active_model.abort_operation()
	end
	def suspend(view)
		Sketchup.active_model.abort_operation()
	end
	def resume(view)
		Sketchup.active_model.start_operation("Apiglio AlignTool")
	end
	def onMouseMove(flags,x,y,view)
		status = screen_coord_state(x,y,view)
		preview_align(status)
	end
	def onLButtonUp(flags, x, y, view)
		Sketchup.active_model.commit_operation()
		Sketchup.active_model.select_tool(nil)
	end
end