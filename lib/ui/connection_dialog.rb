require 'gtk4'

class ConnectionDialog < Gtk::Dialog
  attr_reader :host, :username, :password

  def initialize(parent = nil)
    super()
    set_title("Connect to VPS")
    set_default_size(300, 200)
    self.transient_for = parent if parent
    self.modal = true
    
    add_button("Connect", Gtk::ResponseType::OK)
    add_button("Cancel", Gtk::ResponseType::CANCEL)

    vbox = self.content_area
    vbox.spacing = 10
    vbox.margin_start = 10
    vbox.margin_end = 10
    vbox.margin_top = 10
    vbox.margin_bottom = 10

    @host_entry = Gtk::Entry.new
    @host_entry.placeholder_text = "Host (e.g. 192.168.1.100)"
    
    @user_entry = Gtk::Entry.new
    @user_entry.placeholder_text = "Username"
    
    @pass_entry = Gtk::Entry.new
    @pass_entry.placeholder_text = "Password"
    @pass_entry.visibility = false

    vbox.append(@host_entry)
    vbox.append(@user_entry)
    vbox.append(@pass_entry)

    signal_connect("response") do |_, response_id|
      if response_id == Gtk::ResponseType::OK
        @host = @host_entry.text
        @username = @user_entry.text
        @password = @pass_entry.text
      end
    end
  end
end
