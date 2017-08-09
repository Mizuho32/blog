require 'yaml'

require 'asciidoctor'
require 'asciidoctor/extensions'

class ArticleListBlockMacro < Asciidoctor::Extensions::BlockMacroProcessor
  use_dsl

  named :alist

  def process parent, target, attrs
    
    range = Blog::Index.range
    order = Blog::Index.cache[key = attrs["key"].to_sym]
    html = <<-"HTML"
<table style="width:100%;font-weight: bold;">
  <tbody>
#{
    order.drop(ITEM_PER_INDEX_PAGE*(range.first-1)).take(ITEM_PER_INDEX_PAGE).map{|repo|
      <<-"LIST"
    <tr>
      <td>
        <span class="icon">
          <a href="#{repo.url}">
            <i class="fa fa-#{repo.type}"></i>
          </a>
        </span>
        <a href="#{name = repo.name}/">#{name}</a>#{
          if repo.forking then
'''
        <span class="icon">
          <i class="fa fa-code-fork"></i>
        </span>
'''
          else
           "\n"
          end }
      </td>
      <td style="text-align: right;">#{
          if key == :repos then
            <<-"TITLE"
        created at
        <span class="icon">
          <i class="fa fa-calendar"></i>
        </span>
        #{repo.created_at.to_datetime.new_offset(ZONE).to_s}
TITLE
          else
            <<-"TITLE"
        updated at
        <span class="icon">
          <i class="fa fa-level-up"></i>
        </span>
        #{repo.updated_at.to_datetime.new_offset(ZONE).to_s}
TITLE
          end
        }
      </td>
    </tr>
    <tr>
      <td colspan="2">
        <p>#{repo.description || NO_DESC_CAPTION}</p>
      </td>
    </tr>
LIST
    }.join("\n")
}
  </tbody>
</table>
HTML
    #puts html
    create_pass_block parent, html, attrs, subs: nil
  end
end

Asciidoctor::Extensions.register do
  block_macro ArticleListBlockMacro if document.basebackend? 'html'
end

class PagerBlockMacro < Asciidoctor::Extensions::BlockMacroProcessor
  use_dsl

  named :pager

  def process parent, target, attrs
    
    range = Blog::Index.range
    html = <<-"HTML"
      <table><tbody>
        <tr><td>
          #{
            1.step(range.last).map{|i|
              if i == range.first then
                i.to_s
              else
                <<-"A"
          <a class="pager" href="index#{i == 1 ? "" : i}.html" style="color: #4285f4;">
            #{i}
          </a>
A
              end
            }.join("\n")
          }
        </td></tr>
      </tbody></table>
HTML
    create_pass_block parent, html, attrs, subs: nil
  end
end

Asciidoctor::Extensions.register do
  block_macro PagerBlockMacro if document.basebackend? 'html'
end



module Blog
  module Index
    extend self

    class << self
      attr_accessor :cache
      attr_accessor :range
    end

    public 

    def generate_index(last = 0)
      cache = Blog::Fetch.fetch_repos(GIT_HOSTS)
      Blog::Index.cache = Blog::Fetch.index_model(cache)

      last = last.zero? ? 
                (Blog::Index.cache[:repos].size/ITEM_PER_INDEX_PAGE).to_f.ceil :
                [last, (Blog::Index.cache[:repos].size/ITEM_PER_INDEX_PAGE).to_f.ceil].min

      Blog::Index.range = 1..last
      Asciidoctor.convert_file(
        PROJ_ROOT + "/templ/index.adoc", 
        safe:       :unsafe, 
        base_dir:   (PROJ_ROOT + "/templ"), 
        to_dir:     "../articles",
        attributes: { 
          'docinfodir' => (PROJ_ROOT + "/templ/common"), 
          'docinfo'    => "shared"
        }
      )

      templ = File.read(PROJ_ROOT + "/templ/index2.adoc")
      2.step(last).each do |i|
        Blog::Index.range = i..last
        html = Asciidoctor.convert(
          templ,
          safe:       :unsafe, 
          header_footer: true,
          doctype:      :article,
          backend:      :html,
          base_dir:   (PROJ_ROOT + "/templ"), 
          attributes: { 
            'docinfodir' => (PROJ_ROOT + "/templ/common"), 
            'docinfo'    => "shared"
          }
        )
        File.write("#{ARTS_DIR}/index#{i}.html", html)
      end



    end

  end
end
