# frozen_string_literal: true

require "irb/command"

module IRB
  module Reload
    class Command < IRB::Command::Base
      category "reload"
      description "Watch directories and reload updated Ruby files."
      help_message <<~HELP
        Reload updated files.
      HELP

      def execute(_arg)
        IRB::Reload.reload!
      end
    end
  end
end
