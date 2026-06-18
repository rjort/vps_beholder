require 'gtk3'

class MainWindow < Gtk::Window
  def initialize(ssh_client)
    super()
    @ssh_client = ssh_client
    
    set_title("VPS Beholder - #{ssh_client.host}")
    set_default_size(400, 500)
    set_window_position(:center)

    signal_connect("destroy") { Gtk.main_quit }

    setup_ui
    load_containers
  end

  private

  def setup_ui
    vbox = Gtk::Box.new(:vertical, 5)
    vbox.margin = 10
    add(vbox)

    label = Gtk::Label.new("Docker Containers on #{@ssh_client.host}")
    label.set_alignment(0, 0.5)
    vbox.pack_start(label, expand: false, fill: false, padding: 5)

    scroll = Gtk::ScrolledWindow.new
    scroll.set_policy(:automatic, :automatic)
    vbox.pack_start(scroll, expand: true, fill: true, padding: 0)

    @list_box = Gtk::ListBox.new
    scroll.add(@list_box)
  end

  def load_containers
    begin
      containers = @ssh_client.list_containers
      if containers.empty?
        row = Gtk::ListBoxRow.new
        row.add(Gtk::Label.new("No containers found."))
        @list_box.add(row)
      else
        containers.each do |container_name|
          next if container_name.strip.empty?
          row = Gtk::ListBoxRow.new
          label = Gtk::Label.new(container_name)
          label.set_alignment(0, 0.5)
          label.margin = 5
          row.add(label)
          @list_box.add(row)
        end
      end
    rescue StandardError => e
      show_error_dialog("Failed to load containers:\n#{e.message}")
    end
  end

  def show_error_dialog(message)
    dialog = Gtk::MessageDialog.new(
      parent: self,
      flags: :destroy_with_parent,
      type: :error,
      buttons: :close,
      message: message
    )
    dialog.run
    dialog.destroy
  end
end
