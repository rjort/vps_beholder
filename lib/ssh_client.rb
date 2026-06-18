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

  def disconnect
    @ssh.close if @ssh && !@ssh.closed?
  end
end
