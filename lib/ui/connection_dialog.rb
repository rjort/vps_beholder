require 'gtk3'

class ConnectionDialog < Gtk::Dialog
  attr_reader :host, :username, :password

  def initialize(parent = nil)
    super(title: "Connect to VPS", parent: parent, flags: :destroy_with_parent, buttons: [["Connect", Gtk::ResponseType::OK], ["Cancel", Gtk::ResponseType::CANCEL]])

    set_default_size(300, 200)

    vbox = self.content_area
    vbox.spacing = 10
    vbox.margin = 10

    @host_entry = Gtk::Entry.new
    @host_entry.placeholder_text = "Host (e.g. 192.168.1.100)"
    
    @user_entry = Gtk::Entry.new
    @user_entry.placeholder_text = "Username"
    
    @pass_entry = Gtk::Entry.new
    @pass_entry.placeholder_text = "Password"
    @pass_entry.visibility = false # Hide password characters

    vbox.pack_start(@host_entry, expand: false, fill: false, padding: 0)
    vbox.pack_start(@user_entry, expand: false, fill: false, padding: 0)
    vbox.pack_start(@pass_entry, expand: false, fill: false, padding: 0)

    show_all

    signal_connect("response") do |_, response_id|
      if response_id == Gtk::ResponseType::OK
        @host = @host_entry.text
        @username = @user_entry.text
        @password = @pass_entry.text
      end
    end
  end
end
