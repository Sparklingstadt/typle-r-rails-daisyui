# typle-r's PageMain: the centred main column of a page, as wide as `width` (Ui::Classes::PAGE_WIDTHS).
class Ui::PageMainComponent < ApplicationComponent
  def initialize(width: :wide, class: nil)
    @width = PAGE_WIDTHS.fetch(width)
    @class = class_option(binding)
  end

  def call
    tag.main(content, class: cn("mx-auto w-full px-4 pt-8 pb-16 sm:px-6 lg:px-8", @width, @class))
  end
end
