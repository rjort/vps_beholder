# frozen_string_literal: true

require 'spec_helper'
require_relative '../lib/ssh_client'

RSpec.describe SSHClient do
  let(:host) { '192.168.1.100' }
  let(:username) { 'root' }
  let(:password) { 'secret' }
  let(:client) { described_class.new(host, username, password) }

  describe '#initialize' do
    it 'sets host and username correctly' do
      expect(client.host).to eq(host)
      expect(client.username).to eq(username)
    end
  end

  describe '#connect' do
    context 'when connection succeeds' do
      it 'starts an SSH connection and returns true' do
        expect(Net::SSH).to receive(:start).with(
          host, username,
          password: password,
          non_interactive: true,
          keepalive: true,
          keepalive_interval: 60
        ).and_return(double('ssh_session'))
        expect(client.connect).to be(true)
      end
    end

    context 'when connection fails' do
      it 'raises an error' do
        expect(Net::SSH).to receive(:start).and_raise(StandardError.new('Auth failed'))
        expect { client.connect }.to raise_error(RuntimeError, /Connection failed: Auth failed/)
      end
    end
  end

  describe '#list_containers' do
    let(:ssh_session) { double('ssh_session') }

    before do
      allow(Net::SSH).to receive(:start).and_return(ssh_session)
      client.connect
    end

    it 'executes docker ps -a and returns an array of hashes with name and state' do
      expect(ssh_session).to receive(:exec!).with("docker ps -a --format '{{.Names}}|{{.State}}'").and_return("container1|running\ncontainer2|exited\n")
      expect(client.list_containers).to eq([{ name: 'container1', state: 'running' },
                                            { name: 'container2', state: 'exited' }])
    end

    it 'returns an empty array if output is nil' do
      expect(ssh_session).to receive(:exec!).and_return(nil)
      expect(client.list_containers).to eq([])
    end

    it 'raises an error if the execution fails' do
      expect(ssh_session).to receive(:exec!).and_raise(StandardError.new('Docker not found'))
      expect { client.list_containers }.to raise_error(RuntimeError, /Failed to list containers: Docker not found/)
    end
  end

  describe '#fetch_logs_by_date' do
    let(:ssh_session) { double('ssh_session') }

    it 'returns logs for a specific date' do
      allow(Net::SSH).to receive(:start).and_return(ssh_session)
      expect(ssh_session).to receive(:exec!).with('docker logs --since "2026-06-18T00:00:00Z" --until "2026-06-18T23:59:59Z" container1').and_return('logs from the 18th')
      client.connect
      expect(client.fetch_logs_by_date('container1', '2026-06-18')).to eq('logs from the 18th')
    end
  end
end
