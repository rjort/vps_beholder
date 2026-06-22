# frozen_string_literal: true

require 'json'
require 'fileutils'
require 'securerandom'
require_relative 'secret_manager'

module Storage
  # Manages the local JSON database for host profiles.
  class ProfileManager
    # Returns the path to the profiles file.
    # @return [String] The absolute path to the JSON file.
    def self.file_path
      dir = File.expand_path('~/.vps_beholder')
      FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
      File.join(dir, 'profiles.json')
    end

    # Loads all saved profiles from disk.
    # @return [Array<Hash>] An array of profile hashes.
    def self.load_profiles
      path = file_path
      return [] unless File.exist?(path)

      content = File.read(path)
      return [] if content.strip.empty?

      JSON.parse(content, symbolize_names: true)
    rescue JSON::ParserError
      []
    end

    # Saves a full array of profiles to disk.
    # @param profiles [Array<Hash>] The profiles to save.
    def self.save_profiles(profiles)
      File.write(file_path, JSON.pretty_generate(profiles))
    end

    # Adds a new profile to the database.
    # @param name_alias [String] The friendly name of the host.
    # @param host [String] The IP or URL.
    # @param username [String] The SSH username.
    # @return [Hash] The newly created profile.
    def self.add_profile(name_alias, host, username)
      profiles = load_profiles
      new_profile = {
        id: SecureRandom.uuid,
        alias: name_alias,
        host: host,
        username: username,
        password_saved: false,
        password: nil
      }
      profiles << new_profile
      save_profiles(profiles)
      new_profile
    end

    # Updates an existing profile.
    # @param id [String] The UUID of the profile.
    # @param attributes [Hash] The attributes to update.
    # @return [Hash, nil] The updated profile, or nil if not found.
    def self.update_profile(id, attributes)
      profiles = load_profiles
      index = profiles.find_index { |p| p[:id] == id }
      return nil unless index

      profiles[index].merge!(attributes)
      save_profiles(profiles)
      profiles[index]
    end

    # Deletes a profile by its ID and removes its saved password if any.
    # @param id [String] The UUID of the profile.
    def self.delete_profile(id)
      profiles = load_profiles
      profile = profiles.find { |p| p[:id] == id }
      if profile
        Storage::SecretManager.delete(profile[:host], profile[:username]) if profile[:password_saved]
        profiles.reject! { |p| p[:id] == id }
        save_profiles(profiles)
      end
    end
  end
end
