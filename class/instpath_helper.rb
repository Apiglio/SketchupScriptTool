#InstancePathHelper
#Apiglio
#通过组件或组件定义返回所有相关路径

class InstancePathTree
	attr_accessor :children, :parent, :instance, :instpath
	
	def initialize(instance=nil)
		@parent = nil
		@children = []
		@instance = instance
		@instpath = [] # 只在根节点中记录，用于check_subordinate
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
	protected :recur_paths
	
	def paths
		result=[]
		recur_paths(result,[])
		return result.map{|path|Sketchup::InstancePath.new(path.compact)}
	end
	
	def subordinates
		root_path = @instpath.to_a
		result=[]
		recur_paths(result,[])
		#return result.map{|path|root_path+path.compact.reverse}
		return result.map{|path|Sketchup::InstancePath.new(root_path+path.compact.reverse)}
	end
	
	class << self
		
		def recur_find_parent(node,inst)
			return nil unless inst.parent.is_a? Sketchup::ComponentDefinition
			inst.parent.instances.each{|pinst|
				pnode = node.add_child(pinst)
				recur_find_parent(pnode,pinst)
			}
		end
		private :recur_find_parent
		
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
		
		def recur_find_subordinate(node)
			entity = node.instance
			if entity.respond_to?(:definition) then
				entity.definition.entities.each{|ent|
					child = node.add_child(ent)
					recur_find_subordinate(child)
				}
			elsif node.instance.nil? then
				Sketchup.active_model.entities.each{|ent|
					child = node.add_child(ent)
					recur_find_subordinate(child)
				}
			end
		end
		private :recur_find_subordinate
		
		# 返回path之下的所有path
		def check_subordinate_instancepath(instance_path)
			instance_path=[] if instance_path.nil?
			instpath = Sketchup::InstancePath.new(instance_path)
			if instpath.empty? then
				result = InstancePathTree.new(nil)
				result.instpath = []
			else
				instpath_ary = instpath.to_a
				result = InstancePathTree.new(instpath_ary.pop)
				result.instpath = instpath_ary
			end
			recur_find_subordinate(result)
			return result
		end
		private :check_subordinate_instancepath
		
		# 返回definition之下的所有path
		def check_subordinate_definition(definition)
			instpath=[] if instpath.nil?
			raise ArgumentError.new("参数definition必须要有entities成员。") unless definition.respond_to?(:entities)
			result = InstancePathTree.new(nil)
			result.instpath = []	
			definition.entities.each{|ent|
				child = result.add_child(ent)
				recur_find_subordinate(child)
			}
			return result
		end
		private :check_subordinate_definition
		
		def check_subordinate(instpath_or_definition)
			if instpath_or_definition.respond_to?(:entities) then
				check_subordinate_definition(instpath_or_definition)
			else
				check_subordinate_instancepath(instpath_or_definition)
			end
		end
		
	end
end






