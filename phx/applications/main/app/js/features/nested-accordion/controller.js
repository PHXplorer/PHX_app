/**
 * NestedAccordionController
 *
 * Controller class for the Nested Accordion feature.
 *
 * This class is used in the {@link NestedAccordionBinding}
 * and its static methods are used in the app from the R side.
 */
export class NestedAccordionController {
  /**
   * The current state of the controller.
   * @type {Object|null}
   */
  state = null;

  /**
   * The initial state of the controller.
   * @type {Object|null}
   */
  initialState = null;

  /**
   * Flag to skip immediate value return after initialization.
   * @type {boolean}
   */
  isInitialized = false;

  /**
   * Keep track of the order in which user selected variables in multiple selection mode.
   * This allows for a fine-grained control on how the variables are displayed on the runchart.
   * @type {string[]}
   */
  selectionQueue = [];

  /**
   * Constructs a new instance of the NestedAccordionController.
   * @param {Object} initialState - The initial state of the controller.
   * @param {string} elementId - The ID of the element associated with the controller.
   */
  constructor(initialState, elementId) {
    this.state = initialState;
    this.initialState = initialState;
    this.#handleSelectionQueue(elementId);
  }

  /**
   * Handles the selection order of checkbox and selectpicker inputs.
   * @private
   * @param {string} elemId - The ID of the element associated with the selection queue.
   */
  #handleSelectionQueue(elemId) {
    $(document).on('change', `#${elemId} input[type="checkbox"]`, (event) => {
      const { variable } = event.currentTarget.dataset;
      if (event.currentTarget.checked) {
        this.selectionQueue.push(variable);
      } else {
        this.selectionQueue = this.selectionQueue.filter((x) => x !== variable);
      }
    });

    $(document).on('change', `#${elemId} .custom-selectpicker .selectpicker`, (event) => {
      const { variable } = $(event.currentTarget).parent().siblings('label').data();
      if (event.currentTarget.value !== '') {
        this.selectionQueue.push(variable);
      } else {
        this.selectionQueue = this.selectionQueue.filter((x) => x !== variable);
      }
    });
  }

  /**
   * Button click represents a single selection in the nested accordion.
   * For examples see measure selection, or comparison variable selection.
   * @param {Event} event - The button click event.
   */
  handleButtonClick(event) {
    const variable = $(event.currentTarget).data('variable');
    const category = null;
    this.state = { variable, category };
  }

  /**
   * Picker select single represents a single selection in the nested accordion.
   * For examples see univariate regression variable selection.
   * @param {Event} event - The selectpicker selection event.
   */
  handlePickerSelectSingle(event) {
    const variable = $(event.currentTarget).parent().siblings('label').data('variable');
    const category = event.currentTarget.value;
    this.state = { variable, category };
  }

  /**
   * Multiple selection involves checkboxes and selectpickers.
   * For examples see attribute selection, EDA variable selection.
   * @param {HTMLElement} element - The element containing the selections.
   */
  handleMultipleSelection(element) {
    this.state = [];

    const selectedVariables = [];

    $(element)
      .find('input[type="checkbox"]')
      .each((i, x) => {
        if (x.checked) {
          selectedVariables.push(x.dataset.variable);
        }
      });

    $(element)
      .find('.custom-selectpicker .selectpicker')
      .each((i, x) => {
        const variable = $(x).parent().siblings('label').data('variable');
        if ($(x).val() !== '') {
          selectedVariables.push(variable);
        }
      });

    // eslint-disable-next-line max-len
    selectedVariables.sort((a, b) => this.selectionQueue.indexOf(a) - this.selectionQueue.indexOf(b));

    selectedVariables.forEach((variable) => {
      $(element)
        .find(`[data-variable="${variable}"]`)
        .each((i, x) => {
          if (x?.type === 'checkbox' && x.checked) {
            this.state.push({ variable, category: null, value: null });
            return;
          }

          const $picker = $(x).siblings('.dropdown').find('.selectpicker');

          if ($picker.val() !== '') {
            this.state.push({ variable, category: $picker.val(), value: null });
          }
        });
    });

    this.selectionQueue = [];
  }

  /**
   * Filter selection is a special case of the component.
   * It shuold gather values from all normal select pickers, but in case of categorized numerical
   * variables, it should ignore "categorization" pickers and get all required information
   * from "filter value" pickers
   * @param {HTMLElement} element - The element containing the filter selections.
   */
  handleFilterSelection(element) {
    this.state = [];

    const $pickers = $(element).find('.custom-selectpicker select');
    $pickers.each((i, x) => {
      const value = $(x).val();
      if (value === '' || value === null || value.length === 0) {
        return;
      }

      const isCategorization = $(x).data('isCategorization');
      if (isCategorization) {
        return;
      }

      const pickerType = $(x).data('picker-type');

      const variable = $(x).data('variable');
      const category = pickerType === 'filter-value' ? x.dataset.category : null;

      this.state.push({ variable, category, value });
    });
  }

  /**
   * Resets the state of the controller to its initial state and clears the selection queue.
   */
  handleResetState() {
    this.state = this.initialState;
    this.selectionQueue = [];
  }

  /**
   * Parses the initial state from raw values.
   * @param {string} initialValuesRaw - The raw initial values that comes from dataset attribute.
   * @returns {Object|null} - The parsed initial state.
   */
  static parseInitialState(initialValuesRaw) {
    if (!initialValuesRaw) {
      return null;
    }

    const state = JSON.parse(initialValuesRaw);

    if (state.is_multiple[0]) {
      return state.variable.map((v, i) => ({
        variable: v,
        category: state.category[i],
        value: state.filter_values[i],
      }));
    }

    return {
      variable: state.variable[0],
      category: state.category[0],
      value: state.filter_values[0],
    };
  }

  /**
   * Triggers a special change event on the {@link NestedAccordionBinding}
   * @param {string} id - The ID of the element associated with the multiple dimension selection.
   */
  static handleMultipleDimensionSelection(id) {
    $(`#${id}`).trigger('change:manual');
    window.Shiny.modal.remove();
  }

  /**
   * Triggers a special change event on the {@link NestedAccordionBinding}
   * @param {string} id - The ID of the element associated with the filter apply event.
   */
  static handleFilterApply(id) {
    $(`#${id}`).trigger('change:filter');
    window.Shiny.modal.remove();
  }

  /**
   * Triggers a special change event on the {@link NestedAccordionBinding}
   * @param {Object} options - The options for the multiple dimension reset event.
   * @param {string} options.id - The ID of the element associated with
   * the multiple dimension reset event.
   */
  static handleMultipleDimensionReset({ id }) {
    $(`#${id}`).trigger('change:reset');

    // When controller is not initialized (e.g not rendered), triggering the event will not work
    // In this case, all we can do is to manually reset the label of the button
    // input values will not be changed however, so they should be handled by the server
    const buttonId = id.replace(/-selected$/, '-show_modal');
    const button = document.getElementById(buttonId);
    const { initialLabel } = button.dataset;
    button.innerHTML = initialLabel;
    window.Shiny.modal.remove();
  }
}
