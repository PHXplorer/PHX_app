const MAP_CONTAINER_ID = 'app-neighbor_data-map-map_plot';

/**
 * Highlight map polygons and bivariate legend items
 * when hovering over a bivariate legend item.
 */
$(document).on('mouseenter', '.bivariate-grid-item', (e) => {
  $('.bivariate-grid-item').addClass('dimmed');
  e.currentTarget.classList.add('highlight');
  window.leafletMaps[MAP_CONTAINER_ID].eachLayer((layer) => {
    if (layer.setStyle === undefined) return;

    if (layer.options.group !== e.currentTarget.dataset.group) {
      layer.setStyle({
        fillOpacity: 0.1,
        weight: 1,
      });
    } else {
      layer.setStyle({
        fillOpacity: 1,
        weight: 3,
        color: '#666',
      });
    }
  });
});

/**
 * Reset map polygons and bivariate legend styles when leaving a bivariate legend item.
 */
$(document).on('mouseleave', '.bivariate-grid-item', () => {
  $('.bivariate-grid-item').removeClass('dimmed');
  $('.bivariate-grid-item').removeClass('highlight');
  window.leafletMaps[MAP_CONTAINER_ID].eachLayer((layer) => {
    if (layer.setStyle !== undefined) {
      layer.setStyle({
        fillOpacity: 0.7,
        weight: 1,
      });
    }
  });
});
