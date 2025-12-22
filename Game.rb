#Game Tool
#Apiglio
#游戏模块

module Game
	# Sketchup.active_model.select_tool(Game::FPS::Shooting.new)
	module FPS
		class Shooting
			def activate
				@last_cursor_pos = nil
				@hori_pos = 0.0
				@vert_pos = 0.0
				@sensit_h = 0.08
				@sensit_v = 0.08
				@standing_point = Geom::Point3d.new([0,0,0])
				@view_up = Geom::Vector3d.new([0,0,1])
				@view_zero = Geom::Vector3d.new([1,0,0])
				@view_axis = Geom::Vector3d.new([0,-1,0])
				@direxion = nil
				cam = Sketchup::Camera.new(@standing_point,@view_zero,@view_up)
				Sketchup.active_model.active_view.camera = cam
				@aim_font = {
					:font => "Arial",
					:size => 36,
					:bold => false,
					:color => "Red",
					:align => TextAlignCenter,
					:vertical_align => TextVerticalAlignCenter
				}
				#@shooting = false
			end
			def draw(view)
				aim = @standing_point + @direxion
				view.line_width = 2
				view.drawing_color = "black"
				center = Geom::Point3d.new([view.vpwidth/2,view.vpheight/2,0])
				view.draw_text(center,"+",@aim_font)
				view.invalidate
			end
			def onLButtonDown(flags,x,y,view)
				#@shooting = true
				vec=Geom::Vector3d.new(@direxion)
				vec.length=100000000
				ptr=Geom::Point3d.new([0,0,0])
				Sketchup.active_model.entities.add_line(ptr,ptr+vec)
			end
			def onLButtonUp(flags,x,y,view)
				#@shooting = false
			end
			def onMouseMove(flags,x,y,view)
				if @last_cursor_pos.nil? then
					@last_cursor_pos = Geom::Point3d.new([x,y,0])
				else
					cursor_pos = Geom::Point3d.new([x,y,0])
					offset = cursor_pos - @last_cursor_pos
					@hori_pos -= (offset.x)*@sensit_h
					@vert_pos -= (offset.y)*@sensit_v
					@vert_pos = +75.0 if @vert_pos > +75.0
					@vert_pos = -75.0 if @vert_pos < -75.0
					tVertRot = Geom::Transformation.rotation(@standing_point,@view_axis,@vert_pos.degrees)
					tHoriRot = Geom::Transformation.rotation(@standing_point,@view_up,@hori_pos.degrees)
					@direxion = @view_zero.transform(tHoriRot*tVertRot)
					cam = Sketchup::Camera.new(@standing_point,@standing_point+@direxion,@view_up)
					view.camera = cam
					@last_cursor_pos = cursor_pos
				end
				draw(view)
			end
		end
	end
	
end

