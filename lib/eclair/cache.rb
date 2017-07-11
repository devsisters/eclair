module Eclair
  module Cache
    # extend self
    # CACHE_FILE = "#{Config::CACHE_DIR}/cache"
    
    # def mtime
    #   return @mtime if @mtime
    #   @mtime = {}
    #   Dir["#{CACHE_FILE}/*.cache"].each do |cache_file|
    #     key = File.basename cache_file, ".cache"
    #     @mtime[key] = File.mtime cache_file
    #   end
    #   @mtime
    # end

    # def path key
    #   "#{Config::CACHE_DIR}/#{key}.cache"
    # end

    # def update key, value
    #   serialized = Marshal.dump(value)
    #   compressed = Zlib::Deflate.deflate(serialized)
    #   File.write path(key), compressed
    # end

    # def get key
    #   return nil
    #   # return nil unless File.exists? path(key)
    #   serialized = nil
    #   File.open path(key), "r" do |f|
    #     mtime[key] = f.mtime
    #     compressed  = f.read
    #     serialized = Zlib::Inflate.inflate(compressed)
    #   end
    #   Marshal.load(serialized)
    # end

    # def updated? key
    #   return false unless File.exists? path(key)
    #   return true if !mtime[key] || File.mtime(path(key)) > mtime[key]
    #   return false
    # end
  end
end
