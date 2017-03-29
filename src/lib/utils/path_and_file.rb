module Blog
  module Util
    extend self

    public

    def repo_name_and_relative_path(path, repos_path)

      # case xxx/xx/repos/repo_name/relative_path
      tmp = path[%r|.*?#{REPOS_DIR}/(.+)|, 1]
      path = tmp if tmp

      path =~ /([^\/]+)\/?(.+)?$/
      return $1&.strip, ($2||"./")&.strip

    end

    def file_type?(path)
      `file -b -i #{path}`.strip
    end

  end
end
