/* global React */

import { flattenTree } from '../utils';
import { AccordionSectionInputsDispatcher } from './AccordionSectionInputsDispatcher';
import { BadgeCounter } from './BadgeCounter';
import { ButtonExpand } from './Button';

/**
 * This react context is used to keep track of the selected variables in the accordion:
 * (1) display the number of selected variables in the accordion header
 * (2) prevent the user from selecting more variables than the limit
 * @type {React.Context<MultipleCountContextType>}
 */
export const MultipleCountContext = React.createContext();

/**
 * A recursive component that renders an accordion sections based on the FeatureTree data.
 * Recursive base case is reached when the data has a `featureid` property, which means
 * that the current section is a leaf node.
 *
 * When on a "leaf node", the `AccordionSectionInputsDispatcher` component is rendered.
 *
 * @component
 * @param {Object} props - The component props.
 * @param {string} props.id - The ID of the accordion section.
 * @param {string} props.parentId - The ID of the parent accordion section.
 * @param {FeatureTree} props.data - The data for the accordion section.
 * @param {string} props.namespace - The namespace for the accordion section.
 * @param {boolean} props.multiple - Indicates if multiple selections are allowed.
 * @param {AccordionMode} props.mode - The mode of the accordion section.
 * @param {boolean} props.allowContinuous - Indicates if continuous categorization is allowed.
 * @param {string[]} props.selectedVariables - The selected variables.
 * @param {string[]} props.selectedCategories - The selected categories.
 * @param {string[]} props.selectedFilterValues - The selected filter values.
 * @returns {React.ReactNode} The rendered accordion section component.
 */
export function AccordionSection({
  id,
  parentId,
  data,
  namespace,
  multiple,
  mode,
  allowContinuous,
  selectedVariables,
  selectedCategories,
  selectedFilterValues,
}) {
  /** @type {React.RefObject<HTMLElement>} */
  const ref = React.useRef(null);

  const cleanId = `${parentId}_${id.replace(/\s/g, '_').replace(/[()]/g, '')}`;

  let cardBodyContent = null;
  let updatedData = data;
  let updatedId = id;

  if (Object.values(data[id]).every((x) => x?.featureid !== undefined)) {
    updatedData = data[id];
    updatedId = Object.keys(updatedData)[0];
  }

  const numericCategorizationChoices = [''].concat(Object.keys(window.configUniqueCategories));

  if (allowContinuous) {
    numericCategorizationChoices.push('Continuous');
  }

  if (updatedData[updatedId]?.featureid !== undefined) {
    cardBodyContent = (
      <>
        {Object.entries(updatedData).map(([key, properties]) => {
          return (
            <AccordionSectionInputsDispatcher
              key={key}
              namespace={namespace}
              properties={properties}
              is_multiple={multiple}
              mode={mode}
              initialChoices={numericCategorizationChoices}
              selectedVariables={selectedVariables}
              selectedCategories={selectedCategories}
              selectedFilterValues={selectedFilterValues}
            />
          );
        })}
      </>
    );
  }

  if (updatedData[updatedId]?.featureid === undefined) {
    cardBodyContent = Object.keys(updatedData[updatedId]).map((nexId) => (
      <AccordionSection
        key={`${nexId}-section`}
        id={nexId}
        parentId={cleanId}
        data={updatedData[updatedId]}
        namespace={namespace}
        multiple={multiple}
        mode={mode}
        allowContinuous={allowContinuous}
        selectedVariables={selectedVariables}
        selectedCategories={selectedCategories}
        selectedFilterValues={selectedFilterValues}
      />
    ));
  }

  const flatTree = flattenTree(data[id]);
  let count = 0;

  selectedVariables.forEach((variable) => {
    if (flatTree.includes(variable)) {
      count += 1;
    }
  });

  return (
    <li style={{ listStyle: 'none' }}>
      <ReactBootstrap.Card>
        <ReactBootstrap.Card.Header style={{ display: 'flex', gap: '0.375rem', padding: '0.5rem' }}>
          <ButtonExpand />
          <ReactBootstrap.Button
            variant="link"
            style={{ color: 'initial', padding: 0, fontSize: 17 }}
            onClick={() => {
              ref.current.style.display = ref.current.style.display === 'none' ? 'block' : 'none';
            }}
            data-cy={`accordion-toggle-${cleanId}`}
          >
            <a>{id}</a>
            <BadgeCounter count={count} />
          </ReactBootstrap.Button>
        </ReactBootstrap.Card.Header>
        <ReactBootstrap.Card.Body ref={ref} style={{ display: 'none' }}>
          <ul style={{ padding: 0 }}>{cardBodyContent}</ul>
        </ReactBootstrap.Card.Body>
      </ReactBootstrap.Card>
    </li>
  );
}
