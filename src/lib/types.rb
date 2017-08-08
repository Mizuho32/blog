require 'yaml'

module Blog
  module Index
    module Item

      class IndexItem
        def self.type(type = nil)
          unless type.nil?
            @@type = type
          else
            @@type
          end
        end

        def type
          @@type
        end

        def initialize(obj)
          @repo = obj
          self
        end

        def inspect
          to_s
        end

        def to_s
          <<-"S"
#{name}@#{owner.login}
#{description}

S
        end
      end

      class Github < IndexItem
        type :github

        private

        class Owner
          def initialize(owner)
            @owner = owner
          end

          def login
            @owner[:login]
          end

          def image
            @owner[:avatar_url]
          end
        end

        def _owner(owner)
          @_owner = Owner.new(owner)
        end

        public

        def name
          @repo[:name]
        end

        def owner
          @_owner unless @_owner.nil?

          _owner(@repo[:owner])
        end

        def url
          @repo[:html_url]
        end

        def forking
          @repo[:fork]
        end

        def description
          @repo[:description]
        end

        def created_at
          @repo[:created_at]
        end

        def updated_at
          (a = @repo[:updated_at]) > (b = @repo[:pushed_at]) ? a : b
        end

        def clone_url
          @repo[:clone_url]
        end
      end

      Generic = { github: Github }
    end
  end
end
