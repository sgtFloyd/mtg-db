module Decorator
  def decorate_method(fn, &block)
    fxn = instance_method(fn)
    define_method fn do |*args|
      instance_exec(fxn.bind(self), *args, &block)
    end
  rescue NameError, NoMethodError
    fxn = singleton_class.instance_method(fn).bind(self)
    define_singleton_method fn do |*args|
      instance_exec(fxn, *args, &block)
    end
  end
end

module Memoizer
  include Decorator

  def memoize(fn, cache: Hash.new{|h,k|h[k]={}})
    decorate_method(fn) do |meth, *args|
      unless cache[self].include?(args)
        cache[self][args] = meth.call(*args)
      end
      cache[self][args]
    end
  end
  alias :memo :memoize
end
