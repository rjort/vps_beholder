# frozen_string_literal: true

require 'gtk4'
require_relative 'log_preview_window'
require_relative '../../data/log_manager'

module Components
  # View for displaying local log history for a specific container
  class OfflineContainerDetails < Gtk::Box
    attr_accessor :on_back, :on_error

    # @param parent_window [Gtk::Window] The parent window for dialogs
    # @param profile [Hash] The active profile
    def initialize(parent_window, profile)
      super(:vertical, 10)
      @parent_window = parent_window
      @profile = profile
      @open_windows = []

      self.margin_start = 10
      self.margin_end = 10
      self.margin_top = 10
      self.margin_bottom = 10

      setup_header
      setup_local_logs_list
    end

    # Loads the history for a container
    # @param name [String] The container name
    def load_container(name)
      @current_container = name
      @detail_name_label.text = "Histórico: #{name}"
      reload_local_logs
    end

    # Reloads local files list
    def reload_local_logs
      return unless @current_container

      children = []
      child = @local_logs_list.first_child
      while child
        children << child
        child = child.next_sibling
      end
      children.each { |c| @local_logs_list.remove(c) }

      files = Storage::LogManager.list_logs(@profile[:id], @current_container)
      if files.empty?
        @local_logs_list.append(Gtk::Label.new('Nenhum log salvo localmente.'))
        return
      end

      files.each do |file_name|
        row_box = Gtk::Box.new(:horizontal, 10)
        row_box.margin_start = 10
        row_box.margin_end = 10
        row_box.margin_top = 5
        row_box.margin_bottom = 5

        icon = Gtk::Image.new(file: File.expand_path('../../../assets/icons/terminal.svg', __dir__))
        row_box.append(icon)

        name_label = Gtk::Label.new(file_name)
        name_label.halign = Gtk::Align::START
        name_label.hexpand = true
        row_box.append(name_label)

        open_btn = Gtk::Button.new(label: 'Abrir')
        open_btn.signal_connect('clicked') do
          show_read_window(file_name)
        end
        row_box.append(open_btn)

        @local_logs_list.append(row_box)
      end
    end

    private

    def setup_header
      header_box = Gtk::Box.new(:horizontal, 10)
      append(header_box)

      @detail_icon = Gtk::Image.new(file: File.expand_path('../../../assets/icons/terminal.svg', __dir__))
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
    end

    def setup_local_logs_list
      scroll = Gtk::ScrolledWindow.new
      scroll.set_policy(:automatic, :automatic)
      scroll.vexpand = true
      append(scroll)

      @local_logs_list = Gtk::ListBox.new
      scroll.set_child(@local_logs_list)
    end

    def show_read_window(file_name)
      content = Storage::LogManager.read_log(@profile[:id], @current_container, file_name)
      raise 'Log content not found' unless content

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
