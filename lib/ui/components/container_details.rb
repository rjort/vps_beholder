# frozen_string_literal: true

require 'gtk4'
require 'date'
require_relative 'log_preview_window'

module Components
  # ContainerDetails shows actions, log filtering, and local log history.
  class ContainerDetails < Gtk::Box
    attr_accessor :on_back, :on_state_changed, :on_error, :on_info

    # Triggered when an export action is requested from the preview
    # Yields [container, date, content]
    attr_accessor :on_export

    # Initializes the Details pane
    #
    # @param ssh_client [SSHClient] Client used for actions and log fetching
    # @param parent_window [Gtk::Window] The parent window for dialogs
    def initialize(ssh_client, parent_window)
      super(:vertical, 10)
      @ssh_client = ssh_client
      @parent_window = parent_window
      @open_windows = []

      self.margin_start = 10
      self.margin_end = 10
      self.margin_top = 10
      self.margin_bottom = 10

      setup_header
      setup_filter
      setup_local_logs_list
    end

    # Loads a specific container into the details view
    def load_container(name, icon_path, state)
      @current_container = name
      @detail_name_label.text = "#{name} <#{state}>"
      @detail_icon.file = icon_path

      is_running = state.downcase.include?('running')
      @run_btn.sensitive = !is_running
      @stop_btn.sensitive = is_running
      @restart_btn.sensitive = is_running

      reload_local_logs
    end

    # Reloads the local logs list from the disk
    def reload_local_logs
      return unless @current_container

      children = []
      child = @local_logs_list.first_child
      while child
        children << child
        child = child.next_sibling
      end
      children.each { |c| @local_logs_list.remove(c) }

      base_dir = File.expand_path('~/.vps_beholder/logs')
      container_dir = File.join(base_dir, @current_container)
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

        icon = Gtk::Image.new(file: File.expand_path('../../../assets/icons/terminal.svg', __dir__))
        row_box.append(icon)

        file_name = File.basename(file_path)
        name_label = Gtk::Label.new(file_name)
        name_label.halign = Gtk::Align::START
        name_label.hexpand = true
        row_box.append(name_label)

        open_btn = Gtk::Button.new(label: 'Abrir')
        open_btn.signal_connect('clicked') do
          show_read_window(file_name, file_path)
        end
        row_box.append(open_btn)

        @local_logs_list.append(row_box)
      end
    end

    private

    def setup_header
      header_box = Gtk::Box.new(:horizontal, 10)
      append(header_box)

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

      voltar_icon = Gtk::Image.new(file: File.expand_path('../../../assets/icons/arrow_back.svg', __dir__))
      voltar_btn = Gtk::Button.new
      voltar_btn.set_child(voltar_icon)
      voltar_btn.add_css_class('flat')
      voltar_btn.tooltip_text = 'Back to Containers'
      voltar_btn.signal_connect('clicked') { @on_back&.call }
      actions_box.append(voltar_btn)

      # RUN
      run_icon = Gtk::Image.new(file: File.expand_path('../../../assets/icons/play_arrow.svg', __dir__))
      @run_btn = Gtk::Button.new
      @run_btn.set_child(run_icon)
      @run_btn.add_css_class('flat')
      @run_btn.tooltip_text = 'Start Container'
      @run_btn.signal_connect('clicked') { perform_container_action(:start) }
      actions_box.append(@run_btn)

      # STOP
      stop_icon = Gtk::Image.new(file: File.expand_path('../../../assets/icons/stop.svg', __dir__))
      @stop_btn = Gtk::Button.new
      @stop_btn.set_child(stop_icon)
      @stop_btn.add_css_class('flat')
      @stop_btn.tooltip_text = 'Stop Container'
      @stop_btn.signal_connect('clicked') { perform_container_action(:stop) }
      actions_box.append(@stop_btn)

      # RESTART
      restart_icon = Gtk::Image.new(file: File.expand_path('../../../assets/icons/restart_alt.svg', __dir__))
      @restart_btn = Gtk::Button.new
      @restart_btn.set_child(restart_icon)
      @restart_btn.add_css_class('flat')
      @restart_btn.tooltip_text = 'Restart Container'
      @restart_btn.signal_connect('clicked') { perform_container_action(:restart) }
      actions_box.append(@restart_btn)
    end

    def setup_filter
      filter_box = Gtk::Box.new(:horizontal, 10)
      filter_box.halign = Gtk::Align::CENTER
      filter_box.add_css_class('calendar-btn')
      append(filter_box)

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
    end

    def setup_local_logs_list
      scroll = Gtk::ScrolledWindow.new
      scroll.set_policy(:automatic, :automatic)
      scroll.vexpand = true
      append(scroll)

      @local_logs_list = Gtk::ListBox.new
      scroll.set_child(@local_logs_list)
    end

    def fetch_logs_for_current_detail
      return unless @current_container && @selected_date

      container = @current_container
      date = @selected_date

      dialog = Gtk::MessageDialog.new(message: 'Loading logs...', buttons: :none)
      dialog.transient_for = @parent_window
      dialog.present

      Thread.new do
        content = @ssh_client.fetch_logs_by_date(container, date)
        GLib::Idle.add do
          dialog.destroy
          if content.to_s.strip.empty?
            @on_info&.call('Nenhum log encontrado', "O container não gerou logs na data #{date}.")
          else
            show_preview_window(container, date, content)
          end
          false
        end
      rescue StandardError => e
        GLib::Idle.add do
          dialog.destroy
          @on_error&.call('Error fetching logs', e.message)
          false
        end
      end
    end

    def perform_container_action(action)
      return unless @current_container

      container = @current_container
      dialog = Gtk::MessageDialog.new(message: "Executing #{action} on #{container}...", buttons: :none)
      dialog.transient_for = @parent_window
      dialog.present

      Thread.new do
        case action
        when :start then @ssh_client.start_container(container)
        when :stop then @ssh_client.stop_container(container)
        when :restart then @ssh_client.restart_container(container)
        end

        containers = @ssh_client.list_containers
        target = containers.find { |c| c[:name] == container }
        new_state = target ? target[:state] : 'unknown'

        GLib::Idle.add do
          dialog.destroy
          icon_name = case new_state.downcase
                      when 'running' then 'running.svg'
                      when 'exited', 'dead' then 'exited.svg'
                      else 'warning.svg'
                      end
          icon_path = File.expand_path("../../../assets/icons/#{icon_name}", __dir__)

          # Update local UI
          load_container(container, icon_path, new_state)

          # Emit to parent so it updates the main list
          @on_state_changed&.call(containers)
          false
        end
      rescue StandardError => e
        GLib::Idle.add do
          dialog.destroy
          @on_error&.call("Error executing #{action}", e.message)
          false
        end
      end
    end

    def show_preview_window(container, date, content)
      viewer = LogPreviewWindow.new(
        title: "Preview: #{container} - #{date}",
        content: content,
        mode: :preview,
        container: container,
        date: date
      )
      viewer.on_export = proc do |c, d, ct|
        @on_export&.call(c, d, ct)
      end
      track_window(viewer)
      viewer.present
    end

    def show_read_window(file_name, file_path)
      content = File.read(file_path)
      viewer = LogPreviewWindow.new(
        title: "Lendo: #{file_name}",
        content: content,
        mode: :read
      )
      track_window(viewer)
      viewer.present
    rescue StandardError => e
      @on_error&.call('Error reading log file', e.message)
    end

    def track_window(viewer)
      @open_windows << viewer
      viewer.signal_connect('close-request') do
        @open_windows.delete(viewer)
        false
      end
    end
  end
end
