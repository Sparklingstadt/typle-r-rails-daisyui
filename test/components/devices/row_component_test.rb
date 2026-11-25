require "test_helper"

class Devices::RowComponentTest < ViewComponent::TestCase
  test "the default device has no buttons, and is marked while in use" do
    render_inline(Devices::RowComponent.new(device: nil, usage: nil, current_key: Device::DEFAULT_KEY))

    assert_selector "h3", text: I18n.t("devices.default_name")
    assert_selector ".badge svg.lucide-check"
    assert_no_selector "button"
  end

  test "a device of the user's can be edited and deleted; deleting it says what goes with it" do
    device = users(:one).devices.create!(name: "Laptop", layout: "US")
    render_inline(Devices::RowComponent.new(device:, usage: { count: 4, last: 1.day.ago }, current_key: device.key))

    assert_selector "p", text: "US"
    assert_selector "button[data-visit-url='/devices?edit=#{device.id}']"
    description = page.find("form[action='/devices/#{device.id}']", visible: :all)["data-confirm-description"]
    assert_includes description, I18n.t("design.settings.devices.deleteCurrent"), "it is the device in use"
    assert_includes description, I18n.t("design.settings.devices.deleteRecords", count: 4)
  end
end
