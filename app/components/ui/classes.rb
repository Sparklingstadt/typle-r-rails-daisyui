module Ui
  # The daisyUI classes of the app's parts (btn, badge, card, input, …) and cn(), shared by the components
  # (app/components) and the helpers (UiHelper includes it, so UiHelper::CARD_LIST and the like still read them).
  module Classes
    MERGER = TailwindMerge::Merger.new

    # daisyUI's btn, in the variants and sizes the pages ask for. Each size is named after the daisyUI size it gives.
    BUTTON_BASE = "btn flex-nowrap whitespace-nowrap font-medium"
    BUTTON_VARIANTS = {
      primary: "btn-primary",
      outline: "btn-outline border-base-300 hover:border-base-300 hover:bg-base-200 hover:text-base-content",
      ghost: "btn-ghost",
      error: "btn-error btn-soft",
      link: "btn-link"
    }.freeze
    BUTTON_SIZES = {
      default: "btn-md",
      xs: "btn-xs",
      sm: "btn-sm",
      icon: "btn-square btn-sm",
      "icon-xs": "btn-square btn-xs",
      "icon-sm": "btn-square btn-sm",
      "icon-lg": "btn-square btn-md"
    }.freeze

    BADGE_BASE = "badge badge-sm w-fit shrink-0 gap-1 whitespace-nowrap font-medium [&>svg]:size-3!"
    BADGE_VARIANTS = {
      primary: "badge-primary",
      error: "badge-error badge-soft",
      outline: "badge-outline border-base-300",
      ghost: "badge-ghost",
      warning: "badge-warning badge-soft",
      info: "badge-info badge-soft",
      link: "border-0 bg-transparent text-primary underline-offset-4 hover:underline"
    }.freeze

    # A plain bordered box (daisyUI's card with a border) for a section or a row: its padding and layout are the caller's.
    PANEL = "card card-border border-base-300 bg-base-100"
    PANEL_DASHED = "card card-dash border-base-300 bg-base-100"
    # A card (Ui::CardComponent): a PANEL whose content is clipped to its corners. Its padding and gap are the caller's.
    CARD = "#{PANEL} overflow-hidden text-sm"
    CARD_LIST = "divide-y divide-base-300 overflow-hidden rounded-box border bg-base-100"

    INPUT = "input w-full"
    TEXTAREA = "textarea w-full field-sizing-content min-h-16"
    SELECT_BASE = "select"
    SELECT_VARIANTS = {
      form: "w-full",
      filter: "select-sm w-full",
      compact: "select-sm w-auto"
    }.freeze
    LABEL = "flex items-center gap-2 text-sm leading-none font-medium select-none peer-disabled:cursor-not-allowed peer-disabled:opacity-50"
    SWITCH = "peer toggle toggle-primary"

    TABLE = "table"
    TABLE_HEADER = ""
    TABLE_BODY = ""
    TABLE_ROW = "hover:bg-base-200/50"
    TABLE_HEAD = "whitespace-nowrap text-base-content"
    TABLE_CELL = "whitespace-nowrap"

    ALERT = "alert text-left text-sm"
    ALERT_VARIANTS = { plain: "", error: "alert-error alert-soft", success: "alert-success" }.freeze
    EMPTY_NOTE = "rounded-box border border-dashed bg-base-100 px-5 py-6 text-sm text-base-content/60"
    EMPTY_STATE = "flex flex-col items-center gap-4 rounded-box border border-dashed bg-base-100 px-6 text-center"
    # daisyUI's input as a label around its icon and the field (the field inside takes no style of its own).
    SEARCH_FIELD = "input w-full text-base-content/60"

    # A choice of a few options as a pill (typle-r's ModeToggle and OrderToggle): daisyUI's boxed tabs, its items radio
    # buttons. daisyUI raises the tab that is aria-current; a radio's aria-checked is raised here.
    SEGMENTED = "tabs tabs-box h-9 shrink-0 flex-nowrap rounded-full border border-base-300 bg-base-200/60 p-0.5"
    SEGMENTED_ITEM = "tab h-full rounded-full px-3 text-[13px] text-base-content/60 hover:text-base-content disabled:opacity-60 aria-checked:bg-base-100 aria-checked:font-medium aria-checked:text-base-content aria-checked:shadow-sm"

    PAGE_WIDTHS = { narrow: "max-w-4xl", medium: "max-w-5xl", wide: "max-w-6xl" }.freeze

    # A menu's box and its choices (a check at the left of the chosen one).
    MENU_CONTENT = "menu z-50 flex-nowrap rounded-box border bg-base-100 p-1 text-base-content shadow-md"
    # A menu's action (an icon and its label), and the one that deletes.
    MENU_ITEM = "flex w-full cursor-pointer items-center gap-2.5 rounded-field px-2.5 py-2 text-left text-sm font-normal outline-none select-none hover:bg-base-200 focus-visible:bg-base-200 disabled:pointer-events-none disabled:opacity-50 [&_svg]:size-4 [&_svg]:shrink-0 [&_svg]:text-base-content/60"
    MENU_ITEM_ERROR = MERGER.merge([MENU_ITEM, "text-error hover:bg-error/10 focus-visible:bg-error/10 [&_svg]:text-error"])
    MENU_INSET_ITEM = "relative flex w-full cursor-pointer items-center gap-2 rounded-field py-2 pr-3 pl-8 text-left text-sm outline-none select-none hover:bg-base-200 focus-visible:bg-base-200 has-focus-visible:bg-base-200"

    # cn(): joins classes (leaving out nil and false, from `condition && "classes"`), the later winning over the earlier
    # as tailwind-merge decides.
    def cn(*classes) = MERGER.merge(classes.flatten.select { |name| name.is_a?(String) && !name.empty? }.join(" "))

    def button_classes(variant: :primary, size: :default, class: nil)
      cn(BUTTON_BASE, BUTTON_VARIANTS.fetch(variant.to_sym), BUTTON_SIZES.fetch(size.to_sym), binding.local_variable_get(:class))
    end

    def badge_classes(variant: :primary, class: nil) = cn(BADGE_BASE, BADGE_VARIANTS.fetch(variant.to_sym), binding.local_variable_get(:class))
    def select_classes(variant, extra = nil) = cn(SELECT_BASE, SELECT_VARIANTS.fetch(variant.to_sym), extra)
    def input_classes(extra = nil) = cn(INPUT, extra)
    def textarea_classes(extra = nil) = cn(TEXTAREA, extra)
    def label_classes(extra = nil) = cn(LABEL, extra)
    def alert_classes(variant = :plain, extra = nil) = cn(ALERT, ALERT_VARIANTS.fetch(variant.to_sym), extra)
  end
end
