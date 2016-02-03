require 'redlock/version'

module Redlock
  autoload :Client, 'redlock/client'
  autoload :RedisInstance, 'redlock/redis_instance'

  LockError = Class.new(StandardError)
end
