# A key on the keyboard (daisyUI's kbd).
class Ui::KbdComponent < ApplicationComponent
  def initialize(text, class: nil)
    @text = text
    @class = class_option(binding)
  end

  def call
    tag.kbd(@text, class: cn("kbd kbd-sm font-sans in-data-[variant=default]:border-current/30 in-data-[variant=default]:bg-transparent in-data-[variant=default]:text-current", @class))
  end
end
