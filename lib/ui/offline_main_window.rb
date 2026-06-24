# frozen_string_literal: true

require 'gtk4'
require_relative 'components/offline_container_list'
require_relative 'components/offline_container_details'

class OfflineMainWindow < Gtk::ApplicationWindow
  def initialize(app, profile, &on_back_to_home)
    super(app)
    @profile = profile
    @on_back_to_home = on_back_to_home

    set_title("Offline: #{@profile[:alias]}")
    set_default_size(900, 600)

    setup_css
    setup_ui
  end

  private

  def setup_css
    provider = Gtk::CssProvider.new
    provider.load(data: "
      button.logout-btn:hover { background-color: rgba(128, 128, 128, 0.4); }
    ")
    Gtk::StyleContext.add_provider_for_display(Gdk::Display.default, provider, Gtk::StyleProvider::PRIORITY_APPLICATION)
  end

  def setup_ui
    @stack = Gtk::Stack.new
    @stack.transition_type = :slide_left_right
    set_child(@stack)

    @list_component = Components::OfflineContainerList.new(@profile)
    @details_component = Components::OfflineContainerDetails.new(self, @profile)

    wire_list_events
    wire_details_events

    @stack.add_named(@list_component, 'containers')
    @stack.add_named(@details_component, 'details')

    @stack.visible_child_name = 'containers'
    @list_component.reload_data
  end

  def wire_list_events
    @list_component.on_back = proc do
      @on_back_to_home&.call
      destroy
    end

    @list_component.on_container_selected = proc do |name|
      @details_component.load_container(name)
      @stack.visible_child_name = 'details'
    end
  end

  def wire_details_events
    @details_component.on_back = proc do
      @stack.visible_child_name = 'containers'
    end

    @details_component.on_error = proc do |title, msg|
      show_error_dialog(title, msg)
    end
  end

  def show_error_dialog(title, message)
    dialog = Gtk::MessageDialog.new(message: title, buttons: :close)
    dialog.transient_for = self
    dialog.secondary_text = message
    dialog.message_type = :error
    dialog.signal_connect('response') { dialog.destroy }
    dialog.present
  end
end
