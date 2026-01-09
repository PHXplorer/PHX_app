/**
 * Observe change the current active tab, to decide whether or not
 * to hide the global filters dimensions UI.
 */
$(document).on('click', '.sidebar-menu .nav-link[data-toggle="tab"]', (event) => {
  // Sometimes click event is registered by the child <p> tag
  let tab = $(event.target).data('value');
  if (tab === undefined) {
    tab = $(event.target).parent().data('value');
  }

  const newDisplayValue = tab === 'time' ? 'flex' : 'none';

  $('.global-filters-dimensions').css('display', newDisplayValue);
});
