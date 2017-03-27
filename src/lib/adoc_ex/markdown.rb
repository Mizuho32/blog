require 'asciidoctor'
require 'asciidoctor/extensions'
require 'github/markup'

class MarkdownBlockMacro < Asciidoctor::Extensions::BlockMacroProcessor
  use_dsl

  named :markdown

  def process parent, target, attrs
    html = GitHub::Markup.render_s(GitHub::Markups::MARKUP_MARKDOWN, File.read(target))
    create_pass_block parent, html, attrs, subs: nil
  end
end

Asciidoctor::Extensions.register do
  block_macro MarkdownBlockMacro if document.basebackend? "html"
end
