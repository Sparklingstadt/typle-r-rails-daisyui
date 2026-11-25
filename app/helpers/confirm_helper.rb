# The data of a form whose submission asks first, in typle-r's AlertDialog (layouts/application/_confirm_dialog).
module ConfirmHelper
  # A deletion as typle-r's DeleteConfirmation words it: the description is followed by "この操作は取り消せません。"
  def delete_confirm_data(title:, description:, details: nil, action: nil)
    confirm_data(title:, description: tt("common.delete.description", description:), details:, action:)
  end

  # typle-r's DeleteListDialog with its DeleteDetails: what the list holds, and its CSV export to keep the words.
  def list_delete_confirm_data(list, records)
    description = [records.any? ? tt("wordLists.delete.withRecords") : tt("wordLists.delete.listOnly"),
                   (tt("wordLists.delete.lastInPack", name: list.pack.name) if list.pack.word_lists.size == 1)].compact.join(" ")
    details = render(WordLists::DeleteDetailsComponent.new(list:, records:))
    delete_confirm_data(title: tt("wordLists.delete.title", name: list.name), description:, details:)
  end

  # typle-r's UnfollowDialog.
  def unfollow_confirm_data(name)
    delete_confirm_data(title: tt("wordLists.follow.title", name:), description: tt("wordLists.follow.description", name:), action: tt("wordLists.follow.confirm"))
  end

  def confirm_data(title:, description: nil, details: nil, action: nil, cancel: nil, variant: :error)
    { turbo_confirm: title, confirm_description: description, confirm_details: details&.to_str, confirm_action: action,
      confirm_cancel: cancel, confirm_variant: variant }.compact
  end
end
