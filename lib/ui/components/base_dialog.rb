# frozen_string_literal: true

require 'gtk4'

module Components
  # BaseDialog provides standard layout and button spacing for all app dialogs
  class BaseDialog < Gtk::Dialog
    attr_reader :content_vbox

    def initialize(parent, title:, default_width: 350, default_height: -1)
      super()
      self.title = title
      self.transient_for = parent
      self.modal = true
      set_default_size(default_width, default_height)

      setup_base_ui
    end

    protected

    def setup_base_ui
      @content_vbox = Gtk::Box.new(:vertical, 10)
      @content_vbox.margin_start = 20
      @content_vbox.margin_end = 20
      @content_vbox.margin_top = 20
      @content_vbox.margin_bottom = 20

      content_area.append(@content_vbox)
    end

    def create_input(placeholder, is_password: false)
      entry = is_password ? Gtk::PasswordEntry.new : Gtk::Entry.new
      entry.placeholder_text = placeholder
      entry.activates_default = true
      @content_vbox.append(entry)
      entry
    end

    def setup_action_buttons(accept_label, &on_accept)
      button_box = Gtk::Box.new(:horizontal, 10)
      button_box.halign = Gtk::Align::END
      button_box.margin_top = 10
      @content_vbox.append(button_box)

      cancel_btn = Gtk::Button.new(label: 'Cancelar')
      accept_btn = Gtk::Button.new(label: accept_label)
      accept_btn.add_css_class('suggested-action')

      button_box.append(cancel_btn)
      button_box.append(accept_btn)

      set_default_widget(accept_btn)

      cancel_btn.signal_connect('clicked') do
        destroy
      end

      accept_btn.signal_connect('clicked') do
        on_accept.call
        destroy
      end
    end
  end
end
