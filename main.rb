require 'gtk4'
require_relative 'lib/ssh_client'
require_relative 'lib/ui/connection_dialog'
require_relative 'lib/ui/main_window'

app = Gtk::Application.new('com.vps.beholder', :flags_none)

def start_login_flow(application)
  dialog = ConnectionDialog.new(application) do |dlg|
    host = dlg.host
    username = dlg.username
    password = dlg.password

    ssh_client = SSHClient.new(host, username, password)
    begin
      ssh_client.connect

      dlg.destroy

      window = MainWindow.new(application, ssh_client) do
        start_login_flow(application)
      end
      window.present
    rescue StandardError => e
      error_dialog = Gtk::MessageDialog.new(
        transient_for: dlg,
        flags: :destroy_with_parent,
        type: :error,
        buttons: :close,
        message: 'Connection failed'
      )
      error_dialog.secondary_text = e.message.sub(/^Connection failed: /, '')

      close_btn = error_dialog.get_widget_for_response(Gtk::ResponseType::CLOSE)
      close_btn&.add_css_class('destructive-action')

      error_dialog.signal_connect('response') do
        error_dialog.destroy
      end
      error_dialog.present
    end
  end

  dialog.present
end

app.signal_connect 'activate' do |application|
  start_login_flow(application)
end

app.run
