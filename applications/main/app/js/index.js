import './extensions';
import './global-event-listeners';
import { NestedAccordionController, NestedAccordionComponent } from './features/nested-accordion';

// Register React component to R/Shiny
Rhino.registerReactComponents({ NestedAccordionComponent });

// Exported functions are available in R/Shiny via App module.
export const { handleMultipleDimensionSelection, handleFilterApply } = NestedAccordionController;
