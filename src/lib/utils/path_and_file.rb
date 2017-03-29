module Blog
  module Util
    extend self

    public


    def repo_name_and_relative_path(path, repos_path)
      fullpath = File.expand_path(path)

      # case xxx/xx/repos/repo_name/relative_path
      if fullpath.include?(repos_path) then

        # pick repo_name and relative_path
        fullpath.sub(repos_path, "") =~ /\/?([^\/]+)\/?(.+)?$/
        return $1&.strip, ($2||"./")&.strip

      # case repo_name/relative_path
      else

        path =~ /([^\/]+)\/?(.+)?$/
        return $1&.strip, ($2||"./")&.strip

      end
    end

    def file_type?(path)
      `file -b -i #{path}`.strip
  end


  end
end
