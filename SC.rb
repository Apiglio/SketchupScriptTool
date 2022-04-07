path=__FILE__.gsub("\\","/")
path=__FILE__[0..(__FILE__).rindex("/")]

require path+'Sel.rb'
require path+'Cam.rb'

module S
	class << S
		def ss
			Sel.sels
		end
		def s
			return nil if Sel.sels.length>1
			Sel.sels[0]
		end
		def c
			cs=Sel.sels.grep(Sketchup::Edge).map(&:curve).uniq
			return nil if cs.length!=1
			cs[0]
		end
		def vw
			Cam.vw
		end
		def vs
			Cam.vs
		end
		def va
			Cam.va
		end
		def ents
			Sketchup.active_model.entities
		end
		def defs
			Sketchup.active_model.definitions
		end
		def view
			Sketchup.active_model.active_view
		end
		def mod
			Sketchup.active_model
		end
		def lyrs
			Sketchup.active_model.layers
		end
		
	end
end