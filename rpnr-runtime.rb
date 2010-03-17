class NilClass
	def +(b); b; end # Make + work with nil
	def method_missing(name, *args)
		[].send(name, *args) # Proxy nil onto []
	rescue NoMethodError
		super
	end
end

# List building conveniance
Object.send(:define_method, :',', lambda {|b| [self, b]})
Array.send(:define_method, :',', lambda {|b| self + [b]})

# Multiple operations as one expression conveniance (mostly for lambda)
Object.send(:define_method, :';', lambda {|b| b })

class Object
	# Control flow as methods
	def while(cond, block=nil)
		while cond.is_a?(Proc) ? cond.call : cond
			block && block.call
			block_given? && yield
		end
	end
	def until(cond, block=nil)
		until cond.is_a?(Proc) ? cond.call : cond
			block && block.call
			block_given? && yield
		end
	end
	def if(cond, block_if_true=nil, block_if_false=nil)
		if cond.is_a?(Proc) ? cond.call : cond
			block_if_true && block_if_true.call
		else
			block_if_false && block_if_false.call
		end
	end
	def unless(cond, block_if_true=nil, block_if_false=nil)
		unless cond.is_a?(Proc) ? cond.call : cond
			block_if_true && block_if_true.call
		else
			block_if_false && block_if_false.call
		end
	end

	# Output conveniance
	def puts
		Kernel::puts(to_s)
	end

	# Handle multiple-airity methods being passed a list magically
	def magic_send(message, arg)
		arity = method(message).arity
		if arity < 1
			send(message)
		elsif arg.is_a?(Array) && arity > 1
			send(message, *arg)
		else
			send(message, arg)
		end
	end
end
