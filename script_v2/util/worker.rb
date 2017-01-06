require 'celluloid/current'

class Worker
  include Celluloid
  POOL_SIZE = 50

  def self.distribute(collection, clazz, method)
    worker_pool = pool(size: POOL_SIZE)
    collection.map do |*params|
      worker_pool.future.call(clazz, method, *params)
    end.map(&:value)
  end

  def call(clazz, method, *params)
    clazz.public_send(method, *params)
  end
end
