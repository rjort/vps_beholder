require 'gtk4'
require_relative 'lib/ui/components/log_preview_window'
app = Gtk::Application.new('test.app', :flags_none)
app.signal_connect('activate') do
  Components::LogPreviewWindow.new(title: 'test', content: 'test')
  puts 'Success!'
  app.quit
rescue StandardError => e
  puts "Error: #{e.class} - #{e.message}"
  puts e.backtrace.join("\n")
  app.quit
end
app.run
