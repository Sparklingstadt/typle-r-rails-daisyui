# A button (daisyUI's btn, in Ui::Classes' variants and sizes), as the element that does what it does:
#   :link  — an <a> that looks like a button;
#   :visit — a <button> that opens a page, for typle-r's buttons that navigate (戻る, キャンセル): read as a button, not a
#            link. The click is handled in application.js; an editor's unsaved-changes check still runs (turbo:before-visit);
#   :form  — button_to's form, for a request that changes something.
class Ui::ButtonComponent < ApplicationComponent
  KINDS = %i[link visit form].freeze

  def initialize(label = nil, url:, as: :link, variant: :primary, size: :default, class: nil, icon: nil, form_class: "contents", **options)
    raise ArgumentError, "unknown button kind: #{as.inspect}" unless KINDS.include?(as)
    @label = label
    @url = url
    @as = as
    @variant = variant
    @size = size
    @class = class_option(binding)
    @icon = icon
    @form_class = form_class
    @options = options
  end

  def call
    classes = button_classes(variant: @variant, size: @size, class: @class)
    case @as
    when :link then link_to(@url, class: classes, **@options) { body }
    when :visit then tag.button(type: "button", class: classes, "data-visit-url": @url, **@options) { body }
    when :form then button_to(@url, class: classes, form_class: @form_class, **@options) { body }
    end
  end

  private

  def body = safe_join([ (icon(@icon) if @icon), content? ? content : @label ].compact)
end
