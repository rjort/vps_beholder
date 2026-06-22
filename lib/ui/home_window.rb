# frozen_string_literal: true

require 'gtk4'
require_relative '../data/profile_manager'
require_relative '../data/secret_manager'
require_relative 'components/add_profile_dialog'
require_relative 'components/password_dialog'

# HomeWindow displays the list of saved hosts/profiles and is the
# new entry point of the application.
class HomeWindow < Gtk::ApplicationWindow
  # Triggered when a connection starts
  # Yields [profile, password]
  attr_accessor :on_start_connection

  # Triggered when offline logs are requested
  # Yields [profile]
  attr_accessor :on_offline_logs

  # Initializes the Home Window
  # @param app [Gtk::Application] The GTK Application instance
  def initialize(app)
    super(app)
    set_title('VPS Beholder - Perfis')
    set_default_size(600, 500)

    setup_ui
    load_profiles
  end

  private

  def setup_ui
    vbox = Gtk::Box.new(:vertical, 10)
    set_child(vbox)

    header = Gtk::Box.new(:horizontal, 10)
    header.margin_start = 10
    header.margin_end = 10
    header.margin_top = 10
    vbox.append(header)

    title_label = Gtk::Label.new
    title_label.set_markup('<span size="x-large" weight="bold">Meus Servidores</span>')
    title_label.halign = Gtk::Align::START
    title_label.hexpand = true
    header.append(title_label)

    add_btn = Gtk::Button.new(label: 'Adicionar Host')
    add_btn.add_css_class('suggested-action')
    add_btn.signal_connect('clicked') { show_add_profile_dialog }
    header.append(add_btn)

    scroll = Gtk::ScrolledWindow.new
    scroll.set_policy(:automatic, :automatic)
    scroll.vexpand = true
    scroll.margin_start = 10
    scroll.margin_end = 10
    scroll.margin_bottom = 10
    vbox.append(scroll)

    @list_box = Gtk::ListBox.new
    @list_box.selection_mode = :none
    scroll.set_child(@list_box)
  end

  def load_profiles
    children = []
    child = @list_box.first_child
    while child
      children << child
      child = child.next_sibling
    end
    children.each { |c| @list_box.remove(c) }

    profiles = Storage::ProfileManager.load_profiles
    if profiles.empty?
      @list_box.append(Gtk::Label.new('Nenhum servidor cadastrado. Clique em Adicionar Host.'))
      return
    end

    profiles.each do |profile|
      row = build_profile_row(profile)
      @list_box.append(row)
    end
  end

  def build_profile_row(profile)
    row_box = Gtk::Box.new(:horizontal, 10)
    row_box.margin_start = 10
    row_box.margin_end = 10
    row_box.margin_top = 10
    row_box.margin_bottom = 10

    icon_path = File.expand_path('../../assets/icons/terminal.svg', __dir__)
    icon = Gtk::Image.new(file: icon_path)
    row_box.append(icon)

    info_box = Gtk::Box.new(:vertical, 2)
    info_box.hexpand = true
    row_box.append(info_box)

    alias_label = Gtk::Label.new
    alias_label.set_markup("<b>#{profile[:alias]}</b>")
    alias_label.halign = Gtk::Align::START
    info_box.append(alias_label)

    host_label = Gtk::Label.new("#{profile[:username]}@#{profile[:host]}")
    host_label.halign = Gtk::Align::START
    host_label.add_css_class('dim-label')
    info_box.append(host_label)

    # Actions
    connect_btn = Gtk::Button.new(label: 'Conectar')
    connect_btn.add_css_class('suggested-action')
    connect_btn.signal_connect('clicked') { show_password_dialog(profile) }
    row_box.append(connect_btn)

    offline_btn = Gtk::Button.new(label: 'Logs Offline')
    offline_btn.signal_connect('clicked') { @on_offline_logs&.call(profile) }
    row_box.append(offline_btn)

    edit_icon = Gtk::Image.new(file: File.expand_path('../../assets/icons/edit.svg', __dir__))
    edit_btn = Gtk::Button.new
    edit_btn.set_child(edit_icon)
    edit_btn.tooltip_text = 'Editar Host'
    edit_btn.signal_connect('clicked') do
      show_add_profile_dialog(profile)
    end
    row_box.append(edit_btn)

    del_icon = Gtk::Image.new(file: File.expand_path('../../assets/icons/delete.svg', __dir__))
    del_btn = Gtk::Button.new
    del_btn.set_child(del_icon)
    del_btn.tooltip_text = 'Deletar Host'
    del_btn.add_css_class('destructive-action')
    del_btn.signal_connect('clicked') do
      Storage::ProfileManager.delete_profile(profile[:id])
      load_profiles
    end
    row_box.append(del_btn)

    row_box
  end

  def show_add_profile_dialog(profile = nil)
    dialog = Components::AddProfileDialog.new(self, profile)
    dialog.on_save = proc do |name_alias, host, username|
      if profile
        Storage::ProfileManager.update_profile(profile[:id], {
                                                 alias: name_alias,
                                                 host: host,
                                                 username: username
                                               })
      else
        Storage::ProfileManager.add_profile(name_alias, host, username)
      end
      load_profiles
    end
    dialog.present
  end

  def show_password_dialog(profile)
    if profile[:password_saved]
      saved_password = Storage::SecretManager.get(profile[:host], profile[:username])
      if saved_password
        @on_start_connection&.call(profile, saved_password, true)
        return
      end
    end

    dialog = Components::PasswordDialog.new(self, profile)
    dialog.on_connect = proc do |password, save_pw|
      if save_pw
        Storage::SecretManager.save(profile[:host], profile[:username], password)
        Storage::ProfileManager.update_profile(profile[:id], { password_saved: true })
      end
      @on_start_connection&.call(profile, password, save_pw)
    end
    dialog.present
  end
end
