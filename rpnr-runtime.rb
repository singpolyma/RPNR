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
	def while(block)
		while self.is_a?(Proc) ? self.call : self
			block && block.call
			block_given? && yield
		end
	end
	def until(block)
		until self.is_a?(Proc) ? self.call : self
			block && block.call
			block_given? && yield
		end
	end
	def if(block_if_true, block_if_false=nil)
		if self.is_a?(Proc) ? self.call : self
			block_if_true.is_a?(Proc) ? block_if_true.call : block_if_true
		else
			block_if_false.is_a?(Proc) ? block_if_false.call : block_if_false
		end
	end
	def unless(block_if_true, block_if_false=nil)
		unless self.is_a?(Proc) ? self.call : self
			block_if_true && block_if_true.call
		else
			block_if_false && block_if_false.call
		end
	end

	# Output conveniance
	def puts
		Kernel::puts(to_s)
	end

	# Handle multiple-airity methods being passed a list/block magically
	def magic_send(message, arg)
		arity = method(message).arity
		if arity == 0
			send(message, &arg)
		elsif arity == 1
			send(message, arg)
		else
			case arg
				when nil
					send(message)
				when Array
					if arg.length > arity.abs && arg.last.is_a?(Proc)
						blk = arg.pop
						send(message, *arg, &blk)
					else
						send(message, *arg)
					end
				when Proc
					send(message, &arg)
				else
					send(message, arg)
			end
		end
	end
end
