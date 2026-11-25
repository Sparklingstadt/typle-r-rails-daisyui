# An icon in a muted rounded square, at the head of a row or a card.
class Ui::IconTileComponent < ApplicationComponent
  def initialize(name, class: nil)
    @name = name
    @class = class_option(binding)
  end

  def call
    tag.span(icon(@name, class: "size-5"), class: cn("grid size-10 place-items-center rounded-field bg-base-200 text-base-content/60", @class))
  end
end
