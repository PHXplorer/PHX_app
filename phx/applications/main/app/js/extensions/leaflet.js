/* globals L */

// What is this? See README.md JavaScript Development
/// <reference types="../../../.rhino/node_modules/@types/leaflet/" />

$(() => {
  L.Control.BivariatePalette = L.Control.extend({
    onAdd() {
      const measure = sessionStorage.getItem('measure');
      const comparison = sessionStorage.getItem('comparison');

      const div = L.DomUtil.create('div');
      div.classList.add('info');
      div.classList.add('leaflet-control');
      div.classList.add('bivariate-legend');

      const gridItemsHTML = window.BivariateLegend.groups
        .map((group, idx) => {
          const color = window.BivariateLegend.colors[idx];
          return `<div data-group="${group}" class="bivariate-grid-item" style="background-color: ${color};">${group}</div>`;
        })
        .join('');

      const gridSize = Math.sqrt(window.BivariateLegend.groups.length);
      const gridStyle = `--grid-size: ${gridSize}`;

      div.innerHTML = `
        <p class="dim-one" data-toggle="tooltip" title="${measure}">${measure}</p>
        <div class="bivariate-grid" style="${gridStyle}">${gridItemsHTML}</div>
        <p class="dim-two" data-toggle="tooltip" title="${comparison}">${comparison}</p>
      `;
      return div;
    },
  });

  L.control.bivariatePalette = (opts) => new L.Control.BivariatePalette(opts);

  window.initializeLeafletMap = (mapId, mapObj) => {
    window.leafletMaps ??= {};
    window.leafletMaps[mapId] = mapObj;
    mapObj.eachLayer((layer) => {
      layer.on('mouseover', (e) => {
        $('[data-group]').addClass('dimmed');
        $(`[data-group='${e.target.groupname}']`).addClass('highlight');
      });
      layer.on('mouseout', (e) => {
        $('[data-group]').removeClass('dimmed');
        $(`[data-group='${e.target.groupname}']`).removeClass('highlight');
      });
    });

    L.control.bivariatePalette({ position: 'bottomleft' }).addTo(mapObj);

    $('[data-toggle="tooltip"]').tooltip();

    return undefined;
  };
});
