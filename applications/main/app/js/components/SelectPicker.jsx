/* global React */

import { showShinyNotification } from '../utils';
import { MultipleCountContext } from './AccordionSection';

/**
 * SelectPicker
 *
 * Bootstrap-select picker component reacreated in React.
 *
 * @component
 * @param {Object} props - The component props.
 * @param {string} props.namespace - The namespace for the select picker.
 * @param {FeatureTreeLeaf} props.properties - The properties for the select picker.
 * @param {string[]} props.choices - The choices for the select picker.
 * @param {boolean} props.multiple - Indicates if multiple selections are allowed.
 * @param {boolean} props.active - Indicates if the select picker is active.
 * @param {string[]} props.selectedVariables - The selected variables for the select picker.
 * @param {string[]} props.selectedCategories - The selected categories for the select picker.
 * @returns {React.ReactNode} The rendered SelectPicker component.
 */
export function SelectPicker({
  namespace,
  properties,
  choices,
  multiple,
  active,
  selectedVariables,
  selectedCategories,
}) {
  const { values, updateValues, multipleLimit } = React.useContext(MultipleCountContext);
  const [value, setValue] = React.useState('');

  /** @type {React.RefObject<HTMLElement>} */
  const selectRef = React.useRef(null);

  /** @param {React.ChangeEvent<HTMLInputElement>} event */
  const handleChange = (event) => {
    if (!!event.target.value && values.length >= multipleLimit && !values.includes(properties.colname)) {
      showShinyNotification('Selection limit reached', 'error');
      $(event.target).selectpicker('val', '');
      return;
    }
    updateValues(properties.colname, !!event.target.value ? 'add' : 'remove');
    setValue(event.target.value);
  };

  React.useEffect(() => {
    $(selectRef.current).selectpicker();
    const idx = selectedVariables.indexOf(properties.colname);
    if (idx >= 0) {
      $(selectRef.current).selectpicker('val', selectedCategories[idx]).selectpicker('refresh');
    }
    setValue(selectRef.current?.value ?? '');

    return () => $(selectRef.current).selectpicker('destroy');
  }, [selectRef]);

  return (
    <div
      className="custom-selectpicker"
      style={active ? { border: '1px solid #17a2b8', backgroundColor: '#17a2b830' } : undefined}
    >
      <label className="control-label" data-variable={properties.colname}>
        {properties.label}
        <a className="has-popover leaf-info" data-content={properties.description} data-trigger="hover">
          <i className="icon ion-md-information-circle-outline" />
        </a>
      </label>
      <select
        ref={selectRef}
        className="selectpicker"
        mode={multiple ? 'select:num' : 'select'}
        data-ns={namespace}
        value={value}
        onChange={handleChange}
      >
        {choices.map((category) => (
          <option key={category} value={category}>
            {category}
          </option>
        ))}
      </select>
    </div>
  );
}

/**
 * SelectPickerFiltersText
 *
 * Slighlty modified version of the {@link SelectPicker} component for text filters.
 * It is optimized for re-renders by avoiding usage of {@link MultipleCountContext}.
 * Its state is handled by the bootstrap-select itself - from React's perspective it is an uncontrolled component.
 *
 * @component
 * @param {Object} props - The component props.
 * @param {string} props.namespace - The namespace for the select picker.
 * @param {FeatureTreeLeaf} props.properties - The properties for the select picker.
 * @param {boolean} props.active - Indicates if the select picker is active.
 * @param {string[]} props.selectedVariables - The selected variables for the select picker.
 * @param {string[]} props.selectedFilterValues - The selected filter values for the select picker.
 * @returns {React.ReactNode} The rendered SelectPicker component.
 */
export function SelectPickerFiltersText({ namespace, properties, active, selectedVariables, selectedFilterValues }) {
  /** @type {React.RefObject<HTMLElement>} */
  const ref = React.useRef(null);

  const choices = React.useMemo(() => {
    return window.bmcChoicesMap[properties.colname] ?? [];
  }, []);

  React.useEffect(() => {
    $(ref.current).selectpicker();
    const idx = selectedVariables.indexOf(properties.colname);
    if (idx >= 0) {
      $(ref.current).selectpicker('val', selectedFilterValues[idx]).selectpicker('refresh');
    }
    return () => $(ref.current).selectpicker('destroy');
  }, [ref.current]);

  return (
    <div
      className="custom-selectpicker"
      style={active ? { border: '1px solid #17a2b8', backgroundColor: '#17a2b830' } : undefined}
    >
      <label className="control-label">
        {properties.label}
        <a className="has-popover leaf-info" data-content={properties.description} data-trigger="hover">
          <i className="icon ion-md-information-circle-outline" />
        </a>
      </label>
      <select
        ref={ref}
        className="selectpicker"
        mode="filter"
        data-ns={namespace}
        data-variable={properties.colname}
        multiple
      >
        {choices.map((category) => (
          <option key={category} value={category}>
            {category}
          </option>
        ))}
      </select>
    </div>
  );
}

/**
 * SelectPickerFiltersNumeric
 *
 * Very similar to {@link SelectPickerFiltersText}, but for numeric inputs.
 * Contains two select pickers - one for categorization and one for filter values.
 *
 * Code duplication is partially on purpose to avoid leaky abstractions and coupled implementation.
 *
 * @component
 * @param {Object} props - The component props.
 * @param {FeatureTreeLeaf} props.properties - The properties for the select picker.
 * @param {boolean} props.active - Indicates if the select picker is active.
 * @param {string[]} props.selectedVariables - The selected variables for the select picker.
 * @param {string[]} props.selectedCategories - The selected categories for the select picker.
 * @param {string[]} props.selectedFilterValues - The selected filter values for the select picker.
 * @returns {React.ReactNode} The rendered SelectPicker component.
 */
export function SelectPickerFiltersNumeric({
  properties,
  choices,
  active,
  selectedVariables,
  selectedCategories,
  selectedFilterValues,
}) {
  /** @type {React.RefObject<HTMLElement>} */
  const categorizationRef = React.useRef(null);

  /** @type {React.RefObject<HTMLElement>} */
  const valueRef = React.useRef(null);

  const [categorization, setCategorization] = React.useState('');

  React.useEffect(() => {
    $(categorizationRef.current).selectpicker();
    const idx = selectedVariables.indexOf(properties.colname);
    if (idx >= 0) {
      $(categorizationRef.current).selectpicker('val', selectedCategories[idx]).selectpicker('refresh');
      setCategorization(selectedCategories[idx]);
    }
    return () => $(categorizationRef.current).selectpicker('destroy');
  }, []);

  React.useEffect(() => {
    $(valueRef.current).selectpicker();
    const idx = selectedVariables.indexOf(properties.colname);
    if (idx >= 0) {
      $(valueRef.current).selectpicker('val', selectedFilterValues[idx]).selectpicker('refresh');
    }
    return () => $(valueRef.current).selectpicker('destroy');
  }, [categorization]);

  const handleCategorizationChange = React.useCallback((event) => setCategorization(event.target.value), []);

  const valueChoices = React.useMemo(() => window.configUniqueCategories[categorization] ?? [], [categorization]);

  return (
    <div
      style={{
        marginBottom: '1rem',
        borderBottom: '1px solid #66666630',
        border: active ? '1px solid rgb(23, 162, 184)' : undefined,
        backgroundColor: active ? 'rgba(23, 162, 184, 0.19)' : undefined,
      }}
    >
      <label style={{ display: 'flex', justifyContent: 'center', marginBottom: '0.5rem' }}>
        {properties.label}
        <a
          className="has-popover leaf-info"
          style={{ marginLeft: '0.375rem' }}
          data-content={properties.description}
          data-trigger="hover"
        >
          <i className="icon ion-md-information-circle-outline" />
        </a>
      </label>
      <div style={{ display: 'flex', gap: '1rem', justifyContent: 'space-between' }}>
        <div className="custom-selectpicker" style={{ width: '100%' }}>
          <label className="control-label" style={{ justifyContent: 'center' }}>
            Categorization
          </label>
          <select
            ref={categorizationRef}
            className="selectpicker"
            mode="filter"
            value={categorization}
            onChange={handleCategorizationChange}
            data-is-categorization
          >
            {choices.map((category) => (
              <option key={category} value={category}>
                {category}
              </option>
            ))}
          </select>
        </div>
        <div className="custom-selectpicker" style={{ width: '100%' }}>
          <label className="control-label" style={{ justifyContent: 'center' }}>
            Filter Value
          </label>
          <select
            ref={valueRef}
            className="selectpicker"
            mode="filter"
            data-variable={properties.colname}
            data-category={categorization}
            data-picker-type="filter-value"
            disabled={valueChoices.length === 0}
            multiple
          >
            {valueChoices.map((category) => (
              <option key={category} value={category}>
                {category}
              </option>
            ))}
          </select>
        </div>
      </div>
    </div>
  );
}
