/* eslint-disable class-methods-use-this */

/// <reference types="../../../../.rhino/node_modules/@types/rstudio-shiny/" />

import { NOTHING_LABEL, getVariableLabel } from '../../utils';
import { NestedAccordionController } from './controller';

/**
 * NestedAccordionBinding
 *
 * Shiny input binding for the nested accordion component.
 * https://shiny.posit.co/r/articles/build/building-inputs/
 * Things to watch out for:
 * - When the binding is initialized, it creates an instance of a {@link NestedAccordionController}.
 *   The controller class instance lives inside the ShinyBinding class instance - which means that
 *   the component state is not accessible from the outside AND is destroyed according to Shiny
 *   component lifecycle.
 * - The controller instance gets initial state based on the data passed from R through a
 *   dataset attribute. Parsing process is special, and needs to be adjusted if you want to
 *   pass new things to the controller.
 * - Shiny binding is subscribed to different events, see {@link NestedAccordionBinding.subscribe}.
 *   Each type of event is handled by a corresponding Controller method.
 * - The component can return different types of values, and the logic to process that value and
 *   send to R session is intimidating but fairly simple. Essentially, the value sent to R should be
 *   either a {@link NestedAccordionValue} object or an array of such objects.
 *   When it is a single value it is immediately parsed by R as a list, but when
 *   it's a stringified array, it goes raw.
 * - updateButtonLabel is a custom method that normally doesn't belong to
 *   a Shiny.InputBinding class.
 *   It was created to consolidate repeating logic for updating the button label.
 *   The reason why it exists, is to take this logic away from Shiny: when button is updated
 *   from the Shiny side it takes too long and causes poor user experience.
 */
export class NestedAccordionBinding extends Shiny.InputBinding {
  controller = {};

  find(scope) {
    return $(scope).find('.bmc-nested-accordion');
  }

  getId(el) {
    return el.id;
  }

  initialize(el) {
    const initialState = NestedAccordionController.parseInitialState(el.dataset.initial_values);
    this.controller[el.id] ??= new NestedAccordionController(initialState, el.id);
  }

  getValue(el) {
    // Skip immediate value return after initialization
    if (!this.controller[el.id].isInitialized) {
      this.controller[el.id].isInitialized = true;
      return undefined;
    }
    const value = this.controller[el.id].state;
    console.debug(el.id, 'getValue', value);

    const shouldUpdateLabel = JSON.parse(el.dataset.isLabelDynamic ?? 'true');

    if (Array.isArray(value)) {
      let newLabel = '';
      const variableLabels = value.map((x) => getVariableLabel(x));
      switch (value.length) {
        case 0:
          newLabel = NOTHING_LABEL;
          break;
        case 1:
          newLabel = getVariableLabel(value[0]);
          break;
        case 2:
          newLabel = variableLabels.join(' and ');
          break;
        case 3:
          newLabel = `${variableLabels.slice(0, -1).join(', ')}, and ${variableLabels.slice(-1)}`;
          break;
        default:
          newLabel = `${value.length} variables`;
      }
      if (shouldUpdateLabel) {
        this.updateButtonLabel(el, newLabel);
      }
      return JSON.stringify(value.filter((x) => x.category !== ''));
    }

    const newLabel = getVariableLabel(value);
    if (shouldUpdateLabel) {
      this.updateButtonLabel(el, newLabel);
    }

    return value;
  }

  subscribe(el, callback) {
    console.debug(el.id, 'subscribe');
    $(el).on('click', '.btn-attribute-selection', (event) => {
      this.controller[el.id].handleButtonClick(event);
      callback();
    });

    $(el).on('change', '.custom-selectpicker .selectpicker[mode=select]', (event) => {
      this.controller[el.id].handlePickerSelectSingle(event);
      callback();
    });

    $(el).on('change:manual', () => {
      this.controller[el.id].handleMultipleSelection(el);
      callback();
    });

    $(el).on('change:filter', () => {
      this.controller[el.id].handleFilterSelection(el);
      callback();
    });

    $(el).on('change:reset', () => {
      this.controller[el.id].handleResetState();
      callback();
    });
  }

  unsubscribe(el) {
    console.debug(el.id, 'unsubscribe');
    this.controller[el.id].isInitialized = false;
    $(el).off('click', '.btn-attribute-selection');
    $(el).off('change', '.custom-selectpicker .selectpicker[mode=select]');
    $(el).off('change:manual');
    $(el).off('change:filter');
    $(el).off('change:reset');
  }

  updateButtonLabel(el, label) {
    const buttonId = `#${el.id.replace(/-selected$/, '-show_modal')}`;
    const currentLabel = $(buttonId).text();

    const finalLabel = label ?? currentLabel ?? NOTHING_LABEL;

    $(buttonId).html(finalLabel);
  }
}
