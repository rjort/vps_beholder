# frozen_string_literal: true

require 'net/ssh'

# SSHClient handles all remote execution of Docker commands over SSH.
# It maintains a persistent connection and parses Docker outputs.
class SSHClient
  attr_reader :host, :username

  # Initializes the SSH Client with credentials.
  #
  # @param host [String] The remote server IP or hostname
  # @param username [String] The SSH user
  # @param password [String] The SSH password
  def initialize(host, username, password)
    @host = host
    @username = username
    @password = password
    @ssh = nil
  end

  # Connects to the remote server using Net::SSH.
  # Enables KeepAlive to prevent idle timeouts.
  #
  # @return [Boolean] true if connection is successful
  # @raise [StandardError] if the connection fails
  def connect
    @ssh = Net::SSH.start(
      @host,
      @username,
      password: @password,
      non_interactive: true,
      keepalive: true,
      keepalive_interval: 60
    )
    true
  rescue StandardError => e
    raise "Connection failed: #{e.message}"
  end

  def list_containers
    return [] unless @ssh

    output = @ssh.exec!("docker ps -a --format '{{.Names}}|{{.State}}'")
    return [] unless output

    output.split("\n").map(&:strip).reject(&:empty?).map do |line|
      name, state = line.split('|', 2)
      { name: name.to_s.strip, state: state.to_s.strip }
    end
  rescue StandardError => e
    raise "Failed to list containers: #{e.message}"
  end

  def fetch_logs(container_name)
    return '' unless @ssh

    output = @ssh.exec!("docker logs #{container_name}")
    output || ''
  rescue StandardError => e
    raise "Failed to fetch logs: #{e.message}"
  end

  def fetch_logs_by_date(container_name, date_str)
    return '' unless @ssh

    since_t = "#{date_str}T00:00:00Z"
    until_t = "#{date_str}T23:59:59Z"

    output = @ssh.exec!("docker logs --since \"#{since_t}\" --until \"#{until_t}\" #{container_name}")
    output || ''
  rescue StandardError => e
    raise "Failed to fetch logs: #{e.message}"
  end

  # Starts a stopped Docker container.
  #
  # @param container_name [String] The name of the container
  # @return [String] the command output
  def start_container(container_name)
    return '' unless @ssh

    output = @ssh.exec!("docker start #{container_name}")
    output || ''
  rescue StandardError => e
    raise "Failed to start container: #{e.message}"
  end

  # Stops a running Docker container.
  #
  # @param container_name [String] The name of the container
  # @return [String] the command output
  def stop_container(container_name)
    return '' unless @ssh

    output = @ssh.exec!("docker stop #{container_name}")
    output || ''
  rescue StandardError => e
    raise "Failed to stop container: #{e.message}"
  end

  # Restarts a Docker container.
  #
  # @param container_name [String] The name of the container
  # @return [String] the command output
  def restart_container(container_name)
    return '' unless @ssh

    output = @ssh.exec!("docker restart #{container_name}")
    output || ''
  rescue StandardError => e
    raise "Failed to restart container: #{e.message}"
  end

  def disconnect
    @ssh.close if @ssh && !@ssh.closed?
  end
end
