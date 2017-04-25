require 'spec_helper'
require 'synapse/config_generator/nginx'
require 'synapse/service_watcher'

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
    allow(mockWatcher).to receive(:revision).and_return(1)
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
    allow(mockWatcher).to receive(:revision).and_return(1)
    mockWatcher
  end

  describe 'validates arguments' do
    it 'succeeds on minimal config' do
      expect{Synapse::ConfigGenerator::Nginx.new(config['nginx'])}.not_to raise_error
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

  describe '#update_config' do
    let(:watchers) { [mockwatcher] }

    shared_context 'generate_config is stubbed out' do
      let(:new_config) { 'this is a new config!' }
      before { allow(subject).to receive(:generate_config).and_return(new_config) }
    end

    it 'always updates the config' do
      expect(subject).to receive(:generate_config).with(watchers)
      subject.update_config(watchers)
    end

    context 'if we support config writes' do
      include_context 'generate_config is stubbed out'
      before { config['nginx']['do_writes'] = true }

      it 'writes the new config' do
        expect(subject).to receive(:write_config).with(new_config)
        subject.update_config(watchers)
      end
    end

    context 'when we support config writes and reloads' do
      include_context 'generate_config is stubbed out'

      before do
        config['nginx']['do_writes'] = true
        config['nginx']['do_reloads'] = true
        allow(subject).to receive(:write_config).and_return(true)
        allow(subject).to receive(:`).and_return('it worked')
      end

      it 'always does a restarts and only starts once' do
        expect(subject).to receive(:write_config).with(new_config).twice
        expect(subject).to receive(:restart).twice.and_call_original
        expect(subject).to receive(:start).once.and_call_original
        subject.update_config(watchers)
        subject.update_config(watchers)
      end
    end
  end

  describe '#tick' do
    let(:watchers) { [mockwatcher] }

    context 'when we support reloads' do
      before do
        config['nginx']['do_reloads'] = true
        config['nginx']['start_command'] = 'foo'
        config['nginx']['reload_command'] = 'bar'
        allow(subject).to receive(:start)
        allow(subject).to receive(:restart)
        allow(subject).to receive(:`).and_return('it worked')
      end

      it 'does start once' do
        expect(subject).to receive(:start).once.and_call_original
        expect(subject).not_to receive(:restart)
        subject.tick(watchers)
        subject.tick(watchers)
      end
    end
  end
end
