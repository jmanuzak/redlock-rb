module Redlock
  class Client
    class RedisInstance
      UNLOCK_SCRIPT = <<-eos
        if redis.call("get",KEYS[1]) == ARGV[1] then
          return redis.call("del",KEYS[1])
        else
          return 0
        end
      eos

      # thanks to https://github.com/sbertrang/redis-distlock/blob/master/lib/Redis/DistLock.pm
      # also https://github.com/sbertrang/redis-distlock/issues/2 which proposes the value-checking
      # and @maltoe for https://github.com/leandromoreira/redlock-rb/pull/20#discussion_r38903633
      LOCK_SCRIPT = <<-eos
        if redis.call("exists", KEYS[1]) == 0 or redis.call("get", KEYS[1]) == ARGV[1] then
          return redis.call("set", KEYS[1], ARGV[1], "PX", ARGV[2])
        end
      eos

      def initialize(connection)
        if connection.respond_to?(:client)
          @redis = connection
        else
          @redis  = Redis.new(connection)
        end

        load_scripts
      end

      def lock(resource, val, ttl)
        recover_from_script_flush do
          @redis.evalsha @lock_script_sha, :keys => [resource], :argv => [val, ttl]
        end
      end

      def unlock(resource, val)
        recover_from_script_flush do
          @redis.evalsha @unlock_script_sha, :keys => [resource], :argv => [val]
        end
      rescue
        # Nothing to do, unlocking is just a best-effort attempt.
      end

      private

      def load_scripts
        @unlock_script_sha = @redis.script(:load, UNLOCK_SCRIPT)
        @lock_script_sha = @redis.script(:load, LOCK_SCRIPT)
      end

      def recover_from_script_flush
        retry_on_noscript = true
        begin
          yield
        rescue Redis::CommandError => e
          # When somebody has flushed the Redis instance's script cache, we might
          # want to reload our scripts. Only attempt this once, though, to avoid
          # going into an infinite loop.
          if retry_on_noscript && e.message.include?('NOSCRIPT')
            load_scripts
            retry_on_noscript = false
            retry
          else
            raise
          end
        end
      end
    end
  end
end
