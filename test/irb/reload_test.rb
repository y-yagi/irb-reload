# frozen_string_literal: true

require "test_helper"
require "set"

module IRB
  class ReloadTest < Minitest::Test
    def test_start_respects_configured_paths_and_watchcat_filters
      IRB::Reload.config[:paths] = %w[app services]

      watcher = with_watchcat_stub do
        IRB::Reload.start
      end

      assert_equal %w[app services], watcher.paths
      assert_equal({ ignore_remove: true, ignore_access: true }, watcher.options[:filters])
    end

    def test_record_updated_and_added_ruby_files_only_once
      watcher = with_watchcat_stub do
        IRB::Reload.start
      end

      watcher.simulate_event(paths: ["lib/foo.rb", "lib/foo.rb", "README.md", "lib/bar.rb"], event_type: :modify)
      watcher.simulate_event(paths: ["lib/baz.rb"], event_type: :create)

      assert_equal Set["lib/foo.rb", "lib/bar.rb", "lib/baz.rb"], IRB::Reload.instance_variable_get(:@changed_files)
    end

    private

    def with_watchcat_stub
      watcher = nil

      Watchcat.stub(:watch, ->(paths, **options, &block) { watcher = WatcherDouble.new(paths, options, block) }) do
        yield
      end

      watcher
    end

    class WatcherDouble
      attr_reader :paths, :options

      def initialize(paths, options, block)
        @paths = Array(paths)
        @options = options
        @block = block
      end

      def stop; end

      def simulate_event(paths:, event_type: :modify)
        event = EventDouble.new(paths, event_type)
        @block.call(event)
      end
    end

    class EventDouble
      attr_reader :paths, :kind

      def initialize(paths, event_type)
        @paths = Array(paths)
        @kind = KindDouble.new(event_type)
      end
    end

    class KindDouble
      def initialize(event_type)
        @event_type = event_type
      end

      def create?
        @event_type == :create
      end

      def modify?
        @event_type == :modify
      end

      def any?
        @event_type == :any
      end

      def remove?
        @event_type == :remove
      end

      def access?
        @event_type == :access
      end
    end
  end
end
