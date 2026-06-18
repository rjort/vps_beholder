require 'gtk4'
require 'fileutils'
require 'date'

class MainWindow < Gtk::ApplicationWindow
  def initialize(app, ssh_client, &on_logout)
    super(app)
    @ssh_client = ssh_client
    @on_logout = on_logout

    set_title('VPS Beholder')
    set_default_size(900, 600)

    @open_windows = []

    setup_css
    setup_ui
    load_containers
  end

  private

  def setup_css
    provider = Gtk::CssProvider.new
    provider.load(data: "
      button.logout-btn:hover { background-color: rgba(128, 128, 128, 0.4); }
      .actions-box button { margin-left: 5px; }
      .calendar-btn { margin-bottom: 10px; }
    ")
    Gtk::StyleContext.add_provider_for_display(Gdk::Display.default, provider, Gtk::StyleProvider::PRIORITY_APPLICATION)
  end

  def setup_ui
    @stack = Gtk::Stack.new
    @stack.transition_type = :slide_left_right
    set_child(@stack)

    @containers_page = Gtk::Box.new(:vertical, 5)
    @containers_page.margin_start = 10
    @containers_page.margin_end = 10
    @containers_page.margin_top = 10
    @containers_page.margin_bottom = 10
    setup_containers_page
    @stack.add_named(@containers_page, 'containers')

    @details_page = Gtk::Box.new(:vertical, 10)
    @details_page.margin_start = 10
    @details_page.margin_end = 10
    @details_page.margin_top = 10
    @details_page.margin_bottom = 10
    setup_details_page
    @stack.add_named(@details_page, 'details')

    @stack.visible_child_name = 'containers'
  end

  def setup_containers_page
    header_box = Gtk::Box.new(:horizontal, 10)
    @containers_page.append(header_box)

    label = Gtk::Label.new("User: #{@ssh_client.username} - Host: #{@ssh_client.host}")
    label.halign = Gtk::Align::START
    label.hexpand = true
    header_box.append(label)

    logout_label = Gtk::Label.new
    logout_label.set_markup('<b>LOGOUT</b>')
    logout_btn = Gtk::Button.new
    logout_btn.set_child(logout_label)
    logout_btn.add_css_class('flat')
    logout_btn.add_css_class('logout-btn')
    header_box.append(logout_btn)

    logout_btn.signal_connect('clicked') do
      @ssh_client&.disconnect
      @on_logout&.call
      destroy
    end

    scroll = Gtk::ScrolledWindow.new
    scroll.set_policy(:automatic, :automatic)
    scroll.vexpand = true
    @containers_page.append(scroll)

    @list_box = Gtk::ListBox.new
    scroll.set_child(@list_box)
  end

  def setup_details_page
    # HEADER
    header_box = Gtk::Box.new(:horizontal, 10)
    @details_page.append(header_box)

    @detail_icon = Gtk::Image.new
    @detail_icon.pixel_size = 16
    header_box.append(@detail_icon)

    @detail_name_label = Gtk::Label.new('')
    @detail_name_label.halign = Gtk::Align::START
    @detail_name_label.hexpand = true
    header_box.append(@detail_name_label)

    actions_box = Gtk::Box.new(:horizontal, 5)
    actions_box.add_css_class('actions-box')
    header_box.append(actions_box)

    voltar_icon = Gtk::Image.new(file: File.expand_path('../../assets/icons/arrow_back.svg', __dir__))
    voltar_btn = Gtk::Button.new
    voltar_btn.set_child(voltar_icon)
    voltar_btn.add_css_class('flat')
    voltar_btn.tooltip_text = 'Back to Containers'
    voltar_btn.signal_connect('clicked') do
      @stack.visible_child_name = 'containers'
    end
    actions_box.append(voltar_btn)

    pause_icon = Gtk::Image.new(file: File.expand_path('../../assets/icons/pause.svg', __dir__))
    pause_btn = Gtk::Button.new
    pause_btn.set_child(pause_icon)
    pause_btn.add_css_class('flat')
    pause_btn.tooltip_text = 'Pause Container'
    pause_btn.sensitive = false # Placeholder
    actions_box.append(pause_btn)

    run_icon = Gtk::Image.new(file: File.expand_path('../../assets/icons/play_arrow.svg', __dir__))
    run_btn = Gtk::Button.new
    run_btn.set_child(run_icon)
    run_btn.add_css_class('flat')
    run_btn.tooltip_text = 'Run Container'
    run_btn.sensitive = false # Placeholder
    actions_box.append(run_btn)

    # MIDDLE (Filter)
    filter_box = Gtk::Box.new(:horizontal, 10)
    filter_box.halign = Gtk::Align::CENTER
    filter_box.add_css_class('calendar-btn')
    @details_page.append(filter_box)

    @date_picker_btn = Gtk::MenuButton.new
    @date_picker_btn.label = Date.today.strftime('%Y-%m-%d')
    popover = Gtk::Popover.new
    @calendar = Gtk::Calendar.new
    popover.set_child(@calendar)
    @date_picker_btn.popover = popover
    filter_box.append(@date_picker_btn)

    @calendar.signal_connect('day-selected') do
      d = @calendar.date
      @selected_date = format('%04d-%02d-%02d', d.year, d.month, d.day_of_month)
      @date_picker_btn.label = @selected_date
      popover.popdown
    end

    @selected_date = Date.today.strftime('%Y-%m-%d')

    fetch_btn = Gtk::Button.new(label: 'Buscar do Container')
    fetch_btn.add_css_class('suggested-action')
    fetch_btn.signal_connect('clicked') { fetch_logs_for_current_detail }
    filter_box.append(fetch_btn)

    # BOTTOM (Local Files List)
    scroll = Gtk::ScrolledWindow.new
    scroll.set_policy(:automatic, :automatic)
    scroll.vexpand = true
    @details_page.append(scroll)

    @local_logs_list = Gtk::ListBox.new
    scroll.set_child(@local_logs_list)
  end

  def load_containers
    containers = @ssh_client.list_containers
    if containers.empty?
      label = Gtk::Label.new('No containers found.')
      @list_box.append(label)
    else
      containers.each do |container|
        name = container[:name]
        state = container[:state]
        next if name.empty?

        row_box = Gtk::Box.new(:horizontal, 10)
        row_box.margin_start = 10
        row_box.margin_end = 10
        row_box.margin_top = 5
        row_box.margin_bottom = 5

        icon_name = case state.downcase
                    when 'running' then 'running.svg'
                    when 'exited', 'dead' then 'exited.svg'
                    else 'warning.svg'
                    end
        icon_path = File.expand_path("../../assets/icons/#{icon_name}", __dir__)

        status_indicator = Gtk::Image.new(file: icon_path)
        status_indicator.valign = Gtk::Align::CENTER

        name_label = Gtk::Label.new(name)
        name_label.halign = Gtk::Align::START
        name_label.valign = Gtk::Align::CENTER
        name_label.hexpand = true

        logs_icon_path = File.expand_path('../../assets/icons/terminal.svg', __dir__)
        logs_icon = Gtk::Image.new(file: logs_icon_path)

        logs_btn = Gtk::Button.new
        logs_btn.set_child(logs_icon)
        logs_btn.add_css_class('flat')
        logs_btn.tooltip_text = 'View Logs'
        logs_btn.valign = Gtk::Align::CENTER
        logs_btn.signal_connect('clicked') do
          open_details_page(name, icon_path, state)
        end

        row_box.append(status_indicator)
        row_box.append(name_label)
        row_box.append(logs_btn)

        @list_box.append(row_box)
      end
    end
  rescue StandardError => e
    show_error_dialog('Failed to load containers', e.message.sub(/^Failed to list containers: /, ''))
  end

  def open_details_page(name, icon_path, state)
    @current_container = name
    @detail_name_label.text = "#{name} <#{state}>"
    @detail_icon.file = icon_path
    @stack.visible_child_name = 'details'
    load_local_logs_for_container(name)
  end

  def load_local_logs_for_container(name)
    children = []
    child = @local_logs_list.first_child
    while child
      children << child
      child = child.next_sibling
    end
    children.each { |c| @local_logs_list.remove(c) }

    base_dir = File.expand_path('~/.vps_beholder/logs')
    container_dir = File.join(base_dir, name)
    return unless Dir.exist?(container_dir)

    files = Dir.glob(File.join(container_dir, '*.log')).sort.reverse
    if files.empty?
      @local_logs_list.append(Gtk::Label.new('Nenhum log salvo localmente.'))
      return
    end

    files.each do |file_path|
      row_box = Gtk::Box.new(:horizontal, 10)
      row_box.margin_start = 10
      row_box.margin_end = 10
      row_box.margin_top = 5
      row_box.margin_bottom = 5

      icon = Gtk::Image.new(file: File.expand_path('../../assets/icons/terminal.svg', __dir__))
      row_box.append(icon)

      file_name = File.basename(file_path)
      name_label = Gtk::Label.new(file_name)
      name_label.halign = Gtk::Align::START
      name_label.hexpand = true
      row_box.append(name_label)

      open_btn = Gtk::Button.new(label: 'Abrir')
      open_btn.signal_connect('clicked') do
        show_saved_log_window(file_name, file_path)
      end
      row_box.append(open_btn)

      @local_logs_list.append(row_box)
    end
  end

  def fetch_logs_for_current_detail
    return unless @current_container && @selected_date

    container = @current_container
    date = @selected_date

    dialog = Gtk::MessageDialog.new(
      message: 'Loading logs...'
    )
    dialog.transient_for = self
    dialog.present

    Thread.new do
      content = @ssh_client.fetch_logs_by_date(container, date)
      GLib::Idle.add do
        dialog.destroy
        show_log_preview_window(container, date, content)
        false
      end
    rescue StandardError => e
      GLib::Idle.add do
        dialog.destroy
        show_error_dialog('Error fetching logs', e.message)
        false
      end
    end
  end

  def show_log_preview_window(container, date, content)
    viewer = Gtk::Window.new
    @open_windows << viewer
    viewer.signal_connect('close-request') do
      @open_windows.delete(viewer)
      false
    end

    viewer.set_title("Preview: #{container} - #{date}")
    viewer.set_default_size(800, 600)

    vbox = Gtk::Box.new(:vertical, 5)
    viewer.set_child(vbox)

    scroll = Gtk::ScrolledWindow.new
    scroll.set_policy(:automatic, :automatic)
    scroll.vexpand = true
    vbox.append(scroll)

    text_view = Gtk::TextView.new
    text_view.editable = false
    text_view.monospace = true
    text_view.buffer.text = content.empty? ? "No logs found for #{date}." : content
    scroll.set_child(text_view)

    export_box = Gtk::Box.new(:horizontal, 10)
    export_box.halign = Gtk::Align::END
    export_box.margin_end = 10
    export_box.margin_bottom = 10
    export_box.margin_top = 5
    vbox.append(export_box)

    export_btn = Gtk::Button.new(label: 'Exportar / Salvar Logs')
    export_btn.sensitive = !content.empty?
    export_btn.signal_connect('clicked') do
      export_current_logs(container, date, content)
      export_btn.sensitive = false
      export_btn.label = 'Salvo!'
    end
    export_box.append(export_btn)

    viewer.present
  end

  def show_saved_log_window(file_name, file_path)
    content = File.read(file_path)

    viewer = Gtk::Window.new
    @open_windows << viewer
    viewer.signal_connect('close-request') do
      @open_windows.delete(viewer)
      false
    end

    viewer.set_title("Lendo: #{file_name}")
    viewer.set_default_size(800, 600)

    scroll = Gtk::ScrolledWindow.new
    scroll.set_policy(:automatic, :automatic)
    viewer.set_child(scroll)

    text_view = Gtk::TextView.new
    text_view.editable = false
    text_view.monospace = true
    text_view.buffer.text = content
    scroll.set_child(text_view)

    viewer.present
  rescue StandardError => e
    show_error_dialog('Error reading log file', e.message)
  end

  def export_current_logs(container, date, content)
    base_dir = File.expand_path('~/.vps_beholder/logs')
    container_dir = File.join(base_dir, container)
    FileUtils.mkdir_p(container_dir)

    file_path = File.join(container_dir, "#{date}.log")
    File.write(file_path, content)

    load_local_logs_for_container(container)
  end

  def show_error_dialog(title, message)
    dialog = Gtk::MessageDialog.new(
      message: title
    )
    dialog.transient_for = self
    dialog.secondary_text = message

    close_btn = dialog.get_widget_for_response(Gtk::ResponseType::CLOSE)
    close_btn&.add_css_class('destructive-action')

    dialog.signal_connect('response') { dialog.destroy }
    dialog.present
  end
end
