class StatHelper
	@self_arr
	def initialize(source_arr)
		@self_arr=source_arr
	end
	def summarize(&block)
		h=Hash.new
		@self_arr.each{|i|
			begin
				res=block.call(i)
			rescue
				res="N\/A"
			end
			if h.has_key? res then
				h[res]+=1
			else
				h[res]=1
			end
		}
		return(h)
	end
	def classify(&block)
		res=[]
		iden=[]
		for i in 0..@self_arr.length-1 do
			item=@self_arr[i]
			iden_item=block.call(item)
			iden_num=iden.index(iden_item)
			if iden_num==nil then
				iden_num=iden.length
				iden << iden_item
			end
			if res[iden_num]==nil then
				res[iden_num]=[item]
			else
				res[iden_num] << item
			end
		end
		return res
	end
	def to_h_arr(&block)
		res={}
		iden=[]
		for i in 0..@self_arr.length-1 do
			item=@self_arr[i]
			iden_item=block.call(item)
			if res.has_key?(iden_item)
				res[iden_item]<<item
			else
				res[iden_item]=[item]
			end
		end
		return res
	end
	def each_pairs(allow_loop=false,directed=false,&block)
		len=@self_arr.length-1
		0.upto(len) do |i|
			0.upto(len) do |j|
				block.call(@self_arr[i],@self_arr[j]) unless (not allow_loop and i==j) or (not directed and i>j)
			end
		end
	end
	def loops()
		res=[]
		0.upto(@self_arr.length-1) do |bp|
			loop=@self_arr[bp+1..-1]+@self_arr[0..bp]
			res.push(loop)
		end
		res
	end
	def std()
		len=@self_arr.length
		mu=@self_arr.inject{|i,j|i+=j}.to_f/len
		sigma=(@self_arr.inject(0){|i,j|i+=(j-mu)**2}/(len-1))**0.5
	end
	def cov(arr,sample=true)
		len=arr.length
		raise Exception.new("arr.count wrong") unless len==@self_arr.length
		mean1=@self_arr.inject{|i,j|i+=j}.to_f/len
		mean2=arr.inject{|i,j|i+=j}.to_f/len
		mean_product=[]
		0.upto(len-1) do |i|
			mean_product.push((@self_arr[i]-mean1)*(arr[i]-mean2))
		end
		mean_product.inject{|i,j|i+=j}/(len - (sample ? 1 : 0))
	end
	def pearson(arr)
		len=arr.length
		mu1=@self_arr.inject{|i,j|i+=j}.to_f/len
		mu2=arr.inject{|i,j|i+=j}.to_f/len
		sigma1=(@self_arr.inject(0){|i,j|i+=(j-mu1)**2}/(len-1))**0.5
		sigma2=(arr.inject(0){|i,j|i+=(j-mu2)**2}/(len-1))**0.5
		return cov(arr)/sigma1/sigma2
	end
	def rankify()
		n=@self_arr.length
		rank_X=[1]*n
		for i in 0..n-1 do
			r=1
			s=1
			for j in 0..i-1
				if @self_arr[j] < @self_arr[i]
					r+=1
				elsif @self_arr[j] == @self_arr[i]
					s+=1
				end
			end
			for j in i+1..n-1
				if @self_arr[j] < @self_arr[i]
					r+=1
				elsif @self_arr[j] == @self_arr[i]
					s+=1
				end
			end
			rank_X[i]=r+(s-1)*0.5
		end
		return rank_X
	end
	def	spearman(arr)
		len=arr.length
		raise Exception.new("arr.count wrong") unless len==@self_arr.length
		ra1=@self_arr.stat.rankify
		ra2=arr.stat.rankify
		ra1.stat.pearson(ra2)
	end
	def aver_spearman()
		ll=loops
		res=[]
		ll.stat.each_pairs do |i,j|
			res.push(i.stat.spearman(j))
		end
		res
	end
end


class Array
	def stat
		StatHelper.new(self)
	end
end


