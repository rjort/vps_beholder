# frozen_string_literal: true

require_relative 'base_dialog'

module Components
  # PasswordDialog requests only the password for a known host.
  class PasswordDialog < BaseDialog
    # Yields [password, save_password_boolean]
    attr_accessor :on_connect

    # Initializes the dialog
    # @param parent [Gtk::Window] The parent window
    # @param profile [Hash] The profile being connected
    def initialize(parent, profile)
      super(parent, title: "Conectar: #{profile[:alias]}", default_width: 350, default_height: 220)
      @profile = profile
      setup_ui
    end

    private

    def setup_ui
      info_label = Gtk::Label.new("Host: #{@profile[:host]}\nUser: #{@profile[:username]}")
      info_label.halign = Gtk::Align::START
      @content_vbox.append(info_label)

      @password_entry = create_input('Senha SSH', is_password: true)

      @save_pw_check = Gtk::CheckButton.new
      @save_pw_check.label = 'Salvar Senha'
      @content_vbox.append(@save_pw_check)

      setup_action_buttons('Conectar') do
        pass = @password_entry.text
        save_pw = @save_pw_check.active?
        @on_connect&.call(pass, save_pw)
      end
    end
  end
end
