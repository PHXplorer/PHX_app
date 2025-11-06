import { NestedAccordionController, NestedAccordionBinding } from '../features/nested-accordion';

// #region Custom Message Handlers
$(() => {
  // reset input value in the nested accordion
  Shiny.addCustomMessageHandler('bmcResetAccordion', NestedAccordionController.handleMultipleDimensionReset);

  // Receive label map that is used in the Shiny Binding
  Shiny.addCustomMessageHandler('bmcLabelMap', (message) => {
    window.bmcLabelMap = message;
  });

  // Receive choices map for text variables - will be used in advanced filters
  Shiny.addCustomMessageHandler('bmcChoicesMap', (message) => {
    window.bmcChoicesMap = message;
  });

  // Set the unique categories for the advanced filter
  Shiny.addCustomMessageHandler('config-unique-categories', (message) => {
    window.configUniqueCategories = message;
  });
});
// #endregion

// #region Shiny Binding
Shiny.inputBindings.register(new NestedAccordionBinding(), 'bmc-nested-accordion');
// #endregion
