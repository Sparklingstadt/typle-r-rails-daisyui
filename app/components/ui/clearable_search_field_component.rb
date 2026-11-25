# A search field (daisyUI's input around its icon and the field), with a button that empties it (`clear_url`, as this
# is a GET form), shown while there is something to clear.
class Ui::ClearableSearchFieldComponent < ApplicationComponent
  SIZES = { default: "", sm: "input-sm" }.freeze

  def initialize(name:, value:, label:, size: :default, input_class: nil, class: nil, clear_url: nil, clear_label: nil)
    @name = name
    @value = value
    @label = label
    @size = SIZES.fetch(size)
    @input_class = input_class
    @class = class_option(binding)
    @clear_url = clear_url
    @clear_label = clear_label
  end

  def call
    tag.label(class: cn("input min-w-0 flex-1", @size, @input_class, @class)) do
      safe_join([
        tag.span(@label, class: "sr-only"),
        icon(:search, class: "pointer-events-none size-4 shrink-0 text-base-content/60"),
        search_field_tag(@name, @value, placeholder: @label, autocomplete: "off", class: "grow [&::-webkit-search-cancel-button]:hidden"),
        (clear_link if @value.present? && @clear_url)
      ].compact)
    end
  end

  private

  def clear_link
    link_to(icon(:x, class: "size-3.5"), @clear_url, "aria-label": @clear_label, class: "btn btn-ghost btn-circle btn-xs text-base-content/60")
  end
end
