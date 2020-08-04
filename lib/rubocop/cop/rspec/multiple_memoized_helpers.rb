# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks if example groups contain too many `let` and `subject` calls.
      #
      # This cop is configurable using the `Max` option and the `AllowSubject`
      # which will configure the cop to only register offenses on calls to
      # `let` and not calls to `subject`.
      #
      # @example
      #   # bad
      #   describe MyClass do
      #     let(:foo) { [] }
      #     let(:bar) { [] }
      #     let!(:baz) { [] }
      #     let(:qux) { [] }
      #     let(:quux) { [] }
      #     subject(:quuz) { {} }
      #   end
      #
      #   describe MyClass do
      #     let(:foo) { [] }
      #     let(:bar) { [] }
      #     let!(:baz) { [] }
      #
      #     context 'when stuff' do
      #       let(:qux) { [] }
      #       let(:quux) { [] }
      #       subject(:quuz) { {} }
      #     end
      #   end
      #
      #   # good
      #   describe MyClass do
      #     let(:bar) { [] }
      #     let!(:baz) { [] }
      #     let(:qux) { [] }
      #     let(:quux) { [] }
      #     subject(:quuz) { {} }
      #   end
      #
      #   describe MyClass do
      #     context 'when stuff' do
      #       let(:foo) { [] }
      #       let(:bar) { [] }
      #       let!(:booger) { [] }
      #     end
      #
      #     context 'when other stuff' do
      #       let(:qux) { [] }
      #       let(:quux) { [] }
      #       subject(:quuz) { {} }
      #     end
      #   end
      #
      # @example when disabling AllowSubject configuration
      #
      #   # rubocop.yml
      #   # RSpec/MultipleMemoizedHelpers:
      #   #   AllowSubject: true
      #
      #   # good
      #   describe MyClass do
      #     subject { {} }
      #     let(:foo) { [] }
      #     let(:bar) { [] }
      #     let!(:baz) { [] }
      #     let(:qux) { [] }
      #     let(:quux) { [] }
      #   end
      #
      # @example with Max configuration
      #
      #   # rubocop.yml
      #   # RSpec/MultipleMemoizedHelpers:
      #   #   Max: 0
      #
      #   # bad
      #   describe MyClass do
      #     let(:foo) { [] }
      #   end
      #
      #   # good
      #   describe MyClass do
      #     def foo; []; end
      #   end
      #
      class MultipleMemoizedHelpers < Base
        include ConfigurableMax
        include RuboCop::RSpec::Variable

        MSG = 'Example group has too many memoized helpers [%<count>d/%<max>d]'

        def on_block(node)
          return unless spec_group?(node)

          count = all_helpers(node).uniq.count

          return if count <= max

          self.max = count
          add_offense(node, message: format(MSG, count: count, max: max))
        end

        private

        def all_helpers(node)
          [
            *helpers(node),
            *node.each_ancestor(:block).flat_map(&method(:helpers))
          ]
        end

        def helpers(node)
          example_group = RuboCop::RSpec::ExampleGroup.new(node)
          variables =
            if allow_subject?
              example_group.lets
            else
              example_group.lets + example_group.subjects
            end
          variables.map { |variable| variable_definition?(variable.send_node) }
        end

        def max
          cop_config['Max']
        end

        def allow_subject?
          cop_config['AllowSubject']
        end
      end
    end
  end
end
