# frozen_string_literal: true

require 'gtk4'
require_relative '../../data/log_manager'

module Components
  # Offline list of containers that have downloaded logs
  class OfflineContainerList < Gtk::Box
    attr_accessor :on_container_selected, :on_back

    # @param profile [Hash] The offline profile
    def initialize(profile)
      super(:vertical, 5)
      @profile = profile

      self.margin_start = 10
      self.margin_end = 10
      self.margin_top = 10
      self.margin_bottom = 10

      setup_header
      setup_list
    end

    # Loads containers from disk
    def reload_data
      containers = Storage::LogManager.list_containers(@profile[:id])
      rebuild_ui(containers)
    end

    # Updates UI
    # @param containers [Array<String>] Container names
    def rebuild_ui(containers)
      children = []
      child = @list_box.first_child
      while child
        children << child
        child = child.next_sibling
      end
      children.each { |c| @list_box.remove(c) }

      if containers.empty?
        @list_box.append(Gtk::Label.new('Nenhum log offline encontrado.'))
      else
        containers.each do |name|
          row_box = Gtk::Box.new(:horizontal, 10)
          row_box.margin_start = 10
          row_box.margin_end = 10
          row_box.margin_top = 5
          row_box.margin_bottom = 5

          icon_path = File.expand_path('../../../assets/icons/terminal.svg', __dir__)
          icon = Gtk::Image.new(file: icon_path)
          row_box.append(icon)

          name_label = Gtk::Label.new(name)
          name_label.halign = Gtk::Align::START
          name_label.hexpand = true
          row_box.append(name_label)

          view_btn = Gtk::Button.new(label: 'Ver Histórico')
          view_btn.add_css_class('flat')
          view_btn.signal_connect('clicked') do
            @on_container_selected&.call(name)
          end
          row_box.append(view_btn)

          @list_box.append(row_box)
        end
      end
    end

    private

    def setup_header
      header_box = Gtk::Box.new(:horizontal, 10)
      append(header_box)

      label = Gtk::Label.new("Host Offline: #{@profile[:alias]} (#{@profile[:host]})")
      label.halign = Gtk::Align::START
      label.hexpand = true
      header_box.append(label)

      back_icon = Gtk::Image.new(file: File.expand_path('../../../assets/icons/arrow_back.svg', __dir__))
      back_btn = Gtk::Button.new
      back_btn.set_child(back_icon)
      back_btn.add_css_class('flat')
      back_btn.tooltip_text = 'Voltar para Home'
      header_box.append(back_btn)

      back_btn.signal_connect('clicked') do
        @on_back&.call
      end
    end

    def setup_list
      scroll = Gtk::ScrolledWindow.new
      scroll.set_policy(:automatic, :automatic)
      scroll.vexpand = true
      append(scroll)

      @list_box = Gtk::ListBox.new
      scroll.set_child(@list_box)
    end
  end
end
