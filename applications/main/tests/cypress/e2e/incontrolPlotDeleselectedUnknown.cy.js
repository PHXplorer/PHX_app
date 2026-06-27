/// <reference types="../../../.rhino/node_modules/cypress/" />

describe('unknown selected by default', { testIsolation: false }, () => {
  before(() => {
    cy.clearAllCookies();
    cy.clearAllSessionStorage();
    cy.clearAllLocalStorage();
    cy.visit('/');
    cy.contains('Health Outcomes').click();
  });

  it('renders a plot with Unkown value deselected by default', () => {
    cy.get('[data-cy="dimensions-input-button"]').click();
    cy.get("[data-cy='accordion-toggle-root2_Person_Attribute']").click({ force: true });
    cy.get("[data-cy='accordion-toggle-root2_Person_Attribute_Demographics']").click({ force: true });
    cy.get("[data-variable='neighborhood']").click({ force: true });
    cy.get('[data-cy="dimension-input-apply-button"]').click();

    cy.get('.plotly.html-widget').should('contain.text', 'Unknown');
    cy.get('.plotly.html-widget').contains('Unknown').should('have.css', { opacity: 0.5 });
  });
});
