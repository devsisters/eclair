module Eclair
  module LessViewer
    extend self
    class ColorPP < ::PP
      def self.pp(obj, out = $>, width = 79)
        q = ColorPP.new(out, width)
        q.guard_inspect_key { q.pp obj }
        q.flush
        out << "\n"
      end
      
      def text(str, width = str.length)
        super(CodeRay.scan(str, :ruby).term, width)
      end
    end

    def show obj
      IO.popen("less -R -C", "w") do |f|
        ColorPP.pp(obj, f)
      end
    end
  end
end
