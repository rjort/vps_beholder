require 'gtk4'
require 'json'

class ConnectionDialog < Gtk::ApplicationWindow
  attr_reader :host, :username, :password

  CONFIG_FILE = File.expand_path('~/.vps_beholder_config.json')

  def initialize(app, &on_connect)
    super(app)
    set_title('Connect to VPS')
    set_default_size(300, 250)

    vbox = Gtk::Box.new(:vertical, 10)
    vbox.margin_start = 10
    vbox.margin_end = 10
    vbox.margin_top = 10
    vbox.margin_bottom = 10
    set_child(vbox)

    @host_entry = Gtk::Entry.new
    @host_entry.placeholder_text = 'User@Host (e.g. root@192.168.1.100)'
    @host_entry.text = load_saved_host
    @host_entry.activates_default = true

    @pass_entry = Gtk::Entry.new
    @pass_entry.placeholder_text = 'Password'
    @pass_entry.visibility = false
    @pass_entry.activates_default = true

    @save_check = Gtk::CheckButton.new
    @save_check.label = 'Salvar usuário'
    @save_check.active = !@host_entry.text.empty?

    vbox.append(@host_entry)
    vbox.append(@pass_entry)
    vbox.append(@save_check)

    button_box = Gtk::Box.new(:horizontal, 10)
    button_box.halign = Gtk::Align::END
    vbox.append(button_box)

    @cancel_btn = Gtk::Button.new
    @cancel_btn.label = 'Cancel'
    @connect_btn = Gtk::Button.new
    @connect_btn.label = 'Connect'

    @connect_btn.add_css_class('suggested-action')
    set_default_widget(@connect_btn)

    button_box.append(@cancel_btn)
    button_box.append(@connect_btn)

    @cancel_btn.signal_connect('clicked') do
      destroy
      app.quit
    end

    @connect_btn.signal_connect('clicked') do
      input = @host_entry.text
      if input.include?('@')
        @username, @host = input.split('@', 2)
      else
        @username = 'root'
        @host = input
      end
      @password = @pass_entry.text

      save_host(input) if @save_check.active?

      on_connect.call(self) if block_given?
    end
  end

  def start_connecting_animation
    @connecting = true
    @connect_btn.sensitive = false
    @cancel_btn.sensitive = false
    @pass_entry.sensitive = false
    @host_entry.sensitive = false
    @save_check.sensitive = false
    @dots = 0
    @connect_btn.label = 'Connecting...'

    GLib::Timeout.add(200) do
      if @connecting
        @dots = (@dots + 1) % 4
        @connect_btn.label = 'Connecting' + ('.' * @dots)
        true
      else
        @connect_btn.label = 'Connect'
        @connect_btn.sensitive = true
        @cancel_btn.sensitive = true
        @pass_entry.sensitive = true
        @host_entry.sensitive = true
        @save_check.sensitive = true
        false
      end
    end
  end

  def stop_connecting_animation
    @connecting = false
  end

  private

  def load_saved_host
    if File.exist?(CONFIG_FILE)
      config = JSON.parse(File.read(CONFIG_FILE))
      config['host'] || ''
    else
      ''
    end
  rescue StandardError
    ''
  end

  def save_host(host)
    config = { 'host' => host }
    File.write(CONFIG_FILE, JSON.generate(config))
  end
end
