require 'yaml'

require 'asciidoctor'
require 'asciidoctor/extensions'

class ArticleListBlockMacro < Asciidoctor::Extensions::BlockMacroProcessor
  use_dsl

  named :alist

  def process parent, target, attrs
    
    order = YAML.load_file(PROJ_ROOT + "/repos/order.yaml")
    html = <<-"HTML"
<div class="dlist">
  <dl>
#{
    order.map{|name, info|
      <<-"LIST"
    <dt class="hdlist1">
      <a href="#{name}/">#{name}</a>
      <span class="icon">
        <i class="fa fa-calendar"></i>
      </span>
      #{info[:time].to_s}
    </dt>
    <dd>
      <p>#{info[:desc]}</p>
    </dd>
LIST
    }.join("\n")
}
  </dl>
</div>
HTML
    #puts html
    create_pass_block parent, html, attrs, subs: nil
  end
end

Asciidoctor::Extensions.register do
  block_macro ArticleListBlockMacro if document.basebackend? 'html'
end
