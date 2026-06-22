# frozen_string_literal: true

require 'gtk4'
require_relative 'lib/ssh_client'
require_relative 'lib/ui/home_window'
require_relative 'lib/ui/main_window'

app = Gtk::Application.new('com.vps.beholder', :flags_none)

def start_home_flow(application)
  home = HomeWindow.new(application)

  home.on_start_connection = proc do |profile, password, _save_pw|
    ssh_client = SSHClient.new(profile[:host], profile[:username], password)

    dialog = Gtk::MessageDialog.new(
      transient_for: home,
      message: "Conectando ao #{profile[:alias]}...",
      buttons: :none
    )
    dialog.present

    Thread.new do
      ssh_client.connect
      GLib::Idle.add do
        dialog.destroy
        home.destroy

        window = MainWindow.new(application, ssh_client) do
          start_home_flow(application)
        end
        window.present
        false
      end
    rescue StandardError => e
      GLib::Idle.add do
        dialog.destroy
        error_dialog = Gtk::MessageDialog.new(
          transient_for: home,
          type: :error,
          buttons: :close,
          message: 'Connection failed'
        )
        error_dialog.secondary_text = e.message.sub(/^Connection failed: /, '')
        error_dialog.signal_connect('response') { error_dialog.destroy }
        error_dialog.present
        false
      end
    end
  end

  home.on_offline_logs = proc do |profile|
    info = Gtk::MessageDialog.new(
      transient_for: home,
      type: :info,
      buttons: :ok,
      message: 'Modo Offline',
      secondary_text: "Modo offline para #{profile[:alias]} será implementado na Epic 3."
    )
    info.signal_connect('response') { info.destroy }
    info.present
  end

  home.present
end

app.signal_connect 'activate' do |application|
  start_home_flow(application)
end

app.run
