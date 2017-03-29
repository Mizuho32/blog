module Blog
  module Util
    extend self

    public 

    def shebang_to_lang(line)
      line =~ /^#!(?:\/[^\/]+)+?\/([^\/\s]+)(?:$|\s+)(\w+)?/i
      $2 || $1
    end

    def guess_lang(file_path)
      File.open(file_path){|file|
        shebang_to_lang(file.readline)
      }
    end

  end
end
