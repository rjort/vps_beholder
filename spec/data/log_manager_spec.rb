# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'
require 'securerandom'
require_relative '../../lib/data/log_manager'

RSpec.describe Storage::LogManager do
  let(:base_dir) { File.expand_path('~/.vps_beholder/logs') }
  let(:profile_id) { SecureRandom.uuid }
  let(:container_name) { 'nginx_test' }

  before do
    # Ensure test directory is clean
    FileUtils.rm_rf(base_dir) if Dir.exist?(base_dir)
  end

  after do
    FileUtils.rm_rf(base_dir) if Dir.exist?(base_dir)
  end

  describe '.save_log and .read_log' do
    it 'saves log content and can read it back' do
      date = '2026-06-24'
      content = 'some log data'

      described_class.save_log(profile_id, container_name, date, content)

      read_content = described_class.read_log(profile_id, container_name, "#{date}.log")
      expect(read_content).to eq(content)
    end

    it 'returns nil if reading a nonexistent log' do
      expect(described_class.read_log(profile_id, container_name, 'ghost.log')).to be_nil
    end
  end

  describe '.list_containers' do
    it 'returns an array of containers that have logs' do
      described_class.save_log(profile_id, 'app_container', '2026-01-01', 'logs')
      described_class.save_log(profile_id, 'db_container', '2026-01-01', 'logs')

      containers = described_class.list_containers(profile_id)
      expect(containers).to eq(%w[app_container db_container])
    end

    it 'returns an empty array if profile has no logs' do
      expect(described_class.list_containers(profile_id)).to eq([])
    end
  end

  describe '.list_logs' do
    it 'returns log filenames sorted by newest first' do
      described_class.save_log(profile_id, container_name, '2026-06-01', 'logs')
      described_class.save_log(profile_id, container_name, '2026-06-10', 'logs')
      described_class.save_log(profile_id, container_name, '2026-06-05', 'logs')

      logs = described_class.list_logs(profile_id, container_name)
      expect(logs).to eq(['2026-06-10.log', '2026-06-05.log', '2026-06-01.log'])
    end
  end

  describe '.delete_legacy_logs' do
    it 'deletes folders that are not formatted as UUIDs' do
      FileUtils.mkdir_p(base_dir)

      legacy_dir = File.join(base_dir, 'legacy_nginx')
      FileUtils.mkdir_p(legacy_dir)

      valid_dir = File.join(base_dir, profile_id)
      FileUtils.mkdir_p(valid_dir)

      described_class.delete_legacy_logs

      expect(Dir.exist?(legacy_dir)).to be false
      expect(Dir.exist?(valid_dir)).to be true
    end
  end
end
