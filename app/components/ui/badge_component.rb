# A badge: daisyUI's badge in the app's variants (Ui::Classes::BADGE_VARIANTS).
class Ui::BadgeComponent < ApplicationComponent
  def initialize(text = nil, variant: :primary, class: nil, **options)
    @text = text
    @variant = variant
    @class = class_option(binding)
    @options = options
  end

  def call
    tag.span(content? ? content : @text, class: badge_classes(variant: @variant, class: @class), **@options)
  end
end
