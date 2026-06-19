# frozen_string_literal: true

require 'gtk4'

module Components
  # ContainerList manages the main list of containers fetched via SSH.
  class ContainerList < Gtk::Box
    # Event triggered when a container is clicked.
    # Yields: [name, icon_path, state]
    attr_accessor :on_container_selected

    # Event triggered for logout
    attr_accessor :on_logout

    # Fired on error
    # Yields [title, message]
    attr_accessor :on_error

    # Initializes the list
    #
    # @param ssh_client [SSHClient] Client used to fetch containers
    def initialize(ssh_client)
      super(:vertical, 5)
      @ssh_client = ssh_client

      self.margin_start = 10
      self.margin_end = 10
      self.margin_top = 10
      self.margin_bottom = 10

      setup_header
      setup_list
    end

    # Forces an async reload of the containers list
    def reload_data
      Thread.new do
        containers = @ssh_client.list_containers
        GLib::Idle.add do
          rebuild_ui(containers)
          false
        end
      rescue StandardError => e
        GLib::Idle.add do
          @on_error&.call('Failed to load containers', e.message.sub(/^Failed to list containers: /, ''))
          false
        end
      end
    end

    # Publicly updates UI without SSH call
    def rebuild_ui(containers)
      children = []
      child = @list_box.first_child
      while child
        children << child
        child = child.next_sibling
      end
      children.each { |c| @list_box.remove(c) }

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
          icon_path = File.expand_path("../../../assets/icons/#{icon_name}", __dir__)

          status_indicator = Gtk::Image.new(file: icon_path)
          status_indicator.valign = Gtk::Align::CENTER

          name_label = Gtk::Label.new(name)
          name_label.halign = Gtk::Align::START
          name_label.valign = Gtk::Align::CENTER
          name_label.hexpand = true

          logs_icon_path = File.expand_path('../../../assets/icons/terminal.svg', __dir__)
          logs_icon = Gtk::Image.new(file: logs_icon_path)

          logs_btn = Gtk::Button.new
          logs_btn.set_child(logs_icon)
          logs_btn.add_css_class('flat')
          logs_btn.tooltip_text = 'View Logs'
          logs_btn.valign = Gtk::Align::CENTER
          logs_btn.signal_connect('clicked') do
            @on_container_selected&.call(name, icon_path, state)
          end

          row_box.append(status_indicator)
          row_box.append(name_label)
          row_box.append(logs_btn)

          @list_box.append(row_box)
        end
      end
    end

    private

    def setup_header
      header_box = Gtk::Box.new(:horizontal, 10)
      append(header_box)

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
        @on_logout&.call
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
