# frozen_string_literal: true

require_relative 'base_dialog'

module Components
  # Dialog to add a new host profile
  class AddProfileDialog < BaseDialog
    # Yields [name_alias, host, username]
    attr_accessor :on_save

    # Initialize the dialog
    # @param parent [Gtk::Window] The parent window
    def initialize(parent)
      super(parent, title: 'Adicionar Host', default_width: 350, default_height: 300)
      setup_ui
    end

    private

    def setup_ui
      @alias_entry = create_input('Apelido (ex: Meu Servidor)')
      @host_entry = create_input('Host / IP')
      @user_entry = create_input('Usuário SSH (ex: root)')
      @user_entry.text = 'root'

      setup_action_buttons('Salvar') do
        name_alias = @alias_entry.text.strip
        host = @host_entry.text.strip
        user = @user_entry.text.strip

        @on_save&.call(name_alias, host, user) unless name_alias.empty? || host.empty? || user.empty?
      end
    end
  end
end
