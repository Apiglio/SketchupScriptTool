#InstancePathHelper
#Apiglio
#通过组件或组件定义返回所有相关路径

class InstancePathTree
	attr_accessor :children, :parent, :instance
	
	def initialize(instance=nil)
		@parent = nil
		@children = []
		@instance = instance
	end
	
	def add_child(instance)
		child = InstancePathTree.new(instance)
		child.parent = self
		@children.append(child)
		return child
	end
	
	def inspect
		return "#<InstancePathTree: chilren_count=#{children.count}>"
	end
	
	def recur_paths(paths,curpath)
		cpath = [@instance]+curpath
		if @children.empty? then
			paths.append(cpath)
			return nil
		end
		@children.each{|child|
			child.recur_paths(paths,cpath)
		}
	end
	private_methods :recur_paths
	
	def paths
		result=[]
		recur_paths(result,[])
		return result.map{|path|Sketchup::InstancePath.new(path.compact)}
	end
	
	class << self
		def recur_find_parent(node,inst)
			return nil unless inst.parent.is_a? Sketchup::ComponentDefinition
			inst.parent.instances.each{|pinst|
				pnode = node.add_child(pinst)
				recur_find_parent(pnode,pinst)
			}
		end
		private_methods :recur_find_parent
		
		# 返回图元的所有相关路径
		def check_instance(inst)
			raise ArgumentError.new("参数inst必须是图元。") unless inst.respond_to?(:parent)
			result = InstancePathTree.new(inst)
			recur_find_parent(result,inst)
			return result
		end
		
		# 返回组件定义的所有相关路径
		def check_definition(defi)
			raise ArgumentError.new("参数defi需要拥有实例。") unless defi.respond_to?(:instances)
			result = InstancePathTree.new(nil)
			defi.instances.each{|inst|
				pinst = result.add_child(inst)
				recur_find_parent(pinst,inst)
			}
			return result
		end
	end
end






