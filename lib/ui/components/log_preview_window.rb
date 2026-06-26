# frozen_string_literal: true

require 'gtk4'

module Components
  # LogPreviewWindow is responsible for showing a preview of logs
  # fetched from the server or opening an existing local log file.
  class LogPreviewWindow < Gtk::Window
    # Initializes the preview window
    #
    # @param title [String] Window title
    # @param content [String] Log content
    def initialize(title:, content:)
      super()
      set_title(title)
      set_default_size(1000, 600)

      @content = content

      setup_ui
    end

    private

    def setup_ui
      vbox = Gtk::Box.new(:vertical, 5)
      set_child(vbox)

      scroll = Gtk::ScrolledWindow.new
      scroll.set_policy(:automatic, :automatic)
      scroll.vexpand = true
      vbox.append(scroll)

      text_view = Gtk::TextView.new
      text_view.editable = false
      text_view.monospace = true
      text_view.buffer.text = @content.empty? ? 'No logs found.' : @content
      scroll.set_child(text_view)
    end
  end
end
