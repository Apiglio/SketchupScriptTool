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
	
end