require "benchmark"

module Eclair
  module BenchmarkHelper
    def benchmark(name, &blk)
      result = nil
      if ENV['BM']
        bm = Benchmark.measure do
          result = blk.call
        end
        STDERR.puts "Elasped Time for #{name}:"
        STDERR.puts bm
        result
      else
        blk.call
      end
    end
  end
end
