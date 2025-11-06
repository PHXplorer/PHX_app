import { Button } from './Button';
import { Checkbox } from './Checkbox';
import { SelectPicker, SelectPickerFiltersNumeric, SelectPickerFiltersText } from './SelectPicker';

/**
 * AccordionSectionInputsDispatcher
 *
 * This component is responsible for rendering the correct input component in the accordion section.
 * Decision on what to render is based on the value_type (text or num), mode (select or filter), and is_multiple.
 * This component is written in a "not smart" way intentionally, to allow for easy extension in the future while
 * keeping the dispatching logic consolidated.
 *
 * @param {Object} props - The component props.
 * @param {AccordionMode} props.mode - The mode of the component ('select' or 'filter').
 * @param {boolean} props.is_multiple - Indicates if multiple selections are allowed.
 * @param {string} props.namespace - The namespace of the component.
 * @param {FeatureTreeLeaf} props.properties - The properties of the component.
 * @param {string[]} props.selectedVariables - The selected variables.
 * @param {string[]} props.selectedCategories - The selected categories.
 * @param {string[]} props.selectedFilterValues - The selected filter values.
 * @param {string[]} props.initialChoices - The initial choices.
 * @param {boolean} props.allowContinuous - Indicates if continuous values are allowed.
 * @returns {React.ReactNode} The rendered component.
 */
export function AccordionSectionInputsDispatcher({
  mode = 'select',
  is_multiple = false,
  namespace,
  properties,
  selectedVariables = [],
  selectedCategories = [],
  selectedFilterValues = [],
  initialChoices = [],
  allowContinuous = false,
}) {
  const { value_type } = properties;

  if (value_type === 'text' && mode === 'select' && is_multiple) {
    return (
      <Checkbox
        namespace={namespace}
        properties={properties}
        checkedByDefault={selectedVariables.includes(properties.colname)}
      />
    );
  }

  if (value_type === 'text' && mode === 'select' && !is_multiple) {
    return (
      <Button
        namespace={namespace}
        properties={properties}
        disabled={selectedVariables.includes(properties.colname)}
        active={selectedVariables.includes(properties.colname)}
      />
    );
  }

  if (value_type === 'text' && mode === 'filter') {
    return (
      <SelectPickerFiltersText
        namespace={namespace}
        properties={properties}
        active={selectedVariables.includes(properties.colname)}
        selectedVariables={selectedVariables}
        selectedFilterValues={selectedFilterValues}
      />
    );
  }

  const choices = allowContinuous ? initialChoices : initialChoices.filter((x) => x !== 'Continuous');

  if (value_type === 'num' && mode === 'select') {
    return (
      <SelectPicker
        namespace={namespace}
        properties={properties}
        choices={choices}
        multiple={is_multiple}
        active={selectedVariables.includes(properties.colname)}
        selectedVariables={selectedVariables}
        selectedCategories={selectedCategories}
      />
    );
  }

  if (value_type === 'num' && mode === 'filter') {
    return (
      <SelectPickerFiltersNumeric
        properties={properties}
        choices={choices}
        active={selectedVariables.includes(properties.colname)}
        selectedVariables={selectedVariables}
        selectedCategories={selectedCategories}
        selectedFilterValues={selectedFilterValues}
      />
    );
  }
}
