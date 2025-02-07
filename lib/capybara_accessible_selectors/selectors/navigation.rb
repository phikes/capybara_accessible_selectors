# frozen_string_literal: true

Capybara.add_selector :navigation, locator_type: [String, Symbol] do
  xpath do |*|
    XPath.descendant[[
      XPath.local_name == "nav",
      XPath.attr(:role) == "navigation"
    ].reduce(:|)]
  end

  locator_filter skip_if: nil do |node, locator, exact:, **|
    method = exact ? :eql? : :include?
    if node[:"aria-labelledby"]
      CapybaraAccessibleSelectors::Helpers.element_labelledby(node).public_send(method, locator)
    elsif node[:"aria-label"]
      node[:"aria-label"].public_send(method, locator.to_s)
    end
  end

  filter_set(:capybara_accessible_selectors, %i[described_by])
end

module CapybaraAccessibleSelectors
  module Session
    # Limit supplied block to within a navigation
    #
    # @param [String] Name Navigation label
    # @param [Hash] options Finder options
    def within_navigation(*arguments, **options, &block)
      within(:navigation, *arguments, **options, &block)
    end
  end
end
