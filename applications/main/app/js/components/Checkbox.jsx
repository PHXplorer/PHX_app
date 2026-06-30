/* global React, ReactBootstrap */

import { showShinyNotification } from '../utils';
import { MultipleCountContext } from './AccordionSection';

/**
 * Checkbox component.
 *
 * @param {Object} props - The component props.
 * @param {string} props.namespace - The namespace for the checkbox.
 * @param {FeatureTreeLeaf} props.properties - The properties for the checkbox.
 * @param {boolean} props.checkedByDefault - Whether the checkbox is checked by default.
 * @returns {React.ReactNode} The checkbox component.
 */
export function Checkbox({ namespace, properties, checkedByDefault }) {
  const { values, updateValues, multipleLimit } = React.useContext(MultipleCountContext);
  const [checked, setChecked] = React.useState(checkedByDefault);

  /**
   * @param {React.ChangeEvent<HTMLInputElement>} event
   * @returns {void}
   */
  const handleChange = (event) => {
    if (!!event.target.checked && values.length >= multipleLimit) {
      showShinyNotification('Selection limit reached', 'error');
      return;
    }
    updateValues(properties.colname, event.target.checked ? 'add' : 'remove');
    setChecked(event.target.checked);
  };

  return (
    <ReactBootstrap.Form.Check
      type="checkbox"
      className="checkbox-attribute-selection"
      data-ns={namespace}
      data-variable={properties.colname}
      checked={checked}
      onChange={handleChange}
      label={
        <>
          {properties.label}
          <a className="has-popover leaf-info" data-content={properties.description} data-trigger="hover">
            <i className="icon ion-md-information-circle-outline" />
          </a>
        </>
      }
      id={properties.label}
    />
  );
}
