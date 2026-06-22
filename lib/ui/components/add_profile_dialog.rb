# frozen_string_literal: true

require_relative 'base_dialog'

module Components
  # Dialog to add a new host profile
  class AddProfileDialog < BaseDialog
    # Yields [name_alias, host, username]
    attr_accessor :on_save

    # Initialize the dialog
    # @param parent [Gtk::Window] The parent window
    # @param profile [Hash, nil] Optional profile to edit
    def initialize(parent, profile = nil)
      @is_edit = !profile.nil?
      title = @is_edit ? 'Editar Host' : 'Adicionar Host'
      super(parent, title: title, default_width: 350)
      setup_ui(profile)
    end

    private

    def setup_ui(profile)
      @alias_entry = create_input('Apelido (ex: Meu Servidor)')
      @host_entry = create_input('Host / IP')
      @user_entry = create_input('Usuário SSH (ex: root)')

      if profile
        @alias_entry.text = profile[:alias] || ''
        @host_entry.text = profile[:host] || ''
        @user_entry.text = profile[:username] || 'root'
      else
        @user_entry.text = 'root'
      end

      setup_action_buttons('Salvar') do
        name_alias = @alias_entry.text.strip
        host = @host_entry.text.strip
        user = @user_entry.text.strip

        @on_save&.call(name_alias, host, user) unless name_alias.empty? || host.empty? || user.empty?
      end
    end
  end
end
