# A section of the dashboard: its heading (labelling it) and description, then the block.
class Home::SectionComponent < ApplicationComponent
  def initialize(id:, title:, description:)
    @id = id
    @title = title
    @description = description
  end

  def call
    tag.section(class: "flex flex-col gap-4", "aria-labelledby": @id) do
      safe_join([tag.div(class: "space-y-1") { safe_join([tag.h2(@title, id: @id, class: "text-xl"), tag.p(@description, class: "text-sm text-base-content/60")]) }, content])
    end
  end
end
