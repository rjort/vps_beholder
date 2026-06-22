# frozen_string_literal: true

require 'gtk4'

module Components
  # BaseDialog provides standard layout and button spacing for all app dialogs
  class BaseDialog < Gtk::Dialog
    attr_reader :content_vbox

    def initialize(parent, title:, default_width: 350, default_height: 220)
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
      cancel_btn = add_button('Cancelar', Gtk::ResponseType::CANCEL)
      accept_btn = add_button(accept_label, Gtk::ResponseType::ACCEPT)
      accept_btn.add_css_class('suggested-action')
      
      # Standard spacing
      accept_btn.margin_start = 10
      accept_btn.margin_end = 20
      cancel_btn.margin_bottom = 15
      accept_btn.margin_bottom = 15
      set_default_response(Gtk::ResponseType::ACCEPT)

      signal_connect('response') do |_, response_id|
        on_accept.call if response_id == Gtk::ResponseType::ACCEPT
        destroy
      end
    end
  end
end
