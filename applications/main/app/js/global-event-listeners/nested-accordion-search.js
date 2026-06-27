/**
 * This piece of code provides "searching" functionality in the advanced filters modal.
 * It works by tracking "change" event in the textInput component with #app-show_filters-search id.
 * Then, it looks for (1) accordion titles with that text and (2) input labels with that text.
 * For each found element, it highlights it with special style and expands all parent accordions.
 */
$(document).on('change', '.input-with-button input', (event) => {
  $('.modal-content .search-highlight').each((i, elem) => elem.classList.remove('search-highlight')); // prettier-ignore
  $('.modal-content .card-body').each((i, elem) => {
    // eslint-disable-next-line no-param-reassign
    elem.style.display = 'none';
  });

  const searchInputValue = $(event.currentTarget).val();

  if (searchInputValue === '') {
    return;
  }

  const targets = $(
    `.modal-content [data-toggle="collapse"]:icontains('${searchInputValue.toLocaleLowerCase()}'),
    .modal-content label:icontains('${searchInputValue.toLocaleLowerCase()}'),
    .modal-content button:icontains('${searchInputValue.toLocaleLowerCase()}')`,
  );

  targets.each((i, elem) => elem.classList.add('search-highlight'));
  targets.parents().each((i, elem) => {
    if (elem.classList.contains('card-body')) {
      // eslint-disable-next-line no-param-reassign
      elem.style.display = 'block';
    }
  });
});
