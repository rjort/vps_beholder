require 'gtk4'

class MainWindow < Gtk::ApplicationWindow
  def initialize(app, ssh_client, &on_logout)
    super(app)
    @ssh_client = ssh_client
    @on_logout = on_logout

    set_title('VPS Beholder')
    set_default_size(900, 600)

    setup_ui
    load_containers
  end

  private

  def setup_ui
    vbox = Gtk::Box.new(:vertical, 5)
    vbox.margin_start = 10
    vbox.margin_end = 10
    vbox.margin_top = 10
    vbox.margin_bottom = 10
    set_child(vbox)

    header_box = Gtk::Box.new(:horizontal, 10)
    vbox.append(header_box)

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

    provider = Gtk::CssProvider.new
    provider.load(data: 'button.logout-btn:hover { background-color: rgba(128, 128, 128, 0.4); }')
    logout_btn.style_context.add_provider(provider, Gtk::StyleProvider::PRIORITY_APPLICATION)

    header_box.append(logout_btn)

    logout_btn.signal_connect('clicked') do
      @ssh_client&.disconnect
      @on_logout&.call
      destroy
    end

    scroll = Gtk::ScrolledWindow.new
    scroll.set_policy(:automatic, :automatic)
    scroll.vexpand = true
    vbox.append(scroll)

    @list_box = Gtk::ListBox.new
    scroll.set_child(@list_box)
  end

  def load_containers
    containers = @ssh_client.list_containers
    if containers.empty?
      label = Gtk::Label.new('No containers found.')
      @list_box.append(label)
    else
      containers.each do |container_name|
        next if container_name.strip.empty?

        label = Gtk::Label.new(container_name)
        label.halign = Gtk::Align::START
        label.margin_start = 5
        label.margin_end = 5
        label.margin_top = 5
        label.margin_bottom = 5
        @list_box.append(label)
      end
    end
  rescue StandardError => e
    show_error_dialog('Failed to load containers', e.message.sub(/^Failed to list containers: /, ''))
  end

  def show_error_dialog(title, message)
    dialog = Gtk::MessageDialog.new(
      transient_for: self,
      flags: :destroy_with_parent,
      type: :error,
      buttons: :close,
      message: title
    )
    dialog.secondary_text = message

    close_btn = dialog.get_widget_for_response(Gtk::ResponseType::CLOSE)
    close_btn&.add_css_class('destructive-action')

    dialog.signal_connect('response') { dialog.destroy }
    dialog.present
  end
end
