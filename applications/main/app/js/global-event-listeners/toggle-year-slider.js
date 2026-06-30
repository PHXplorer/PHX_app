/**
 * Close the year slider in global filters when clicking outside of the slider.
 */
const GLOBAL_FILTERS_SHINY_NAMESPACE = 'app-global_filters-';
const SLIDER_SELECTOR = '.global-filters-container .slider-container';

$(document).on('click', (event) => {
  const target = $(event.target);
  const isInClickPath = target.closest(SLIDER_SELECTOR).length > 0;
  const isCheckboxClick = target.closest('.checkbox').length > 0;

  if (!isInClickPath && !isCheckboxClick) {
    $(`#${GLOBAL_FILTERS_SHINY_NAMESPACE}show_slider_years`).prop('checked', false);
    $(`#${GLOBAL_FILTERS_SHINY_NAMESPACE}show_slider_years_neighbor`).prop('checked', false);
    Shiny.setInputValue(`${GLOBAL_FILTERS_SHINY_NAMESPACE}show_slider_years`, false);
    Shiny.setInputValue(`${GLOBAL_FILTERS_SHINY_NAMESPACE}show_slider_years_neighbor`, false);
  }
});
