# A card (daisyUI's card with a border): a block of the page, with its parts in Ui::Card.
class Ui::CardComponent < ApplicationComponent
  def initialize(size: :default, class: nil, tag_name: :div, **options)
    @size = size
    @class = class_option(binding)
    @tag_name = tag_name
    @options = options
  end

  def call
    content_tag(@tag_name, content, class: cn(CARD, @class), "data-slot": "card", "data-size": @size, **@options)
  end
end
