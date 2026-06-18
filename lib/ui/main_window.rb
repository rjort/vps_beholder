require 'gtk4'

class MainWindow < Gtk::ApplicationWindow
  def initialize(app, ssh_client)
    super(app)
    @ssh_client = ssh_client
    
    set_title("VPS Beholder - #{ssh_client.host}")
    set_default_size(400, 500)

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
    self.set_child(vbox)

    label = Gtk::Label.new("Docker Containers on #{@ssh_client.host}")
    label.halign = Gtk::Align::START
    vbox.append(label)

    scroll = Gtk::ScrolledWindow.new
    scroll.set_policy(:automatic, :automatic)
    scroll.vexpand = true
    vbox.append(scroll)

    @list_box = Gtk::ListBox.new
    scroll.set_child(@list_box)
  end

  def load_containers
    begin
      containers = @ssh_client.list_containers
      if containers.empty?
        label = Gtk::Label.new("No containers found.")
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
      show_error_dialog("Failed to load containers:\n#{e.message}")
    end
  end

  def show_error_dialog(message)
    dialog = Gtk::MessageDialog.new(
      transient_for: self,
      flags: :destroy_with_parent,
      type: :error,
      buttons: :close,
      message: message
    )
    dialog.signal_connect("response") { dialog.destroy }
    dialog.present
  end
end
