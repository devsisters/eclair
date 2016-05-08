module Eclair
  class Cache
    CACHE_FILE = "#{ENV['HOME']}/.ecl/.cache"

    def initialize
      @data = {}
      if File.exists? CACHE_FILE
        compressed  = File.read(CACHE_FILE)
        serialized = Zlib::Inflate.inflate(compressed)
        @data = Marshal.load(serialized)
      end
    end

    def update key, value
      @data[key] = value
      serialized = Marshal.dump(@data)
      compressed = Zlib::Deflate.deflate(serialized)
      File.write CACHE_FILE, compressed
    end

    def get key
      @data[key]
    end
  end

  extend self

  def cache
    @cache ||= Cache.new
  end
end
