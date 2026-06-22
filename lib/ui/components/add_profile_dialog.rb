# frozen_string_literal: true

require_relative 'base_dialog'

module Components
  # Dialog to add a new host profile
  class AddProfileDialog < BaseDialog
    # Yields [name_alias, host, username, password]
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

    # Sets up the dialog UI components.
    # @param profile [Hash, nil] Optional profile to prefill.
    def setup_ui(profile)
      @alias_entry = create_input('Apelido (ex: Meu Servidor)')
      @host_entry = create_input('Host / IP')
      @user_entry = create_input('Usuário SSH (ex: root)')
      @password_entry = create_input('Senha SSH', is_password: true) if @is_edit

      if profile
        @alias_entry.text = profile[:alias] || ''
        @host_entry.text = profile[:host] || ''
        @user_entry.text = profile[:username] || 'root'
        if profile[:password_saved]
          saved_pw = Storage::SecretManager.get(profile[:host], profile[:username])
          @password_entry.text = saved_pw || ''
        end
      else
        @user_entry.text = 'root'
      end

      setup_action_buttons('Salvar') do
        name_alias = @alias_entry.text.strip
        host = @host_entry.text.strip
        user = @user_entry.text.strip
        password = @is_edit ? @password_entry.text : nil

        @on_save&.call(name_alias, host, user, password) unless name_alias.empty? || host.empty? || user.empty?
      end
    end
  end
end
