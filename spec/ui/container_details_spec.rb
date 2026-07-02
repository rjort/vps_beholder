# frozen_string_literal: true

require 'spec_helper'
require 'gtk4'
require_relative '../../lib/ui/components/container_details'
require_relative '../../lib/data/log_manager'

RSpec.describe Components::ContainerDetails do
  let(:ssh_client) { double('ssh_client') }
  let(:parent_window) { Gtk::Window.new }
  let(:profile) { { id: 'test-uuid' } }
  let(:details) { described_class.new(ssh_client, parent_window, profile) }

  describe '#show_preview_window' do
    it 'instantiates LogPreviewWindow and tracks it' do
      expect(Components::LogPreviewWindow).to receive(:new).with(
        title: 'Preview: my_container - 2026-07-02',
        content: 'test log content'
      ).and_call_original

      expect_any_instance_of(Components::LogPreviewWindow).to receive(:present)

      details.send(:show_preview_window, 'my_container', '2026-07-02', 'test log content')
    end
  end

  describe '#show_read_window' do
    it 'instantiates LogPreviewWindow for local files and tracks it' do
      # Mock the log reading
      allow(Storage::LogManager).to receive(:read_log).with('test-uuid', nil, '2026-07-02.log').and_return('local content')

      expect(Components::LogPreviewWindow).to receive(:new).with(
        title: 'Lendo: 2026-07-02.log',
        content: 'local content'
      ).and_call_original

      expect_any_instance_of(Components::LogPreviewWindow).to receive(:present)

      details.send(:show_read_window, '2026-07-02.log')
    end

    it 'calls on_error if log content is not found' do
      allow(Storage::LogManager).to receive(:read_log).and_return(nil)

      error_called = false
      details.on_error = proc do |title, msg|
        error_called = true
        expect(title).to eq('Error reading log file')
        expect(msg).to eq('Log content not found')
      end

      details.send(:show_read_window, 'invalid.log')
      expect(error_called).to be true
    end
  end
end
