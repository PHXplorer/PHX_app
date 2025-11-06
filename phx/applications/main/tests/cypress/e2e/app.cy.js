describe(`${Cypress.env('BENCHMARK_IGNORE')} app`, () => {
  beforeEach(() => {
    cy.visit('/');
  });

  it('starts', () => {});
});
