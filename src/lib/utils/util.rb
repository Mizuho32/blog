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

    def filename_to_lang(filename)
      FTYPES
          .inject({}){|result, (type, langs)| 
            if l = (langs.select{|pat, la|
              pat =~ filename
            }.values.first) then
              result[:type] = type
              result[:lang] = l
            end
            result
          }
    end

    def unused_num(ar)
      return 0 if ar.empty?

      ar.each_cons(2){|a,b|
        return a + 1 unless a == b - 1
      }

      return ar.last + 1
    end

  end
end
