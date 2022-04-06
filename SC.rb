path=__FILE__.gsub("\\","/")
path=__FILE__[0..(__FILE__).rindex("/")]

require path+'Sel.rb'
require path+'Cam.rb'

module S
	class <<S
		def ss
			Sel.sels
		end
		def s
			return nil if Sel.sels.length>1
			Sel.sels[0]
		end
		def vw
			Cam.vw
		end
		def vs
			Cam.vs
		end
	end
end