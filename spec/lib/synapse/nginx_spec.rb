require 'spec_helper'
require 'synapse/config_generator/nginx'

class MockWatcher; end;

describe Synapse::ConfigGenerator::Nginx do
  subject { Synapse::ConfigGenerator::Nginx.new(config['nginx']) }

  let(:mockwatcher) do
    mockWatcher = double(Synapse::ServiceWatcher)
    allow(mockWatcher).to receive(:name).and_return('example_service')
    backends = [{ 'host' => 'somehost', 'port' => 5555}]
    allow(mockWatcher).to receive(:backends).and_return(backends)
    watcher_config = subject.normalize_watcher_provided_config('example_service', {'port' => 2199})
    allow(mockWatcher).to receive(:config_for_generator).and_return({
      'nginx' => watcher_config
    })
    mockWatcher
  end

  let(:mockwatcher_disabled) do
    mockWatcher = double(Synapse::ServiceWatcher)
    allow(mockWatcher).to receive(:name).and_return('disabled_watcher')
    backends = [{ 'host' => 'somehost', 'port' => 5555}]
    allow(mockWatcher).to receive(:backends).and_return(backends)
    watcher_config = subject.normalize_watcher_provided_config('disabled_watcher', {'port' => 2199, 'disabled' => true})
    allow(mockWatcher).to receive(:config_for_generator).and_return({
      'nginx' => watcher_config
    })
    mockWatcher
  end

  describe 'validates arguments' do
    it 'succeeds on minimal config' do
      conf = {
        'contexts' => {'main' => [], 'events' => []},
        'check_command' => 'noop',
        'reload_command' => 'noop',
        'start_command' => 'noop',
        'config_file_path' => 'somewhre'
      }
      Synapse::ConfigGenerator::Nginx.new(conf)
      expect{Synapse::ConfigGenerator::Nginx.new(conf)}.not_to raise_error
    end

    it 'validates req_pairs' do
      req_pairs = {
        'do_writes' => ['config_file_path', 'check_command'],
        'do_reloads' => ['reload_command', 'start_command'],
      }
      valid_conf = {
        'contexts' => {'main' => [], 'events' => []},
        'do_writes' => false,
        'do_reloads' => false
      }

      req_pairs.each do |key, value|
        conf = valid_conf.clone
        conf[key] = true
        expect{Synapse::ConfigGenerator::Nginx.new(conf)}.
          to raise_error(ArgumentError, "the `#{value}` option(s) are required when `#{key}` is true")
      end
    end

    it 'properly defaults do_writes, do_reloads' do
      conf = {
        'contexts' => {'main' => [], 'events' => []},
        'config_file_path' => 'test_file',
        'reload_command' => 'test_reload',
        'start_command' => 'test_start',
        'check_command' => 'test_check'
      }
      expect{Synapse::ConfigGenerator::Nginx.new(conf)}.not_to raise_error
      nginx = Synapse::ConfigGenerator::Nginx.new(conf)
      expect(nginx.instance_variable_get(:@opts)['do_writes']).to eql(true)
      expect(nginx.instance_variable_get(:@opts)['do_reloads']).to eql(true)
    end

    it 'complains when main or events are not passed at all' do
      conf = {
        'contexts' => {}
      }
      expect{Synapse::ConfigGenerator::Nginx.new(conf)}.to raise_error(ArgumentError)
    end
  end

  describe '#name' do
    it 'returns nginx' do
      expect(subject.name).to eq('nginx')
    end
  end

  describe 'disabled watcher' do
    let(:watchers) { [mockwatcher, mockwatcher_disabled] }

    it 'does not generate config' do
      expect(subject).to receive(:generate_server).exactly(:once).with(mockwatcher).and_return([])
      expect(subject).to receive(:generate_upstream).exactly(:once).with(mockwatcher).and_return([])
      subject.update_config(watchers)
    end
  end
end
