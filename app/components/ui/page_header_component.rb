# typle-r's PageHeader: the page's heading and description, with the block (the page's actions) at the end of the row.
# `plain` is the settings pages' header (typle-r's settings and input pages): the title and description alone, full width.
# The page's <title> and the alert under the header are the page's, so UiHelper#page_header adds them.
class Ui::PageHeaderComponent < ApplicationComponent
  def initialize(title, description = nil, plain: false)
    @title = title
    @description = description
    @plain = plain
  end

  def call
    return tag.header(heading, class: "mb-6 space-y-1") if @plain
    tag.header(class: "mb-6 flex flex-wrap items-end justify-between gap-3") do
      safe_join([ tag.div(heading, class: "space-y-1"), (content if content?) ].compact)
    end
  end

  private

  def heading
    safe_join([ tag.h1(@title, class: "text-2xl font-bold"), (tag.p(@description, class: "text-sm text-base-content/60") if @description) ].compact)
  end
end
