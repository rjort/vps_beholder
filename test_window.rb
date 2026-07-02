require 'gtk4'
require_relative 'lib/ui/components/log_preview_window'
app = Gtk::Application.new('test.app', :flags_none)
app.signal_connect('activate') do
  begin
    win = Components::LogPreviewWindow.new(title: 'test', content: 'test')
    puts "Success!"
    app.quit
  rescue => e
    puts "Error: #{e.class} - #{e.message}"
    puts e.backtrace.join("\n")
    app.quit
  end
end
app.run
