# Capybara accessible selectors

A set of Capybara selectors that allow you to
find common UI elements by labels and using screen-reader compatible mark-up.

[Cheat sheet](CHEAT_SHEET.md)

## Philosophy

All feature tests should interact with the browser in the same way a screen-reader user would. This both tests the feature, and ensures the application is accessible.

To be accessible to a screen-reader, a page should be built from the native html elements with the semantics and behaviour required for each feature. For example if the page contains a button it should use `<button>` element rather than adding a `onClick` handler to a `<span>`.

Where a feature does not exist in HTML, such as tabs, then ARIA roles and states can be used to convey the meaning to a screen-reader.

For a better overview see [Using aria](https://www.w3.org/TR/using-aria/).

As a result all tests should be built from the visible labels on the page, and the semantic meaning of elements, and ARIA roles and attribute.

CSS and XPATH selectors based on classes, ids and nesting elements with no semantic meaning, should not be used.

This gem contains a set of selectors and filters for common UI elements and element states that are not already included in Capybara. These selectors follow the guidelines in [ARIA Authoring Practices](https://www.w3.org/TR/wai-aria-practices-1.1/).

Examples:

```ruby
# Bad selectors
# - fragile and does not check the control is correctly labelled

page.find(:css, "#widget > div > .field").set("Bob")

fill_in "field_name_1", with: "Bob"

page.find(:css, "#tab_1").click

within(:css, "#tabs > div > div.panel:first-child") do
  expect(page).to have_text "Client name Bob"
end

# Good selectors
# - based on how a screen reader would hear and navigate a page

within_fieldset "User details" do
  fill_in "First name", with: "Bob"
end

select_tab "Client details"

expect(page).to have_tab_panel "Client details", text: "Client name Bob"

within_modal "Are you sure?" do
  click_button "OK"
end
```

## Usage

Include in your Gemfile:

```ruby
group :test do
  gem "capybara_accessible_selectors", git: "https://github.com/citizensadvice/capybara_accessible_selectors", branch: "main"
end
```

## Documentation

See the [Capybara cheatsheet](https://devhints.io/capybara) for an overview of built-in Capybara selectors and actions.

### Filters

#### `aria` [Hash]

Added to: `button`, `checkbox`, `css`, `element`, `field`, `file_field`, `fillable_field`, `link`, `link_or_button`, `radio_button`, `select`, and `xpath`

Filters for an element that declares [ARIA attributes](https://www.w3.org/TR/wai-aria/#introstates)

```html
<button aria-controls="some-state" aria-pressed="true">A pressed button</button>
```

```ruby
expect(page).to have_selector :button, "A pressed button", aria: { controls: "some-state", pressed: true }
```

#### `current` [String, Symbol]

Added to: `link`, `link_or_button`.

Is the element the current item within a container or set of related elements using [`aria-current`](https://www.w3.org/TR/wai-aria/#aria-current).

For example:

```html
<ul>
  <li>
    <a href="/">Home</a>
  </li>
  <li>
    <a href="/about-us" aria-current="page">About us</a>
  </li>
</ul>
```

```ruby
expect(page).to have_link "About us", current: "page"
```

#### `described_by` [String]

Added to all selectors.

Is the field described by some text using [`aria-describedby`](https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/ARIA_Techniques/Using_the_aria-describedby_attribute).

For example:

```html
<label>
  My field
  <input aria-describedby="id1 id2" />
</label>
<span id="id1">My</span>
<span id="id2">description</span>
```

```ruby
expect(page).to have_field "My field", described_by: "My description"
```

#### `fieldset` [String, Symbol, Array]

Added to: `button`, `link`, `link_or_button`, `field`, `fillable_field`, `radio_button`, `checkbox`, `select`, `file_field`, `combo_box` and `rich_text`.

Filter for controls within a `<fieldset>` by `<legend>` text. This can also take an array of fieldsets for multiple nested fieldsets.

For example:

```html
<fieldset>
  <legend>My question</legend>
  <label>
    <input type="radio" name="radios" />
    Answer 1
  </label>
  <label>
    <input type="radio" name="radios" />
    Answer 2
  </label>
</fieldset>
```

```ruby
find :radio_button, "Answer 1", fieldset: "My question"
choose "Answer 1", fieldset: "My question"
```

Also see [↓ Locating fields](#locating-fields)

#### `required` [Boolean]

Added to: `button`, `link`, `link_or_button`, `field`, `fillable_field`, `radio_button`, `checkbox`, `select`, `file_field`, `combo_box` and `rich_text`.

Filter for controls with a `required` or `aria-required` attribute.

For example:

```html
<label>
<input requied />
Text
</label>
```

```ruby
find :field, required: true
```

#### `role` [String]

Added to: `button`, `checkbox`, `css`, `element`, `field`, `file_field`, `fillable_field`, `link`, `link_or_button`, `radio_button`, `select`, and `xpath`

Filters for an element that declares a matching [role](https://www.w3.org/TR/wai-aria/#usage_intro) attribute.

```html
<label for="switch-input">A switch input</label>
<input id="switch-input" type="checkbox" role="switch">
```

```ruby
expect(page).to have_field "A switch input", role: "switch"
```

#### `validation_error` [String]

Added to: `field`, `fillable_field`, `datalist_input`, `radio_button`, `checkbox`, `select`, `file_field`, `combo_box` and `rich_text`.

Filters for an element being both invalid, and has a description or label containing the error message.

To be invalid, the element must [`willValidate`](https://developer.mozilla.org/en-US/docs/Web/API/HTMLObjectElement/willValidate) and have a [`validity.valid`](https://developer.mozilla.org/en-US/docs/Web/API/ValidityState) that is false. Additionally the `aria-invalid` must not contradict the validity state.

For the error description, this can be contained in the ARIA description, or the label.

```html
<label>
  My field
  <input required aria-describedby="error-id" />
</label>
<span id="error-id">This is required</span>
```

```ruby
expect(page).to have_field "My field", validation_error: "This is required"
```

Also see:

- [↓ `have_validation_errors` expectation](#have_validation_errorsblock)
- [↓ `have_no_validation_errors` expecation](#have_no_validation_errors)

### Selectors

#### Locating fields

The following selectors have been extended so you can use an array as the locator to select within a fieldset. The last element of the array is the field label, and the other elements are fieldsets.

Extended selectors: `button`, `link`, `link_or_button`, `field`, `fillable_field`, `datalist_input`, `radio_button`, `checkbox`, `select`, `file_field`, `combo_box`, `rich_text`.

```html
<fieldset>
  <legend>My question</legend>
  <label>
    <input type="radio" name="radios" />
    Answer 1
  </label>
  <label>
    <input type="radio" name="radios" />
    Answer 2
  </label>
</fieldset>
```

```ruby
find :radio_button, ["My question", "Answer 1"]
choose ["My question", "Answer 1"]
```

Also see [↑ `fieldset` filter](#fieldset-string-symbol-array)

#### `alert`

Selects an element with the role of [`alert`](https://www.w3.org/WAI/ARIA/apg/patterns/alert/).

```html
<div role="alert">Important message</div>
```

```ruby
expect(page).to have_selector :alert, text: "Successfully saved"
expect(page).to have_alert, text: "Successfully saved"
```

Also see [↓ Expectation shortcuts](#expectation-shortcuts)

#### `article`

Finds an [article structural role](https://www.w3.org/WAI/ARIA/apg/practices/structural-roles/#all-structural-roles). The selector will match either an [`<article>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/article) or an element with [role="article"](https://www.w3.org/TR/wai-aria/#article).

- `locator` [String, Symbol] The article's `[aria-label]` attribute or contents
  of the element referenced by its `[aria-labelledby]` attribute

Also see:

- [↓ Expectation shortcuts](#expectation-shortcuts)

#### `banner`

Finds a [banner landmark](https://www.w3.org/WAI/ARIA/apg/practices/landmark-regions/#x4-3-1-banner).

- `locator` [String, Symbol] The landmark's `[aria-label]` attribute or contents
  of the element referenced by its `[aria-labelledby]` attribute

Also see:

- [↓ Expectation shortcuts](#expectation-shortcuts)


#### `columnheader`

Finds a [columnheader](https://w3c.github.io/aria/#columnheader) cell that's either a `<th>` element descendant of a `<table>`, or a `[role="columnheader"]` element.

- `locator` [String, Symbol] The text contents of the element
- filters:
  - `colindex` [Integer, String] Filters elements based on their position amongst their siblings, or elements with a matching [aria-colindex](https://w3c.github.io/aria/#aria-colindex)

Also see:

- [↓ Expectation shortcuts](#expectation-shortcuts)

Example:

```html
<table role="grid">
  <tr>
    <th>A columnheader</th>
  </tr>
</table>

<div role="grid">
  <div role="row">
    <div role="columnheader">A columnheader</div>
  </div>
</div>
```

```ruby
expect(page).to have_selector :columnheader, "A columnheader", count: 2
```

#### `combo_box`

Finds a [combo box](https://www.w3.org/WAI/ARIA/apg/patterns/combobox/).
This will find ARIA 1.0 and ARIA 1.1 combo boxes. A combo box is an input with a popup list of options.

This also finds select based on [Twitter typeahead](https://twitter.github.io/typeahead.js/) classes, but this behaviour is deprecated and will be removed in a future release.

Locator and options are the same as the [field selector](https://www.rubydoc.info/github/jnicklas/capybara/Capybara/Selector) with the following additional filters:

- Filters:
  - `expanded` [Boolean] - Is the combo box expanded
  - `options` [Array\<String, Regexp\>] - Has exactly these options in order. This, and other other filters, will match if the option includes the string
  - `with_options` [Array\<String, Regexp\>] - Includes these options
  - `enabled_options` [Array\<String, Regexp\>] - Has exactly these enabled options in order
  - `with_enabled_options` [Array\<String, Regexp\>] - Includes these enabled options
  - `disabled_options` [Array\<String, Regexp\>] - Has exactly these disabled options in order
  - `with_disabled_options` [Array\<String, Regexp\>] - Includes these disabled options

Option text is normalised to single white spaces.

Note that the built-in Capybara selector `datalist_input` will find a [native html `list` attribute based combo-box](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/datalist).

Also see:

- [↓ `select_combo_box_option` action](#select_combo_box_optionwith-options)
- [↓ Expectation shortcuts](#expectation-shortcuts)

#### `contentinfo`

Finds a [contentinfo landmark](https://www.w3.org/WAI/ARIA/apg/practices/landmark-regions/#x4-3-3-contentinfo).

- `locator` [String, Symbol] The landmark's `[aria-label]` attribute or contents
  of the element referenced by its `[aria-labelledby]` attribute

Also see:

- [↓ Expectation shortcuts](#expectation-shortcuts)

#### `disclosure`

Finds a [disclosure](https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/). This will find both a [native disclosure](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/details) (`<details>`/`<summary>`) and an ARIA disclosure.

- `locator` [String, Symbol] The text label of the disclosure
- Filters:
  - `expanded` [Boolean] Is the disclosure expanded

Note that an ARIA disclosure is typically hidden when closed. Using `expanded: false` will only find an element where `visible:` is set to `false` or `:all`.

Also see:

- [↓ `select_disclosure` action](#select_disclosure)
- [↓ `toggle_disclosure` action](#toggle_disclosurename-expand)
- [↓ Expectation shortcuts](#expectation-shortcuts)
- [↓ `within_disclosure`](#within_disclosurename-find_options-block)

#### `disclosure_button`

Finds the open and close button associated with a [disclosure](https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/). This will be a `<summary>`, a `<button>` or an element with the role of button.

- `locator` [String, Symbol] The text label of the disclosure
- Filters:
  - `expanded` [Boolean] Is the disclosure expanded

Also see:

- [↓ `select_disclosure` action](#select_disclosure)
- [↓ `toggle_disclosure` action](#toggle_disclosurename-expand)
- [↓ Expectation shortcuts](#expectation-shortcuts)

#### `grid`

Finds a [grid](https://www.w3.org/WAI/ARIA/apg/patterns/grid/) element that declares `[role="grid"]`.

- `locator` [String, Symbol] Either the grid's `[aria-label]` value, or the
  text contents of the elements referenced by its `[aria-labelledby]` attribute
- filters:
  - `described_by` [String, Symbol] The text contents of the elements referenced by
    its `[aria-describedby]` attribute, or the text contents of a `<table>` element's
    `<caption>` element

Also see:

- [↓ Expectation shortcuts](#expectation-shortcuts)

Example:

```html
<table role="grid" aria-label="A grid"></table>
<div role="grid" aria-label="A grid"></div>
```

```ruby
expect(page).to have_selector :grid, "A table grid", count: 2
```

#### `gridcell`

Finds a [gridcell](https://w3c.github.io/aria/#gridcell) element that's either a `<td>` descendant of a `<table>` or declares `[role="gridcell"]`.

- `locator` [String, Symbol]
- filters:
  - `columnheader` [String, Symbol] Filters elements based on their matching columnheader's text content
  - `rowindex` [Integer, String] Filters elements based on their ancestor row's positing amongst its siblings
  - `colindex` [Integer, String] Filters elements based on their position amongst their siblings

Also see:

- [↓ Expectation shortcuts](#expectation-shortcuts)

Example:

```html
<table role="grid">
  <tr>
    <td>A gridcell</td>
  </tr>
</table>

<div role="grid">
  <div role="row">
    <div role="gridcell">A gridcell</div>
  </div>
</div>
```

```ruby
expect(page).to have_selector :gridcell, "A gridcell", count: 2
```

#### `item` and `item_type`

Finds a [microdata](https://developer.mozilla.org/en-US/docs/Web/HTML/Microdata) item.

Microdata isn't exposed to users, including screen-readers. However this can still be a useful way to check a page has the expected information in the expected place.

- `locator` [String, Symbol] The `itemprop` name of the item
- Filters:
  - `type` [String, Symbol, Array] The `itemtype`. Also accepts and array of item types, for selecting nested item types

Example:

```html
<dl itemscope itemtype="application:person">
  <dt>First name</dt>
  <dd itemprop="first-name">Bob</dd>
  <dt>Last name</dt>
  <dd itemprop="last-name">Hoskins</dd>
</dl>
```

```ruby
expect(page).to have_selector :item, "first-name", type: "application:person", text: "Bob"
expect(page).to have_selector :item_type, "application:person"
```

Also see [↓ Expectation shortcuts](#expectation-shortcuts)

#### `main`

Finds a [main landmark](https://www.w3.org/WAI/ARIA/apg/practices/landmark-regions/#x4-3-5-main).

- `locator` [String, Symbol] The landmark's `[aria-label]` attribute or contents
  of the element referenced by its `[aria-labelledby]` attribute

Also see:

- [↓ Expectation shortcuts](#expectation-shortcuts)

#### `menu`

Finds a [menu](https://www.w3.org/WAI/ARIA/apg/patterns/menu/).

- `locator` [String, Symbol] Either the menu's `[aria-label]` value, the
  contents of the `[role="menuitem"]` or `<button>` referenced by its
  `[aria-labelledby]`
- Filters:
  - `expanded` [Boolean] Is the menu expanded
  - `orientation` [String] The menu's orientation, either `horizontal` or
    `vertical` (defaults to `vertical` when omitted

```html
<div role="menu" aria-label="Actions">
  <button type="button" role="menuitem">Share</li>
  <button type="button" role="menuitem">Save</li>
  <button type="button" role="menuitem">Delete</li>
</div>
```

```ruby
expect(page).to have_selector :menu, "Actions"
expect(page).to have_selector :menu, "Actions", expanded: true
```

#### `menuitem`

Finds a [menuitem](https://w3c.github.io/aria/#menuitem).

- `locator` [String, Symbol] The menuitem content or the
- `locator` [String, Symbol] Either the menuitem's contents, its `[aria-label]`
  value, or the contents of the element referenced by its `[aria-labelledby]`
- Filters:
  - `disabled` [Boolean] Is the menuitem disabled

```html
<div role="menu" aria-label="Actions">
  <button type="button" role="menuitem">Share</li>
  <button type="button" role="menuitem" aria-disabled="true">Save</li>
  <button type="button" role="menuitem">Delete</li>
</div>
```

```ruby
within :menu, "Actions", expanded: true do
  expect(page).to have_selector :menuitem, "Share"
  expect(page).to have_selector :menuitem, "Save", disabled: true
  expect(page).to have_no_selector :menuitem, "Do something else"
end
```

#### `modal`

Finds a [modal dialog](https://www.w3.org/WAI/ARIA/apg/patterns/dialogmodal/).

This checks for either

- a modal with the correct aria role, `aria-modal="true"` attribute, and it has an associated title.
- or, an open `<dialog>` element.

Note that it is not possible to distinguish between a `<dialog>` opened as a modal and as non-modal.

- `locator` [String, Symbol] The title of the modal

Also see:

- [↓ Expectation shortcuts](#expectation-shortcuts)
- [↓ `within_modal`](#within_modalname-find_options-block)

#### `navigation`

Finds a [navigation landmark](https://www.w3.org/WAI/ARIA/apg/practices/landmark-regions/#x4-3-6-navigation).

- `locator` [String, Symbol] The landmark's `[aria-label]` attribute or contents
  of the element referenced by its `[aria-labelledby]` attribute

Also see:

- [↓ Expectation shortcuts](#expectation-shortcuts)

#### `row`

Finds a [row](https://w3c.github.io/aria/#row) element that's either a `<tr>` descendant of a `<table>` or declares `[role="row"]`.

- `locator` [String, Symbol] The text contents of the element
- filters:
  - `rowindex` [Integer, String] Filters elements based on their position amongst their siblings, or elements with a matching [aria-rowindex](https://w3c.github.io/aria/#aria-rowindex)

Also see:

- [↓ Expectation shortcuts](#expectation-shortcuts)

Example:

```html
<table role="grid">
  <tr>
    <td>Within a row</td>
  </tr>
</table>

<div role="grid">
  <div role="row">
    <div role="gridcell">Within a row</div>
  </div>
</div>
```

```ruby
expect(page).to have_selector :row, "Within a row", count: 2
```

#### `region`

Finds a [region landmark](https://www.w3.org/WAI/ARIA/apg/practices/landmark-regions/#x4-3-7-region).

- `locator` [String, Symbol] The landmark's `[aria-label]` attribute or contents
  of the element referenced by its `[aria-labelledby]` attribute

Also see:

- [↓ Expectation shortcuts](#expectation-shortcuts)

#### `rich_text`

Finds a rich text editor.

This should be compatible with most browser based rich text editors. It searches for `contenteditable` section marked up with the correct role. It is also compatible with `<iframe>` based editors such as CKEditor 4 and TinyMCE.

- `locator` [String, Symbol] The label for the editor. This can be an `aria-label` or `aria-labelledby`. For iframe editors this is the `title` attribute.

For testing the content of an iframe based editor you need to use `within_frame`, or you can use `within_rich_text`.

```ruby
# non-iframe based editors
expect(page).to have_selector :rich_text, "Label", text: "My content"

# iframe based editors
within_frame find(:rich_text, "Label") do
  expect(page).to have_text "My content"
end
```

Also see:

- [↓ `fill_in_rich_text` action](#fill_in_rich_textlocator-options)
- [↓ Expectation shortcuts](#expectation-shortcuts)
- [↓ `within_rich_text`](#within_rich_textname-find_options-block)

#### `section`

Finds a section of the site based on the first heading in the section.

A section is html sectioning element: `<section>`, `<article>`, `<aside>`, `<footer>`, `<header>`, `<main>` or `<form>`.

- `locator` [String, Symbol] The text of the first heading
- filters:
  - `heading_level` [Integer, Enumerable] The heading level to find. Defaults to `(1..6)`
  - `section_element` [String, Symbol, Array] The section element to use. Defaults to `%i[section article aside footer header main form]`

```html
<section>
  <div>
    <h2>My section</h2>
  </div>
  Some content
</section>
```

```ruby
within :section, "My section" do
	expect(page).to have_text "Some content"
end
```

Also see

- [↓ Expectation shortcuts](#expectation-shortcuts)
- [↓ `within_section`](#within_sectionname-find_options-block)

#### `tab_panel`

Finds a [tab panel](https://www.w3.org/WAI/ARIA/apg/patterns/tabpanel/).

- `locator` [String, Symbol] The text label of the tab button associated with the panel
- Filters:
  - `open` [Boolean] Is the tab panel open.

Note that a closed tab panel is not visible. Using `open: false` will only find an element where `visible:` is set to `false` or `:all`.

Also see

- [↓ `select_tab` action](#select_tabname-block)
- [↓ Expectation shortcuts](#expectation-shortcuts)
- [↓ `within_tab_panel`](#within_tab_panelname-find_options-block)

#### `tab_button`

Finds the button that opens a tab.

- `locator` [String, Symbol] The text label of the tab button
- Filters:
  - `open` [Boolean] Is the tab panel open.

Also see:

- [↓ `select_tab` action](#select_tabname-block)
- [↓ Expectation shortcuts](#expectation-shortcuts)

### Actions

#### `fill_in_rich_text(locator, **options)`

Fill in a rich text field with plain text.

- `locator` [String] - Find the rich text area
- `options`:
  - `with` [String] - The text to fill the field, or nil to empty
  - `clear` [Boolean] - Clear the rich text area first, defaults to true

```ruby
fill_in_rich_text "Diary entry", with: "Today I published a gem"
```

Also see [↑ `rich_text` selector](#rich_text)

#### `select_tab(name, &block)`

Opens a tab by name.

- `name` [String] - The tab label to open
- `block` [Block] - Optional block to run within the tab

```ruby
select_tab "Client details"
```

Also see [↑ `tab_panel` selector](#tab_panel)

#### `select_combo_box_option(with, **options)`

Fill in a combo box and select an option

- `with` [String] - Option to select
- `options`:
  - `from` [String, Symbol, Array] - Locator for the field
  - `search` [String] - Alternative text to search for in the input
  - `currently_with` [String] - Current value for the field
  - options prefixed with `option_` will be used to find the option. eg `option_text`, `option_match`
  - other options will be used to find the combo box

```ruby
select_combo_box_option "Apple", from: "Fruits"
```

Also see [↑ `combo_box` selector](#combo_box)

#### `select_disclosure(name)`

Open disclosure if not already open, and return the disclosure.

- `name` [String] - Locator for the disclosure button
- options:
- `block` - When present, the `block` argument is forwarded to a
  [`within_disclosure`](#within_disclosurename-find_options-block) call

```ruby
select_disclosure("Client details")
select_disclosure "Client details" do
  expect(page).to have_text "The Client details contents"
end
```

Also see [↑ `disclosure` selector](#disclosure)

#### `toggle_disclosure(name, expand:)`

Toggle a disclosure open or closed, and return the button

- `name` [String] - Locator for the disclosure button
- options:
  - `expand` [Boolean] - Force open or closed rather than toggling.
- `block` - When present, the `block` argument is forwarded to a
  [`within_disclosure`](#within_disclosurename-find_options-block) call

```ruby
toggle_disclosure("Client details")
toggle_disclosure "Client details", expand: true do
  expect(page).to have_text "The Client details contents"
end
```

Also see [↑ `disclosure` selector](#disclosure)

### Limiting

#### `within_disclosure(name, **find_options, &block)`

Executing the block within a disclosure.

```ruby
within_disclosure "Client details" do
  expect(page).to have_text "Name: Frank"
end
```

Also see [↑ `disclosure` selector](#disclosure)

#### `within_modal(name, **find_options, &block)`

Execute the block within a modal.

```ruby
within_modal "Are you sure?" do
  click_button "Confirm"
end
```

Also see [↑ `modal` selector](#modal)

#### `within_rich_text(name, **find_options, &block)`

Execute within the rich text. If the rich text is iframe based this will execute "`within_frame`".

```ruby
within_rich_text "Journal entry" do
  expect(page).to have_text "Today I went to the zoo"
end
```

Also see [↑ `rich_text` selector](#rich_text)

#### `within_section(name, **find_options, &block)`

Execute the block within a section.

```ruby
within_section "Heading" do
  expect(page).to have_text "Section content"
end
```

Also see [↑ `section` selector](#section)

#### `within_tab_panel(name, **find_options, &block)`

Executing the block within a tab panel.

```ruby
within_tab_panel "Client details" do
  expect(page).to have_text "Name: Fred"
end
```

Also see [↑ `tab_panel` selector](#tab_panel)

### Expectations

#### `have_validation_errors(&block)`

Checks if a page has a set of validation errors. This will fail if the page does not have the exact set of errors.

- `&block` - this takes a block. In the block each validation error exception should be added using the following DSL:

```ruby
expect(page).to have_validation_errors do
  field "Name", validation_error: "This is required"
  select "Gender", validation_error: "This is required"
  field "Age", validation_error: "Please choose a number less than 120"

  # The block methods correspond to the following selectors:
  # field, radio_button, checkbox, select, file_field and combo_box
end
```

Also see [↑ `validation_error` filter](#validation_error-string)

#### `have_no_validation_errors`

Checks if a page has no invalid fields.

```ruby
expect(page).to have_no_validation_errors
```

Also see [↑ `validation_error` filter](#validation_error-string)

#### Expectation shortcuts

The following expectation shortcuts are also added for both `have_selector_` and `have_no_selector_`:

- `have_alert`
- `have_article`
- `have_banner`
- `have_columnheader`
- `have_combo_box`
- `have_contentinfo`
- `have_disclosure`
- `have_disclosure_button`
- `have_grid`
- `have_gridcell`
- `have_item`
- `have_main`
- `have_modal`
- `have_navigation`
- `have_region`
- `have_row`
- `have_section`
- `have_tab_panel`
- `have_tab_button`

For example the following two are equivalent:

```ruby
expect(page).to have_selector :combo_box, "Foo"
expect(page).to have_combo_box, "Foo"

```

## Local development

```bash
# install
bundle install

# lint
bundle exec rubocop

# test
# A local install of Chrome is required for the selenium web driver
bundle exec rspec
```
