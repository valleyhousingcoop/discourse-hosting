require 'mock_redis'

Discourse.redis.instance_variable_set(:@redis, MockRedis.new)

ActiveRecord::Base.establish_connection({
  adapter: 'sqlite3',
  database: ':memory:'
})
