/// <reference types="../../../.rhino/node_modules/@types/rstudio-shiny/" />

/**
 * Flattens a tree-like object structure into a flat object.
 *
 * @param {FeatureTree} tree - The tree-like object to flatten.
 * @returns {string[]} - List of colnames from the terminal nodes in the tree.
 */
export function flattenTree(tree) {
  const result = [];

  function traverse(node) {
    if (node.colname) {
      result.push(node.colname);
    } else {
      Object.values(node).forEach(traverse);
    }
  }

  traverse(tree);

  return result;
}

/**
 * Displays a shiny notification.
 *
 * @param {string} msg - The message to display in the notification.
 * @param {string} type - The type of the notification.
 */
export function showShinyNotification(msg, type) {
  window.Shiny.notifications.show({ html: `<span data-cy="shiny-notification">${msg}</span>`, type });
}

/**
 * NOTHING_LABEL
 *
 * label to display when no variable is selected. type: htmlString
 */
// prettier-ignore
export const NOTHING_LABEL = '<i class="fas fa-plus dimension-input-default-icon" role="presentation" aria-label="plus icon" title="Click here to add a dimension" data-cy="dimension-input-default-icon"></i>';

/**
 * Returns the label for a given variable value.
 * @param {Object} value - The value object containing the variable and category.
 * @param {string} value.variable - The variable name.
 * @param {string} value.category - The category name.
 * @returns {string} - The label for the variable value.
 */
export function getVariableLabel(value) {
  if (value === undefined || value === null || value.variable === '') {
    return NOTHING_LABEL;
  }

  const { variable, category } = value;
  const labelIndex = window.bmcLabelMap.colname.indexOf(variable);

  const label = window.bmcLabelMap.label[labelIndex];
  const valueType = window.bmcLabelMap.value_type[labelIndex];

  if (valueType === 'num' && category === '') {
    return NOTHING_LABEL;
  }

  if (category === '' || category === undefined || category === null) {
    return label;
  }

  return `${label} (${category})`;
}
