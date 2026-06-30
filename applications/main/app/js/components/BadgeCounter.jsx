/* global ReactBootstrap */

/**
 * Renders a badge counter component.
 *
 * @param {Object} props - The component props.
 * @param {number} props.count - The count value for the badge counter.
 * @returns {React.ReactNode} The rendered badge counter component or null if count is 0.
 */
export function BadgeCounter({ count }) {
  if (count === 0) return null;

  return (
    <ReactBootstrap.Badge variant="info" style={{ marginLeft: '0.375rem' }}>
      {count}
    </ReactBootstrap.Badge>
  );
}
