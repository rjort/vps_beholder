# frozen_string_literal: true

require 'fileutils'

module Storage
  # Manages local storage of container logs, scoped by profile.
  class LogManager
    UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

    # Returns the base directory for all logs.
    # @return [String] Absolute path to the logs directory.
    def self.base_dir
      dir = File.expand_path('~/.vps_beholder/logs')
      FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
      dir
    end

    # Returns the log directory for a specific profile.
    # @param profile_id [String] The UUID of the profile.
    # @return [String] Absolute path to the profile's log directory.
    def self.profile_dir(profile_id)
      dir = File.join(base_dir, profile_id)
      FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
      dir
    end

    # Deletes any log directories that do not conform to the UUID pattern (legacy logs).
    def self.delete_legacy_logs
      Dir.glob(File.join(base_dir, '*')).each do |path|
        next unless File.directory?(path)

        folder_name = File.basename(path)
        FileUtils.rm_rf(path) unless folder_name.match?(UUID_REGEX)
      end
    end

    # Saves a log file for a specific container and date.
    # @param profile_id [String] The UUID of the profile.
    # @param container_name [String] The name of the container.
    # @param date [String] The date string (e.g. YYYY-MM-DD).
    # @param content [String] The log content to save.
    def self.save_log(profile_id, container_name, date, content)
      dir = File.join(profile_dir(profile_id), container_name)
      FileUtils.mkdir_p(dir) unless Dir.exist?(dir)

      file_path = File.join(dir, "#{date}.log")
      File.write(file_path, content)
    end

    # Lists all containers that have saved logs under a profile.
    # @param profile_id [String] The UUID of the profile.
    # @return [Array<String>] List of container names.
    def self.list_containers(profile_id)
      dir = profile_dir(profile_id)
      return [] unless Dir.exist?(dir)

      Dir.children(dir).select do |child|
        File.directory?(File.join(dir, child))
      end.sort
    end

    # Lists all log files available for a specific container.
    # @param profile_id [String] The UUID of the profile.
    # @param container_name [String] The name of the container.
    # @return [Array<String>] List of filenames (e.g. 'YYYY-MM-DD.log').
    def self.list_logs(profile_id, container_name)
      dir = File.join(profile_dir(profile_id), container_name)
      return [] unless Dir.exist?(dir)

      Dir.glob(File.join(dir, '*.log')).map { |f| File.basename(f) }.sort.reverse
    end

    # Reads the content of a specific log file.
    # @param profile_id [String] The UUID of the profile.
    # @param container_name [String] The name of the container.
    # @param filename [String] The filename to read (e.g. 'YYYY-MM-DD.log').
    # @return [String, nil] The log content, or nil if not found.
    def self.read_log(profile_id, container_name, filename)
      file_path = File.join(profile_dir(profile_id), container_name, filename)
      return nil unless File.exist?(file_path)

      File.read(file_path)
    end
  end
end
