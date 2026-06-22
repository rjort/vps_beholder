# frozen_string_literal: true

require 'open3'

module Storage
  # Manager to handle secure storage and retrieval of passwords using libsecret (via secret-tool)
  class SecretManager
    # Saves a password to the user's secure keyring.
    # @param host [String] The target host
    # @param user [String] The SSH username
    # @param password [String] The password to store
    # @return [Boolean] True if saved successfully, false otherwise
    def self.save(host, user, password)
      cmd = ['secret-tool', 'store', '--label', "VPS Beholder: #{user}@#{host}", 'app', 'vps_beholder', 'host', host, 'user', user]
      _stdout, _stderr, status = Open3.capture3(*cmd, stdin_data: password)
      status.success?
    rescue StandardError => e
      warn "Failed to save secret: #{e.message}"
      false
    end

    # Retrieves a password from the user's secure keyring.
    # @param host [String] The target host
    # @param user [String] The SSH username
    # @return [String, nil] The password if found, nil otherwise
    def self.get(host, user)
      cmd = ['secret-tool', 'lookup', 'app', 'vps_beholder', 'host', host, 'user', user]
      stdout, _stderr, status = Open3.capture3(*cmd)
      status.success? && !stdout.empty? ? stdout : nil
    rescue StandardError => e
      warn "Failed to retrieve secret: #{e.message}"
      nil
    end

    # Removes a password from the user's secure keyring.
    # @param host [String] The target host
    # @param user [String] The SSH username
    # @return [Boolean] True if removed successfully, false on error
    def self.delete(host, user)
      cmd = ['secret-tool', 'clear', 'app', 'vps_beholder', 'host', host, 'user', user]
      _stdout, _stderr, status = Open3.capture3(*cmd)
      status.success?
    rescue StandardError => e
      warn "Failed to delete secret: #{e.message}"
      false
    end
  end
end
