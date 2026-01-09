/**
 * Context for managing multiple count values.
 * @typedef {Object} MultipleCountContextType
 * @property {string[]} values
 * @property {(value: string, operation: 'add' | 'remove')} updateValues
 * @property {number} multipleLimit
 */

/**
 * The data for the accordion sections.
 * @typedef {Record<string, FeatureTree | FeatureTreeLeaf>} FeatureTree
 */

/**
 * Feature tree leaf node.
 * @typedef {Object} FeatureTreeLeaf
 * @property {string} category - The category of the leaf node.
 * @property {string} colname - The column name of the leaf node.
 * @property {string} description - The description of the leaf node.
 * @property {string} domain - The domain of the leaf node.
 * @property {string} feature_type - The feature type of the leaf node.
 * @property {string} featureid - The feature ID of the leaf node.
 * @property {string} info_content - The information content of the leaf node.
 * @property {string} label - The label of the leaf node.
 * @property {number} reverse - The reverse value of the leaf node.
 * @property {string} source - The source of the leaf node.
 * @property {string} subdomain - The subdomain of the leaf node.
 * @property {string} subsubdomain - The subsubdomain of the leaf node.
 * @property {string} table - The table of the leaf node.
 * @property {string} value_type - The value type of the leaf node.
 */

/**
 * Accordion mode - either to select or filter.
 * @typedef {'select' | 'filter'} AccordionMode
 */

/**
 * Value returned by the NestedAccordionBinding
 * @typedef {Object} NestedAccordionValue
 * @property {string} variable - The variable name.
 * @property {string | null } category - Either a SelectPicker value,
 * or numeric variable categorization
 * @property {string | null} value - Only relevant for filtering
 */
