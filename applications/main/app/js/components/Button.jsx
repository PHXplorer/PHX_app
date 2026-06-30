/* global React, ReactBootstrap */

/**
 * Button
 *
 * Basically, a bootstrap 4 button + a popover recreated in React.
 *
 * @param {Object} props - The component props.
 * @param {string} props.namespace - The namespace of the button.
 * @param {FeatureTreeLeaf} props.properties - The properties of the button.
 * @param {boolean} props.disabled - Indicates if the button is disabled.
 * @param {boolean} props.active - Indicates if the button is active.
 * @returns {React.ReactNode} The rendered button component.
 */
export function Button({ namespace, properties, disabled, active }) {
  return (
    <ReactBootstrap.Button
      className="btn-attribute-selection"
      variant={active ? 'outline-info' : 'default'}
      disabled={disabled}
      data-variable={properties.colname}
      data-ns={namespace}
    >
      {properties.label}
      <a className="has-popover leaf-info" data-content={properties.description} data-trigger="hover">
        <i className="icon ion-md-information-circle-outline" />
      </a>
    </ReactBootstrap.Button>
  );
}

/**
 * ButtonExpand
 *
 * Component that goes in an AccordionSection header, that is supposed to
 * expand the entire tree branch all the way down to the leaf nodes (inputs).
 *
 * @returns {React.ReactNode} The rendered button component.
 */
export function ButtonExpand() {
  return (
    <ReactBootstrap.Button
      variant="default"
      style={{ padding: '0 10px' }}
      onClick={(event) => {
        const expansionRoot = $(event.currentTarget).parent().siblings('.card-body');
        const isExpanded = $(expansionRoot).css('display') === 'block';
        $(expansionRoot).css('display', isExpanded ? 'none' : 'block');
        $(expansionRoot)
          .find('.card-body')
          .each((i, x) => $(x).css('display', isExpanded ? 'none' : 'block'));
      }}
    >
      <i className="icon ion-md-arrow-dropright" />
    </ReactBootstrap.Button>
  );
}
