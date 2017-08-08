require 'yaml'

require 'asciidoctor'
require 'asciidoctor/extensions'

class ArticleListBlockMacro < Asciidoctor::Extensions::BlockMacroProcessor
  use_dsl

  named :alist

  def process parent, target, attrs
    
    #order = YAML.load_file(PROJ_ROOT + "/repos/order.yaml")
    order = Blog::Fetch.cache[key = attrs["key"].to_sym]
    html = <<-"HTML"
<table style="width:100%;font-weight: bold;">
  <tbody>
#{
    order.map{|repo|
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
      <td style="text-align: right;">
        #{
          if key == :repos then
            "created at "
          else
            "updated at "
          end
        }
        <span class="icon">
          <i class="fa fa-calendar"></i>
        </span>
        #{
          if key == :repos then
            repo.created_at.to_s
          else
            repo.updated_at.to_s
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
