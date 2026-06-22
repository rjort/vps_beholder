# frozen_string_literal: true

require 'gtk4'

module Components
  # Dialog to add a new host profile
  class AddProfileDialog < Gtk::Dialog
    # Yields [name_alias, host, username]
    attr_accessor :on_save

    # Initialize the dialog
    # @param parent [Gtk::Window] The parent window
    def initialize(parent)
      super()
      self.title = 'Adicionar Host'
      self.transient_for = parent
      self.modal = true
      set_default_size(350, 300)

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

      # GTK4 uses content_area
      content_area.append(vbox)

      @alias_entry = create_input(vbox, 'Apelido (ex: Meu Servidor)')
      @host_entry = create_input(vbox, 'Host / IP')
      @user_entry = create_input(vbox, 'Usuário SSH (ex: root)')
      @user_entry.text = 'root'
    end

    def create_input(parent_box, placeholder)
      entry = Gtk::Entry.new
      entry.placeholder_text = placeholder
      entry.activates_default = true
      parent_box.append(entry)
      entry
    end

    def setup_buttons
      cancel_btn = add_button('Cancelar', Gtk::ResponseType::CANCEL)
      save_btn = add_button('Salvar', Gtk::ResponseType::ACCEPT)
      save_btn.add_css_class('suggested-action')
      
      # Add spacing between buttons and set default response
      save_btn.margin_start = 10
      cancel_btn.margin_bottom = 10
      save_btn.margin_bottom = 10
      set_default_response(Gtk::ResponseType::ACCEPT)

      signal_connect('response') do |_, response_id|
        if response_id == Gtk::ResponseType::ACCEPT
          name_alias = @alias_entry.text.strip
          host = @host_entry.text.strip
          user = @user_entry.text.strip

          @on_save&.call(name_alias, host, user) unless name_alias.empty? || host.empty? || user.empty?
        end
        destroy
      end
    end
  end
end
