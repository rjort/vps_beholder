# frozen_string_literal: true

require 'gtk4'

module Components
  # LogPreviewWindow is responsible for showing a preview of logs
  # fetched from the server or opening an existing local log file.
  class LogPreviewWindow < Gtk::Window
    # Event emitted when the window wants to save the current logs
    # Yields: [container, date, content]
    attr_accessor :on_export

    # Initializes the preview window
    #
    # @param title [String] Window title
    # @param content [String] Log content
    # @param mode [Symbol] :preview or :read (hides export button if :read)
    # @param container [String] (optional) Container name
    # @param date [String] (optional) Date string
    def initialize(title:, content:, mode: :preview, container: nil, date: nil)
      super()
      set_title(title)
      set_default_size(1000, 600)

      @container = container
      @date = date
      @content = content

      setup_ui(mode)
    end

    private

    def setup_ui(mode)
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

      return unless mode == :preview

      export_box = Gtk::Box.new(:horizontal, 10)
      export_box.halign = Gtk::Align::END
      export_box.margin_end = 10
      export_box.margin_bottom = 10
      export_box.margin_top = 5
      vbox.append(export_box)

      @export_btn = Gtk::Button.new(label: 'Exportar / Salvar Logs')
      @export_btn.sensitive = !@content.empty?
      @export_btn.signal_connect('clicked') do
        @on_export&.call(@container, @date, @content)
        @export_btn.sensitive = false
        @export_btn.label = 'Salvo!'
      end
      export_box.append(@export_btn)
    end
  end
end
