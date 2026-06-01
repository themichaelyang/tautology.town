module Jekyll
  class CardBlock < Liquid::Block

    def render(context)
      text = super
      converter = context.registers[:site].find_converter_instance(::Jekyll::Converters::Markdown)
      # blockquote so reader view shows this correctly
      "<blockquote class=\"card\">#{converter.convert text}</blockquote>"
    end

  end
end

Liquid::Template.register_tag('card', Jekyll::CardBlock)
