# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'
require_relative '../../lib/data/profile_manager'

RSpec.describe Storage::ProfileManager do
  let(:test_dir) { File.expand_path('~/.vps_beholder') }
  let(:test_file) { File.join(test_dir, 'profiles.json') }

  before do
    # Ensure test directory is clean
    FileUtils.rm_f(test_file) if File.exist?(test_file)
  end

  after do
    FileUtils.rm_f(test_file) if File.exist?(test_file)
  end

  describe '.load_profiles' do
    it 'returns an empty array when file does not exist' do
      expect(described_class.load_profiles).to eq([])
    end

    it 'loads profiles from a valid JSON file' do
      profiles = [{ id: '1', alias: 'Test', host: '127.0.0.1', username: 'root' }]
      described_class.save_profiles(profiles)
      expect(described_class.load_profiles.first[:alias]).to eq('Test')
    end
  end

  describe '.add_profile' do
    it 'creates a new profile with a UUID and saves it' do
      profile = described_class.add_profile('My Host', '10.0.0.1', 'admin')
      expect(profile[:id]).not_to be_nil
      expect(profile[:alias]).to eq('My Host')
      expect(profile[:host]).to eq('10.0.0.1')
      expect(profile[:username]).to eq('admin')

      loaded = described_class.load_profiles
      expect(loaded.length).to eq(1)
      expect(loaded.first[:alias]).to eq('My Host')
    end
  end

  describe '.delete_profile' do
    it 'removes a profile by id' do
      p1 = described_class.add_profile('H1', '10.0.0.1', 'admin')
      described_class.add_profile('H2', '10.0.0.2', 'root')

      expect(described_class.load_profiles.length).to eq(2)

      described_class.delete_profile(p1[:id])

      loaded = described_class.load_profiles
      expect(loaded.length).to eq(1)
      expect(loaded.first[:alias]).to eq('H2')
    end
  end

  describe '.update_profile' do
    it 'updates an existing profile by id' do
      p = described_class.add_profile('Old Name', '10.0.0.1', 'admin')
      updated = described_class.update_profile(p[:id], { alias: 'New Name', host: '10.0.0.9' })

      expect(updated[:alias]).to eq('New Name')
      expect(updated[:host]).to eq('10.0.0.9')
      expect(updated[:username]).to eq('admin')

      loaded = described_class.load_profiles.first
      expect(loaded[:alias]).to eq('New Name')
      expect(loaded[:host]).to eq('10.0.0.9')
    end

    it 'returns nil if the profile id does not exist' do
      expect(described_class.update_profile('nonexistent-uuid', { alias: 'New' })).to be_nil
    end
  end
end
