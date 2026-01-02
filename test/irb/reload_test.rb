# frozen_string_literal: true

require "test_helper"
require "set"

module IRB
  class ReloadTest < Minitest::Test
    def test_start_respects_configured_paths_and_listen_options
      IRB::Reload.config[:paths] = %w[app services]
      IRB::Reload.config[:listen] = { "ignore" => %r{/tmp}, latency: 0.25 }

      listener = with_listener_stub do
        IRB::Reload.start
      end

      assert_equal %w[app services], listener.paths
      assert_equal %r{/tmp}, listener.options[:ignore]
      assert_equal 0.25, listener.options[:latency]
    end

    def test_record_updated_and_added_ruby_files_only_once
      listener = with_listener_stub do
        IRB::Reload.start
      end

      listener.simulate_change(modified: ["lib/foo.rb", "lib/foo.rb"], added: ["README.md", "lib/bar.rb"])

      assert_equal Set["lib/foo.rb", "lib/bar.rb"], IRB::Reload.instance_variable_get(:@changed_files)
    end

    private

    def with_listener_stub
      listener = nil

      Listen.stub(:to, ->(*paths, **options, &block) { listener = ListenerDouble.new(paths, options, block) }) do
        yield
      end

      listener
    end

    class ListenerDouble
      attr_reader :paths, :options

      def initialize(paths, options, block)
        @paths = paths
        @options = options
        @block = block
        @started = false
      end

      def start
        @started = true
      end

      def started?
        @started
      end

      def directories
        paths
      end

      def simulate_change(modified: [], added: [], removed: [])
        @block.call(modified, added, removed)
      end
    end
  end
end
