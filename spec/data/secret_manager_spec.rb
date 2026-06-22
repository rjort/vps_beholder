# frozen_string_literal: true

require 'rspec'
require_relative '../../lib/data/secret_manager'
require 'open3'

RSpec.describe Storage::SecretManager do
  let(:host) { '192.168.1.10' }
  let(:user) { 'root' }
  let(:password) { 'secret_password' }
  let(:success_status) { instance_double(Process::Status, success?: true) }
  let(:fail_status) { instance_double(Process::Status, success?: false) }

  describe '.save' do
    it 'saves the password via secret-tool' do
      expect(Open3).to receive(:capture3)
        .with('secret-tool', 'store', '--label', "VPS Beholder: #{user}@#{host}", 'app', 'vps_beholder', 'host', host, 'user', user, stdin_data: password)
        .and_return(['', '', success_status])
      
      expect(described_class.save(host, user, password)).to be true
    end

    it 'returns false if secret-tool fails' do
      expect(Open3).to receive(:capture3).and_return(['', '', fail_status])
      expect(described_class.save(host, user, password)).to be false
    end
  end

  describe '.get' do
    it 'returns the password if found' do
      expect(Open3).to receive(:capture3)
        .with('secret-tool', 'lookup', 'app', 'vps_beholder', 'host', host, 'user', user)
        .and_return([password, '', success_status])
      
      expect(described_class.get(host, user)).to eq(password)
    end

    it 'returns nil if password is not found or empty' do
      expect(Open3).to receive(:capture3).and_return(['', '', success_status])
      expect(described_class.get(host, user)).to be_nil
    end

    it 'returns nil if command fails' do
      expect(Open3).to receive(:capture3).and_return(['', '', fail_status])
      expect(described_class.get(host, user)).to be_nil
    end
  end

  describe '.delete' do
    it 'clears the password via secret-tool' do
      expect(Open3).to receive(:capture3)
        .with('secret-tool', 'clear', 'app', 'vps_beholder', 'host', host, 'user', user)
        .and_return(['', '', success_status])
      
      expect(described_class.delete(host, user)).to be true
    end
  end
end
