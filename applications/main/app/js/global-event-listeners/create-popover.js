/*
 * Create a popover when hovering over a leaf-info class.
 * The popover will use the `data-*` attributes of the element such as `data-title` and
 * `data-content`. Official documentation https://getbootstrap.com/docs/4.0/components/popovers/
 */
$(document).on('mouseenter', '.leaf-info', (event) => {
  $(event.currentTarget).popover('show');
});
