# typle-r's EmptyState: a dashed box, centred, for a page or a list with nothing in it yet (its icon is
# Ui::EmptyState::IconComponent).
class Ui::EmptyStateComponent < ApplicationComponent
  def initialize(class: nil)
    @class = class_option(binding)
  end

  def call = tag.div(content, class: cn(EMPTY_STATE, @class))
end
