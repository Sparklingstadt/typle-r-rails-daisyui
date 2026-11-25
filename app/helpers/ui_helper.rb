# The app's UI parts as helpers: each renders its component (app/components/ui), built on daisyUI. The class strings
# are Ui::Classes'.
module UiHelper
  include Ui::Classes

  # The ItemIndicator of a chosen item; `peer: true` shows it only while the input before it is checked.
  def menu_check(peer: false)
    tag.span(icon(:check, class: "size-4"), class: cn("pointer-events-none absolute left-2.5 inline-flex", peer && "opacity-0 peer-checked:opacity-100"), "aria-hidden": "true")
  end

  # A lucide icon (the set typle-r uses), hidden from screen readers unless it is given a label.
  # Without a size class it is 1rem (application.css), and a button's own size for icons wins, as with lucide-react.
  def icon(name, class: nil, **options)
    lucide_icon(name.to_s, class: cn("lucide lucide-#{name}", binding.local_variable_get(:class)), "aria-hidden": "true", **options)
  end

  # TrendChart's tooltip: the value and date of the run being read, above it (the trend-chart controller fills it).
  def trend_chart_tooltip
    tag.div(hidden: true, "aria-hidden": "true", data: { trend_chart_target: "tooltip" },
            class: "pointer-events-none absolute bottom-full z-10 mb-3 flex flex-col whitespace-nowrap rounded-md bg-base-100 px-2 py-1 text-base-content shadow-md ring-1 ring-base-content/10") do
      safe_join([tag.span(class: "text-sm font-semibold tabular-nums", data: { trend_chart_target: "tooltipValue" }),
                 tag.span(class: "text-xs text-base-content/60", data: { trend_chart_target: "tooltipDate" })])
    end
  end

  # Ui::ButtonComponent as an <a>.
  def link_button(label = nil, url = nil, **options, &block)
    url, label = label, nil if block
    render(Ui::ButtonComponent.new(label, url:, as: :link, **options), &block)
  end

  # Ui::ButtonComponent as a <button> that opens a page (戻る, キャンセル).
  def visit_button(label = nil, url = nil, **options, &block)
    url, label = label, nil if block
    render(Ui::ButtonComponent.new(label, url:, as: :visit, **options), &block)
  end

  # Ui::ButtonComponent as button_to's form.
  def form_button(label, url, **options) = render(Ui::ButtonComponent.new(label, url:, as: :form, **options))

  def ui_badge(text = nil, **options, &block) = render(Ui::BadgeComponent.new(text, **options), &block)

  # Ui::CardComponent and its parts (Ui::Card).
  def card(**options, &block) = render(Ui::CardComponent.new(**options), &block)
  def card_header(**options, &block) = render(Ui::Card::HeaderComponent.new(**options), &block)
  def card_title(text = nil, **options, &block) = render(Ui::Card::TitleComponent.new(text, **options), &block)
  def card_description(text = nil, **options, &block) = render(Ui::Card::DescriptionComponent.new(text, **options), &block)
  def card_action(**options, &block) = render(Ui::Card::ActionComponent.new(**options), &block)
  def card_content(**options, &block) = render(Ui::Card::ContentComponent.new(**options), &block)
  def card_footer(**options, &block) = render(Ui::Card::FooterComponent.new(**options), &block)

  def empty_note(text = nil, **options, &block) = render(Ui::EmptyNoteComponent.new(text, **options), &block)
  def empty_state(**options, &block) = render(Ui::EmptyStateComponent.new(**options), &block)
  def empty_state_icon(name, **options) = render(Ui::EmptyState::IconComponent.new(name, **options))
  def icon_tile(name, **options) = render(Ui::IconTileComponent.new(name, **options))

  def page_main(**options, &block) = render(Ui::PageMainComponent.new(**options), &block)

  # Ui::PageHeaderComponent, which also names the page (its <title>, unless the page has named itself) and is followed
  # by the alert of a refused request.
  def page_header(title, description = nil, plain: false, &block)
    content_for(:title, title) unless content_for?(:title)
    safe_join([ render(Ui::PageHeaderComponent.new(title, description, plain:), &block), page_alert ].compact)
  end

  # typle-r's ErrorAlert, under the page's header: what a request refused (the flash alert), shown once. The layout
  # shows it for the pages without a header (@page_alert_shown).
  def page_alert
    return if alert.blank? || @page_alert_shown
    @page_alert_shown = true
    tag.div(role: "alert", class: alert_classes(:destructive, "mb-6 border-error/40 bg-error/5")) do
      safe_join([ icon("circle-alert"), tag.div(alert, "data-slot": "alert-description", class: "text-sm") ])
    end
  end

  def search_field(**options) = render(Ui::SearchFieldComponent.new(**options))
  def clearable_search_field(**options) = render(Ui::ClearableSearchFieldComponent.new(**options))

  def kbd(text, **options) = render(Ui::KbdComponent.new(text, **options))
end
