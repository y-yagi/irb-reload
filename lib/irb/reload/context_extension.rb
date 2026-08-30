# frozen_string_literal: true

require "irb/context"

module IRB
  module Reload
    module ContextExtension
      def evaluate(...)
        IRB::Reload.auto_reload!
        super
      end
    end
  end
end
