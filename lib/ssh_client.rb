require 'net/ssh'

class SSHClient
  attr_reader :host, :username

  def initialize(host, username, password)
    @host = host
    @username = username
    @password = password
    @ssh = nil
  end

  def connect
    @ssh = Net::SSH.start(@host, @username, password: @password, non_interactive: true)
    true
  rescue StandardError => e
    raise "Connection failed: #{e.message}"
  end

  def list_containers
    return [] unless @ssh

    output = @ssh.exec!("docker ps --format '{{.Names}}'")
    output ? output.split("\n") : []
  rescue StandardError => e
    raise "Failed to list containers: #{e.message}"
  end

  def disconnect
    @ssh.close if @ssh && !@ssh.closed?
  end
end
