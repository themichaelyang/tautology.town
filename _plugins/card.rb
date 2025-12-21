module Jekyll
  class CardBlock < Liquid::Block

    def render(context)
      text = super
      converter = context.registers[:site].find_converter_instance(::Jekyll::Converters::Markdown)
      "<div class=\"card\">#{converter.convert text}</div>"
    end

  end
end

Liquid::Template.register_tag('card', Jekyll::CardBlock)
