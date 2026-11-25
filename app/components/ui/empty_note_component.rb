# A short note in a dashed box, where a list has nothing to show.
class Ui::EmptyNoteComponent < ApplicationComponent
  def initialize(text = nil, class: nil)
    @text = text
    @class = class_option(binding)
  end

  def call = tag.p(content? ? content : @text, class: cn(EMPTY_NOTE, @class))
end
