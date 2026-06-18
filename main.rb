require 'gtk4'
require_relative 'lib/ssh_client'
require_relative 'lib/ui/connection_dialog'
require_relative 'lib/ui/main_window'

app = Gtk::Application.new("com.vps.beholder", :flags_none)

app.signal_connect "activate" do |application|
  dialog = ConnectionDialog.new
  
  dialog.signal_connect("response") do |_, response_id|
    if response_id == Gtk::ResponseType::OK
      host = dialog.host
      username = dialog.username
      password = dialog.password
      
      dialog.destroy

      ssh_client = SSHClient.new(host, username, password)
      begin
        ssh_client.connect
        
        window = MainWindow.new(application, ssh_client)
        window.present
      rescue StandardError => e
        error_dialog = Gtk::MessageDialog.new(
          transient_for: nil,
          flags: :destroy_with_parent,
          type: :error,
          buttons: :close,
          message: "Connection failed:\n#{e.message}"
        )
        error_dialog.signal_connect("response") do
          error_dialog.destroy
          application.quit
        end
        error_dialog.present
      end
    else
      dialog.destroy
      application.quit
    end
  end
  
  dialog.present
end

app.run
