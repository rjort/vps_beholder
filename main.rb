require 'gtk3'
require_relative 'lib/ssh_client'
require_relative 'lib/ui/connection_dialog'
require_relative 'lib/ui/main_window'

Gtk.init

dialog = ConnectionDialog.new
response = dialog.run

if response == Gtk::ResponseType::OK
  host = dialog.host
  username = dialog.username
  password = dialog.password
  
  dialog.destroy

  ssh_client = SSHClient.new(host, username, password)
  begin
    ssh_client.connect
    
    window = MainWindow.new(ssh_client)
    window.show_all
    Gtk.main
  rescue StandardError => e
    error_dialog = Gtk::MessageDialog.new(
      parent: nil,
      flags: :destroy_with_parent,
      type: :error,
      buttons: :close,
      message: "Connection failed:\n#{e.message}"
    )
    error_dialog.run
    error_dialog.destroy
  end
else
  dialog.destroy
end
