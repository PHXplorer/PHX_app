/// <reference types="../../../.rhino/node_modules/cypress/" />

describe('global filters', { testIsolation: false }, () => {
  before(() => {
    cy.clearAllCookies();
    cy.clearAllSessionStorage();
    cy.clearAllLocalStorage();
    cy.visit('/');
    cy.contains('Health Outcomes').click();
  });

  it('should only show certain things by default', () => {
    cy.contains('Show me the percentage of').should('be.visible');
    cy.get('[data-cy="measure-input-button"]').should('be.visible');
    cy.get('[data-cy="dimensions-input-button"]').should('be.visible');
    cy.get('[data-cy="year-input-slider"]').should('be.visible');
  });

  it('should be filtered by default', () => {
    cy.contains('Filters applied: Active Pt 1Yr Lookback').should('be.visible');
  });

  it('should allow to reset filters', () => {
    cy.get('[data-cy="advanced-filters-button"]').click();
    cy.contains('Reset').click();
  });

  it('should allow to add dimensions', () => {
    cy.get('[data-cy="dimensions-input-button"]').click();
    cy.get('.modal-dialog').should('be.visible');
    cy.get('.bmc-nested-accordion').should('be.visible');

    cy.get("[data-cy='accordion-toggle-root2_Person_Attribute']").click({ force: true });
    cy.get("[data-cy='accordion-toggle-root2_Person_Attribute_Demographics']").click({ force: true });
    cy.get("[data-variable='age_group']").click({ force: true });
    cy.get('[data-cy="dimension-input-apply-button"]').click({ force: true });

    cy.get('.modal-dialog').should('not.exist');
    cy.get('.bmc-nested-accordion').should('not.exist');

    cy.get('[data-cy="dimensions-input-button"]').should('contain.text', 'Age group');

    cy.get('[data-cy="dimensions-input-button"]').click();
    cy.get("[data-cy='accordion-toggle-root2_Person_Attribute']").click({ force: true });
    cy.get("[data-cy='accordion-toggle-root2_Person_Attribute_Demographics']").click({ force: true });
    cy.get("[data-variable='race']").click({ force: true });
    cy.get('[data-cy="dimension-input-apply-button"]').click();

    cy.get('[data-cy="dimensions-input-button"]').should('contain.text', 'Age group and Race');

    // Test that these items have appeard in the legend - this is a bit hacky
    // way to test that the plot has changed without doing screenshot testing
    cy.get('.plotly.html-widget').contains('Age group').should('be.visible');
    cy.get('.plotly.html-widget').contains('Race').should('be.visible');
    cy.get('.plotly.html-widget').contains('years old').should('be.visible');
    cy.get('.plotly.html-widget').contains('White').should('be.visible');
  });

  it('should allow to remove dimensions', () => {
    cy.get('[data-cy="dimensions-input-button"]').click();
    cy.get("[data-cy='accordion-toggle-root2_Person_Attribute']").click({ force: true });
    cy.get("[data-cy='accordion-toggle-root2_Person_Attribute_Demographics']").click({ force: true });
    cy.get("[data-variable='race']").click({ force: true });
    cy.get('[data-cy="dimension-input-apply-button"]').click();

    cy.get('[data-cy="dimensions-input-button"]').should('contain.text', 'Age group');

    cy.get('.plotly.html-widget').contains('Age group').should('be.visible');
    cy.get('.plotly.html-widget').contains('Race').should('not.exist');
    cy.get('.plotly.html-widget').contains('years old').should('be.visible');
    cy.get('.plotly.html-widget').contains('White').should('not.exist');

    cy.get('[data-cy="dimensions-input-button"]').click();
    cy.get("[data-cy='accordion-toggle-root2_Person_Attribute']").click({ force: true });
    cy.get("[data-cy='accordion-toggle-root2_Person_Attribute_Demographics']").click({ force: true });
    cy.get("[data-variable='age_group']").click({ force: true });
    cy.get('[data-cy="dimension-input-apply-button"]').click();

    cy.get('[data-cy="dimension-input-default-icon"]').should('be.visible');

    cy.get('.plotly.html-widget').contains('Age group').should('not.exist');
    cy.get('.plotly.html-widget').contains('Race').should('not.exist');
    cy.get('.plotly.html-widget').contains('years old').should('not.exist');
    cy.get('.plotly.html-widget').contains('Asian').should('not.exist');
  });

  it('should allow to change measure', () => {
    cy.get('.plotly.html-widget').contains('Percentage of patients with hypertension').should('be.visible');

    cy.contains('patients with hypertension').click();
    cy.get("[data-cy='accordion-toggle-root2_Equity_Dimension']").click({ force: true });
    cy.get("[data-cy='accordion-toggle-root2_Equity_Dimension_Preventive_Services']").click({ force: true });
    cy.get("[data-cy='accordion-toggle-root2_Equity_Dimension_Preventive_Services_Cancer_Screening']").click({
      force: true,
    });
    cy.get("[data-variable='ps_02']").click({ force: true });

    cy.contains('patients with hypertension').should('not.exist');
    cy.contains('patients who have been screened for colon cancer').should('be.visible');

    // new plotly title
    cy.get('.plotly.html-widget')
      .contains('Percentage of patients who have been screened for colon cancer')
      .should('be.visible');
  });

  it('should not allow to select more than 3 attributes', () => {
    cy.get('[data-cy="dimensions-input-button"]').click();
    cy.get("[data-cy='accordion-toggle-root2_Person_Attribute']").click({ force: true });
    cy.get("[data-cy='accordion-toggle-root2_Person_Attribute_Demographics']").click({ force: true });
    cy.get("[data-variable='age_group']").click({ force: true });
    cy.get("[data-variable='race']").click({ force: true });
    cy.get("[data-variable='ethnicity']").click({ force: true });

    cy.get("[data-cy='selection-limit-message']").should('contain.text', '3 out of 3');

    cy.get("[data-variable='sex']").click({ force: true });
    cy.get("[data-variable='sex']").should('not.be.checked');
    cy.get('[data-cy="shiny-notification').should('be.visible');
  });
});

describe('exhastive parametrized tests', { testIsolation: false }, () => {
  before(() => {
    cy.clearAllCookies();
    cy.clearAllSessionStorage();
    cy.clearAllLocalStorage();
    cy.visit('/');
    cy.contains('Health Outcomes').click();
    cy.window().its('Shiny').should('exist');
    cy.window().then((win) => {
      win.Shiny.setInputValue('app-global_filters-years', [2010, 2022]);
    });
  });

  const measures = [
    {
      variable: 'ps_02',
      label: 'patients who have been screened for colon cancer',
    },
    {
      variable: 'ps_03',
      label: 'women who have been screened for breast cancer',
    },
    {
      variable: 'cvr_01',
      label: 'adults over 18 with BMI < 30',
    },
    {
      variable: 'cvr_02',
      label: 'children with BMI percentile < 95%',
    },
    {
      variable: 'cvr_03',
      label: 'patients with hypertension and controlled blood pressure',
    },
    {
      variable: 'cvr_04',
      label: 'patients with diabetes and HbA1C < 9',
    },
    {
      variable: 'bh_03',
      label: 'patients who scored below 10 on PHQ9',
    },
    {
      variable: 'sdoh_02',
      label: 'patients with secure housing',
    },
    {
      variable: 'bh_01',
      label: 'patients with dx of anxiety or depression',
    },
    {
      variable: 'bh_02',
      label: 'patients with dx of schizophrenia or bipolar disorder',
    },
    {
      variable: 'ptype_01',
      label: 'patients with a primary care visit in current or previous year',
    },
    {
      variable: 'ptype_02',
      label: 'patients with visit to a CHC in the current  year',
    },
    {
      variable: 'ptype_03',
      label: 'patients with any visit in current or previous year',
    },
    {
      variable: 'ptype_04',
      label: 'patients with any visit in current year',
    },
    {
      variable: 'ptype_05',
      label: 'patients with any visit in current or previous 2 years',
    },
  ];

  measures.forEach((measure) => {
    describe(`${Cypress.env('BENCHMARK_IGNORE')} measure: ${measure.variable}`, () => {
      it(`should be able to select measure: ${measure.variable}`, () => {
        cy.get('[data-cy="measure-input-button"]').click();
        cy.get('.modal-dialog').should('be.visible');
        cy.get('.load-container').should('not.be.visible');
        cy.get(`[data-variable="${measure.variable}"]`).click({ force: true });
        cy.get('.modal-dialog').should('not.exist');
      });

      it('should change button label', () => {
        cy.get('[data-cy="measure-input-button"]').should('contain.text', measure.label);
      });

      it('should not have output errors', () => {
        cy.get('.shiny-output-error').should('not.exist');
      });
    });
  });
});
