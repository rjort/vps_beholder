# frozen_string_literal: true

require 'gtk4'
require 'fileutils'
require_relative 'components/container_list'
require_relative 'components/container_details'

# MainWindow acts as the main application orchestrator, managing the Stack
# and handling high-level dialogs and transitions between components.
class MainWindow < Gtk::ApplicationWindow
  def initialize(app, ssh_client, &on_logout)
    super(app)
    @ssh_client = ssh_client
    @on_logout = on_logout

    set_title('VPS Beholder')
    set_default_size(900, 600)

    setup_css
    setup_ui
  end

  private

  def setup_css
    provider = Gtk::CssProvider.new
    provider.load(data: "
      button.logout-btn:hover { background-color: rgba(128, 128, 128, 0.4); }
      .actions-box button { margin-left: 5px; }
      .calendar-btn { margin-bottom: 10px; }
      .edit-btn-style {
        padding: 6px 16px;
      }
    ")
    Gtk::StyleContext.add_provider_for_display(Gdk::Display.default, provider, Gtk::StyleProvider::PRIORITY_APPLICATION)
  end

  def setup_ui
    @stack = Gtk::Stack.new
    @stack.transition_type = :slide_left_right
    set_child(@stack)

    # 1. Initialize Components
    @list_component = Components::ContainerList.new(@ssh_client)
    @details_component = Components::ContainerDetails.new(@ssh_client, self)

    # 2. Wire Events
    wire_list_events
    wire_details_events

    # 3. Add to Stack
    @stack.add_named(@list_component, 'containers')
    @stack.add_named(@details_component, 'details')

    # 4. Start
    @stack.visible_child_name = 'containers'
    @list_component.reload_data
  end

  def wire_list_events
    @list_component.on_logout = proc do
      @ssh_client&.disconnect
      @on_logout&.call
      destroy
    end

    @list_component.on_error = proc do |title, msg|
      show_error_dialog(title, msg)
    end

    @list_component.on_container_selected = proc do |name, icon_path, state|
      @details_component.load_container(name, icon_path, state)
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

    @details_component.on_info = proc do |title, msg|
      show_info_dialog(title, msg)
    end

    @details_component.on_state_changed = proc do |containers|
      @list_component.rebuild_ui(containers)
    end

    @details_component.on_export = proc do |container, date, content|
      export_current_logs(container, date, content)
      @details_component.reload_local_logs
    end
  end

  def export_current_logs(container, date, content)
    base_dir = File.expand_path('~/.vps_beholder/logs')
    container_dir = File.join(base_dir, container)
    FileUtils.mkdir_p(container_dir)

    file_path = File.join(container_dir, "#{date}.log")
    File.write(file_path, content)
  rescue StandardError => e
    show_error_dialog('Error saving log', e.message)
  end

  def show_error_dialog(title, message)
    dialog = Gtk::MessageDialog.new(message: title, buttons: :close)
    dialog.transient_for = self
    dialog.secondary_text = message
    dialog.message_type = :error

    close_btn = dialog.get_widget_for_response(Gtk::ResponseType::CLOSE)
    close_btn&.add_css_class('destructive-action')

    dialog.signal_connect('response') { dialog.destroy }
    dialog.present
  end

  def show_info_dialog(title, message)
    dialog = Gtk::MessageDialog.new(message: title, buttons: :ok)
    dialog.transient_for = self
    dialog.message_type = :info
    dialog.secondary_text = message

    dialog.signal_connect('response') { dialog.destroy }
    dialog.present
  end
end
