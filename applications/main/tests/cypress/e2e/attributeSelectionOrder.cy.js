/// <reference types="../../../.rhino/node_modules/cypress/" />

describe('dimension selection order', { testIsolation: false }, () => {
  before(() => {
    cy.clearAllCookies();
    cy.clearAllSessionStorage();
    cy.clearAllLocalStorage();
    cy.visit('/');
    cy.contains('Health Outcomes').click();
  });

  it('displays dimensions in the order they were selected', () => {
    cy.get('[data-cy="dimensions-input-button"]').click();
    cy.get("[data-cy='accordion-toggle-root2_Person_Attribute']").click({ force: true });
    cy.get("[data-cy='accordion-toggle-root2_Person_Attribute_Demographics']").click({ force: true });
    cy.get("[data-variable='race']").click({ force: true });
    cy.get("[data-variable='age_group']").click({ force: true });
    cy.get('[data-cy="dimension-input-apply-button"]').click();

    cy.get('[data-cy="dimensions-input-button"]').should('contain.text', 'Race and Age group');
    cy.get('.plotly.html-widget').should('contain.text', 'Race, Age group');
  });

  it('allows to flip the order', () => {
    cy.get('[data-cy="dimensions-input-button"]').click();
    cy.get("[data-cy='accordion-toggle-root2_Person_Attribute']").click({ force: true });
    cy.get("[data-cy='accordion-toggle-root2_Person_Attribute_Demographics']").click({ force: true });
    cy.get("[data-variable='race']").click({ force: true }); // de-select
    cy.get("[data-variable='race']").click({ force: true }); // select again
    cy.get('[data-cy="dimension-input-apply-button"]').click();

    cy.get('[data-cy="dimensions-input-button"]').should('contain.text', 'Age group and Race');
    cy.get('.plotly.html-widget').should('contain.text', 'Age group, Race');
  });

  it('allows to change the order after reset', () => {
    cy.get('[data-cy="dimensions-input-button"]').click();
    cy.get("[data-cy='dimension-input-reset-button']").click();

    cy.get('[data-cy="dimensions-input-button"]').click();

    // NOTE: gotta wait a little because shiny triggers double re-render of the component
    cy.wait(5000);

    cy.get("[data-cy='accordion-toggle-root2_Person_Attribute']").click({ force: true });
    cy.get("[data-cy='accordion-toggle-root2_Person_Attribute_Demographics']").click({ force: true });
    cy.get("[data-variable='race']").click({ force: true });
    cy.get("[data-variable='age_group']").click({ force: true });
    cy.get('[data-cy="dimension-input-apply-button"]').click();

    cy.get('[data-cy="dimensions-input-button"]').should('contain.text', 'Race and Age group');
    cy.get('.plotly.html-widget').should('contain.text', 'Race, Age group');
  });
});
