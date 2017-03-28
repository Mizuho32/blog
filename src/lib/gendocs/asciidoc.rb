module Blog
  module DocRenderer
    extend self
    
    public

    def asciidoc(doc_path)
      name = File.basename(doc_path)
      dir  = File.dirname(doc_path)
      adoc = File.read(doc_path)
    
      css = Pathname(PROJ_ROOT + "/articles/css").relative_path_from(Pathname(dir)).to_s
      highlightjs = Pathname(PROJ_ROOT + "/articles/highlight/fordoc").relative_path_from(Pathname(dir)).to_s

      html = Asciidoctor.convert(
        adoc,
        safe: :unsafe,
        header_footer: true,
        attributes: {
          'linkcss'    => "",
          'stylesdir'  => css,
          'source-highlighter' => 'highlightjs',
          'highlightjsdir' => highlightjs,
          'icons' => 'font'
        }
      )
      File.write(dir + ".html", html) 
    end
  end
end
