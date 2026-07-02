# frozen_string_literal: true

require 'spec_helper'
require 'gtk4'
require_relative '../../lib/ui/components/offline_container_details'
require_relative '../../lib/data/log_manager'

RSpec.describe Components::OfflineContainerDetails do
  let(:parent_window) { Gtk::Window.new }
  let(:profile) { { id: 'test-uuid' } }
  let(:details) { described_class.new(parent_window, profile) }

  describe '#show_read_window' do
    it 'instantiates LogPreviewWindow without mode parameter and tracks it' do
      allow(Storage::LogManager).to receive(:read_log).and_return('offline content')

      expect(Components::LogPreviewWindow).to receive(:new).with(
        title: 'Lendo: 2026-07-02.log',
        content: 'offline content'
      ).and_call_original

      expect_any_instance_of(Components::LogPreviewWindow).to receive(:present)

      details.send(:show_read_window, '2026-07-02.log')
    end

    it 'calls on_error if offline log content is not found' do
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
