# A card (daisyUI's card with a border): a block of the page. Its padding and gap are the page's (class:).
class Ui::CardComponent < ApplicationComponent
  def initialize(class: nil, tag_name: :div, **options)
    @class = class_option(binding)
    @tag_name = tag_name
    @options = options
  end

  def call
    content_tag(@tag_name, content, class: cn(CARD, @class), **@options)
  end
end
