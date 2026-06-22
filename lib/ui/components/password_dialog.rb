# frozen_string_literal: true

require 'gtk4'

module Components
  # PasswordDialog requests only the password for a known host.
  class PasswordDialog < Gtk::Dialog
    # Yields [password, save_password_boolean]
    attr_accessor :on_connect

    # Initializes the dialog
    # @param parent [Gtk::Window] The parent window
    # @param profile [Hash] The profile being connected
    def initialize(parent, profile)
      super()
      self.title = "Conectar: #{profile[:alias]}"
      self.transient_for = parent
      self.modal = true
      set_default_size(350, 220)
      @profile = profile

      setup_ui
      setup_buttons
    end

    private

    def setup_ui
      vbox = Gtk::Box.new(:vertical, 10)
      vbox.margin_start = 20
      vbox.margin_end = 20
      vbox.margin_top = 20
      vbox.margin_bottom = 20
      content_area.append(vbox)

      info_label = Gtk::Label.new("Host: #{@profile[:host]}\nUser: #{@profile[:username]}")
      info_label.halign = Gtk::Align::START
      vbox.append(info_label)

      @password_entry = Gtk::PasswordEntry.new
      @password_entry.placeholder_text = 'Senha SSH'
      @password_entry.activates_default = true
      vbox.append(@password_entry)

      @save_pw_check = Gtk::CheckButton.new
      @save_pw_check.label = 'Salvar Senha'
      vbox.append(@save_pw_check)
    end

    def setup_buttons
      cancel_btn = add_button('Cancelar', Gtk::ResponseType::CANCEL)
      connect_btn = add_button('Conectar', Gtk::ResponseType::ACCEPT)
      connect_btn.add_css_class('suggested-action')
      
      # Add spacing between buttons and set default response
      connect_btn.margin_start = 10
      cancel_btn.margin_bottom = 10
      connect_btn.margin_bottom = 10
      set_default_response(Gtk::ResponseType::ACCEPT)

      signal_connect('response') do |_, response_id|
        if response_id == Gtk::ResponseType::ACCEPT
          pass = @password_entry.text
          save_pw = @save_pw_check.active?
          @on_connect&.call(pass, save_pw)
        end
        destroy
      end
    end
  end
end
